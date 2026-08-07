# 🔄 End-to-End Master Irrigation Workflow & Operational Lifecycle

## 📖 1. Executive Summary & Workflow Overview

The **JalDrishti Master Irrigation Workflow** defines the complete operational journey of a farmer within the system—from initial account creation and farm plot onboarding to satellite-driven hydrological modeling, automated pumping schedule generation, Smart Rain Hold advisories, field analytics, and real-time emergency notifications.

By replacing traditional static watering routines with dynamic satellite telemetry, satellite soil physics, and FAO-56 scientific equations, JalDrishti protects crops from water stress and waterlogging while minimizing operational expenditures on electricity and diesel fuel.

```text
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                PHASE 1: ONBOARDING & SETUP                              │
│  User Registration (JWT)  ──>  Farmer Profile Setup  ──>  Farm Plot Configuration       │
└───────────────────────────────────────────┬─────────────────────────────────────────────┘
                                            │
                                            ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                           PHASE 2: HYDROLOGICAL CALCULATIONS                            │
│  Open-Meteo Satellite Feed  ──>  FAO-56 ETo Engine  ──>  Dynamic Kc(t) & ETc Loss       │
│  ISRIC SoilGrids Physics    ──>  Soil TAW / RAW     ──>  Mass-Balance Bucket Depletion Di│
└───────────────────────────────────────────┬─────────────────────────────────────────────┘
                                            │
                                            ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                       PHASE 3: DECISION & SMART RAIN HOLD ENGINE                        │
│  Di >= RAW Trigger Check    ──>  Inspect 48h Rain    ──>  Pump Hours / Rain Hold        │
└───────────────────────────────────────────┬─────────────────────────────────────────────┘
                                            │
                                            ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                        PHASE 4: FIELD ANALYTICS & NOTIFICATIONS                         │
│  5-Tab Analytics Suite      ──>  Cumulative ROI      ──>  Push / In-App Alerts          │
└───────────────────────────────────────────┴─────────────────────────────────────────────┘
```

---

## 👤 2. Phase 1: User Onboarding, Profile & Farm Plot Registration

### 2.1 User Account Registration & Security Authentication
- **Action**: Farmer registers an account via the mobile registration screen or login screen.
- **Backend Endpoint**: `POST /api/v1/auth/register` and `POST /api/v1/auth/login`
- **Mechanism**:
  1. Hashed password generation via **bcrypt** hashing ($12$ rounds).
  2. Issuance of a standard **JWT Access Token** (`HS256` signed) stored securely in mobile `SharedPreferences`.

```mermaid
sequenceDiagram
    autonumber
    actor Farmer
    participant App as Mobile Client
    participant Auth as Auth Router (/api/v1/auth)
    participant DB as Supabase PostgreSQL

    Farmer->>App: Input Username & Password
    App->>Auth: POST /register or /login
    Auth->>DB: Query User Credentials / Insert User Record
    DB-->>Auth: User Record Confirmed
    Auth->>Auth: Generate JWT Access Token (HS256)
    Auth-->>App: 200 OK + { access_token, token_type }
    App->>App: Store JWT in SharedPreferences & AuthProvider State
```

---

### 2.2 Onboarding Survey & Farmer Profile Setup
- **Action**: Farmer completes the initial onboarding profile setup.
- **Backend Model**: `User_Profile` table in PostgreSQL.
- **Fields Captured**:
  - `first_name`, `last_name`, `phone_number`
  - `state`, `district`, `location_name` (e.g., *"Burdwan, West Bengal"*)
  - `farm_area_acres` (e.g., `2.5` acres)
  - `interested_crop` (e.g., `paddy_rice`, `potato`, `wheat`)
  - `preferred_language` (`English`, `Bengali`, `Hindi`)

---

### 2.3 Farm Plot Configuration & Equipment Attributes
- **Action**: Farmer adds one or more specific farm plots via `add_edit_farm_plot_screen.dart`.
- **Backend Endpoint**: `POST /api/v1/plots/`
- **Fields & Parameters Required for Hydrology**:

| Parameter Field | Type / Unit | Description & Operational Purpose |
|---|---|---|
| **`name`** | `String` | Unique field name (e.g., *"Main Paddy Field"*) |
| **`latitude` & `longitude`** | `Float` | Geolocation coordinates for satellite telemetry fetching |
| **`crop_id`** | `String` | Crop selection (`paddy_rice`, `potato`, `wheat`, `mustard`, `maize`) |
| **`sowing_date`** | `YYYY-MM-DD` | Date of planting to calculate dynamic crop growth stage |
| **`area_acres`** | `Float` | Land size in acres (converted to $\mathrm{m}^2$: $1\text{ acre} = 4046.86\text{ m}^2$) |
| **`pump_hp`** | `Float` | Pump motor power rating (HP) |
| **`pump_flow_lps`** | `Float` | Volumetric pump flow rate ($Q_{\mathrm{pump}}$ in Liters per second) |
| **`irrigation_method`** | `String` | System efficiency profile: `drip` ($90\%$), `sprinkler` ($75\%$), `flood` ($50\%$) |
| **`soil_type`** | `String` | Topsoil texture: `clay_loam`, `sandy_loam`, `loam`, `silty_clay`, `heavy_clay` |

---

## 🧮 3. Phase 2: Hydrological Science & Meteorological Calculation Pipeline

When the farmer opens the app or switches active farm plots, JalDrishti automatically executes the 7-step FAO-56 hydrological calculation pipeline:

```mermaid
graph TD
    A["Selected Farm Plot Profile"] --> B["1. Fetch Satellite Telemetry:<br/>Open-Meteo & SoilGrids APIs"]
    B --> C["2. FAO-56 PenmanMonteithEngine:<br/>Calculate Daily ETo (mm/day)"]
    B --> D["3. Dynamic Growth Stage Interpolation:<br/>Calculate Kc(t) & Root Depth Zr"]
    B --> E["4. ISRIC Soil Physics Engine:<br/>Calculate FC, WP, TAW & RAW"]

    C & D --> F["5. Compute Actual Crop Demand:<br/>ETc = ETo × Kc(t)"]
    E & F --> G["6. Mass-Balance Bucket Model:<br/>Di = Di-1 + ETc - Peff - I"]

    G --> H{"7. Is Soil Depletion Di >= RAW Threshold?"}
    H -- No --> I["Status: SOIL MOISTURE OPTIMAL<br/>Recommended Water = 0.0 mm<br/>Pump Runtime = 0 Hours 0 Mins"]
    H -- Yes --> J["Status: IRRIGATE IMMEDIATELY<br/>Convert Net Water to Gross Water Depth"]
```

---

### Step 2.1: Automated Telemetry Ingestion
1. **Weather Telemetry**: Sourced from Open-Meteo API (cached in Redis Cloud `weather:{lat}:{lon}` for 3 hours).
   - Variables fetched: Maximum Temperature ($T_{\mathrm{max}}$), Minimum Temperature ($T_{\mathrm{min}}$), Relative Humidity ($\mathrm{RH}$), Solar Radiation ($R_s$), Wind Speed at 2m height ($u_2$), Precipitation ($P$).
2. **Soil Physics Telemetry**: Sourced from ISRIC SoilGrids 250m API (cached in Redis Cloud `soil:{lat}:{lon}` for 7 days).
   - Variables fetched: Topsoil Clay percentage and Sand percentage.
3. **Crop Stage Telemetry**: Sourced from ICAR Package of Practices (`crop_coefficients.json`).
   - Variables fetched: Stage durations ($L_{\mathrm{ini}}, L_{\mathrm{dev}}, L_{\mathrm{mid}}, L_{\mathrm{late}}$), stage $K_c$ values ($K_{c,\mathrm{ini}}, K_{c,\mathrm{mid}}, K_{c,\mathrm{end}}$), and maximum root depth ($Z_{r,\mathrm{max}}$).

---

### Step 2.2: FAO-56 Penman-Monteith Reference Evapotranspiration ($ET_0$)

The backend `PenmanMonteithEngine` calculates daily reference crop evapotranspiration ($ET_0$) for a standard grass reference surface:

$$ET_0 = \frac{0.408 \Delta (R_n - G) + \gamma \frac{900}{T + 273} u_2 (e_s - e_a)}{\Delta + \gamma (1 + 0.34 u_2)}$$

#### Mathematical Components:
1. **Mean Temperature**: $T_{\mathrm{mean}} = \frac{T_{\mathrm{max}} + T_{\mathrm{min}}}{2} \quad [^\circ\mathrm{C}]$
2. **Atmospheric Pressure**: $P = 101.3 \times \left(\frac{293 - 0.0065 z}{293}\right)^{5.26} \quad [\mathrm{kPa}]$
3. **Psychrometric Constant**: $\gamma = 0.000665 \times P \quad [\mathrm{kPa}/^\circ\mathrm{C}]$
4. **Saturation Vapour Pressure Curve Slope**: $\Delta = \frac{4098 \times e^0(T_{\mathrm{mean}})}{(T_{\mathrm{mean}} + 237.3)^2} \quad [\mathrm{kPa}/^\circ\text{C}]$
5. **Vapour Pressure Deficit**: $e_s - e_a = \frac{e^0(T_{\mathrm{max}}) + e^0(T_{\mathrm{min}})}{2} \times \left(1 - \frac{\mathrm{RH}}{100}\right) \quad [\mathrm{kPa}]$
6. **Net Radiation**: $R_n = 0.77 R_s - 0.10 R_s = 0.67 R_s \quad [\mathrm{MJ/m}^2/\mathrm{day}]$
7. **Soil Heat Flux**: $G = 0.0 \quad [\mathrm{MJ/m}^2/\mathrm{day}]$

---

### Step 2.3: Dynamic Crop Coefficient ($K_c$) & Crop Transpiration Loss ($ET_c$)

The backend `SoilWaterBucketModel` computes elapsed growth days from sowing date to interpolate time-dependent $K_c(t)$ and root depth $Z_r(t)$:

```text
  Kc Factor
    ▲
Kc_mid ├───────────────────────────────┐
       │                              │ ╲
       │   Stage 2 (Development)      │  ╲ Stage 4 (Late Season)
       │  ╱                           │   ╲
Kc_ini ├─╱   Stage 1 (Initial)        │    ╲
       └─┴────────────────────────────┴────┴───────────► Time (Days)
        0   L_initial               L_mid  L_late
```

$$\text{Actual Crop Demand } (ET_c) = ET_0 \times K_c(t) \quad [\mathrm{mm/day}]$$

---

### Step 2.4: Soil Moisture Holding Capacity Calculation

Using topsoil Clay percentage ($\mathrm{Clay}$) and Sand percentage ($\mathrm{Sand}$) from satellite soil telemetry:

1. **Field Capacity ($\theta_{\mathrm{FC}}$)**:
   $$\theta_{\mathrm{FC}} = 0.10 + 0.0025 \times \mathrm{Clay} + 0.0005 \times (100 - \mathrm{Sand}) \quad [\mathrm{m}^3/\mathrm{m}^3]$$

2. **Permanent Wilting Point ($\theta_{\mathrm{WP}}$)**:
   $$\theta_{\mathrm{WP}} = 0.02 + 0.0020 \times \mathrm{Clay} \quad [\mathrm{m}^3/\mathrm{m}^3]$$

3. **Total Available Water ($TAW$)**:
   $$TAW = 1000 \times (\theta_{\mathrm{FC}} - \theta_{\mathrm{WP}}) \times Z_r \quad [\mathrm{mm}]$$

4. **Readily Available Water ($RAW$) Threshold**:
   $$RAW = p \times TAW \quad [\mathrm{mm}]$$
   *(where $p$ is the allowable depletion fraction, default $0.50$)*

---

### Step 2.5: Daily Mass-Balance Soil Water Bucket Model

Daily soil depletion $D_i$ in the root zone is calculated conservationally:

$$D_i = D_{i-1} + ET_{c,i} - P_{\mathrm{eff},i} - I_i$$

Where:
- $D_{i-1}$: Previous day's soil depletion [mm]
- $ET_{c,i}$: Today's crop evapotranspiration loss [mm]
- $P_{\mathrm{eff},i}$: Effective rainfall depth entering root zone ($P_{\mathrm{eff}} = \min(P \times 0.80, P)$) [mm]
- $I_i$: Net irrigation water applied today [mm]

---

### Step 2.6: Decision Boundary & Volumetric Pump Runtime Calculation

When soil water depletion breaches the threshold ($D_i \ge RAW$):

1. **Status Trigger**: `needs_irrigation_today = True`, `status = "IRRIGATE IMMEDIATELY"`
2. **Net Water Recommended**: $D_{\mathrm{net}} = D_i \quad [\mathrm{mm}]$
3. **Gross Water Adjusted for Irrigation Efficiency**:
   $$D_{\mathrm{gross}} = \frac{D_{\mathrm{net}}}{\eta} \quad [\mathrm{mm}]$$
   *(Drip efficiency $\eta = 0.90$, Sprinkler $\eta = 0.75$, Flood $\eta = 0.50$)*
4. **Total Volumetric Water Volume**:
   $$V_{\mathrm{liters}} = D_{\mathrm{gross}} \times A_{\mathrm{sqm}} \quad [\mathrm{Liters}]$$
5. **Pump Runtime Duration**:
   $$T_{\mathrm{seconds}} = \frac{V_{\mathrm{liters}}}{Q_{\mathrm{pump}}}$$
   $$\text{Pump Hours} = \left\lfloor \frac{T_{\mathrm{seconds}}}{3600} \right\rfloor, \quad \text{Pump Minutes} = \mathrm{round}\left( \frac{T_{\mathrm{seconds}} \pmod{3600}}{60} \right)$$

---

## 🌧️ 4. Phase 3: Smart Rain Hold Advisory & Cumulative ROI Telemetry

Before issuing the final pump recommendation to the farmer, JalDrishti inspects the **upcoming 48-hour satellite rainfall forecast** ($P_{\mathrm{upcoming}}$):

$$P_{\mathrm{upcoming}} = \sum_{d=t+1}^{t+2} P_d \quad [\mathrm{mm}]$$

```mermaid
graph TD
    A["Calculated Pump Runtime & Status"] --> B{"Is Upcoming Rain >= 5.0 mm<br/>OR Today Rain >= 4.0 mm?"}
    B -- No --> C["Status: IRRIGATE IMMEDIATELY<br/>Maintain Original Pump Hours"]
    B -- Yes --> D["Trigger Smart Rain Hold!<br/>rain_hold_active = True"]

    D --> E{"Was Irrigation Needed Today?"}
    E -- Yes --> F["Override needs_irrigation = False<br/>Set Status = RAIN_HOLD<br/>Calculate Single-Run ₹ Savings"]
    E -- No --> G["Issue General Rain Advisory<br/>Soil Moisture Optimal"]

    F & G --> H["Aggregate Cumulative Farmer ROI<br/>(Water Liters, Pump Hours, ₹ Money Saved, CO₂ kg)"]
```

### Single-Run & Cumulative ROI Equations:
1. **Single-Run Cost Saved**:
   $$C_{\mathrm{run}} = \mathrm{round}(T_{\mathrm{saved}} \times 80) \quad [\mathrm{INR}]$$
   *(Benchmark operating tariff: ₹80.0 / hour for electricity & diesel generator fuel)*

2. **Cumulative Water Saved ($V_{\mathrm{cum}}$)**:
   $$V_{\mathrm{cum}} = \mathrm{round}(D_{\mathrm{gross}} \times A_{\mathrm{sqm}} \times (N_{\mathrm{skipped}} + 3)) \quad [\mathrm{Liters}]$$

3. **Cumulative Financial Savings ($S_{\mathrm{cum}}$)**:
   $$S_{\mathrm{cum}} = \mathrm{round}(T_{\mathrm{cum}} \times 80 + (N_{\mathrm{skipped}} \times C_{\mathrm{run}})) \quad [\mathrm{INR}]$$

4. **Cumulative Carbon Footprint Reduced ($E_{\mathrm{CO2}}$)**:
   $$E_{\mathrm{CO2}} = \mathrm{round}(T_{\mathrm{cum}} \times 2.8, \, 1) \quad [\mathrm{kg\ CO}_2]$$

---

## 📊 5. Phase 4: Field Analytics & Visualization Dashboard Engine

The mobile client `AnalyticsScreen` provides a modular 5-tab breakdown of field performance:

```text
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                FIELD ANALYTICS SUITE                                    │
│  [🌦️ Weather Stats] [📊 Daily Trend] [💡 Smart Insights] [🌊 Water Balance] [📋 History]│
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

1. **Tab 0: Weather Stats (`weather_stats_tab.dart`)**:
   - Maps 6-day weather forecast directly from `daily_breakdown`.
   - Displays Max/Min temperatures, relative humidity $\%$, wind speed (km/h), precipitation depth (mm), and $ET_0$ reference evapotranspiration.
2. **Tab 1: Daily Trends (`daily_trends_tab.dart`)**:
   - CustomPainter bar & line chart featuring Y-axis scale labels (`0 mm`, `5 mm`, `10 mm`, `15 mm`).
   - Applied Water bars (Dark Blue), Rainfall bars (Sky Blue), and Crop Demand $ET_c$ golden spline curve.
   - Interactive daily breakdown card list showing exact daily numeric metrics.
3. **Tab 2: Smart Insights (`smart_insights_tab.dart`)**:
   - Real-time Hydration Status badge (Optimal / Deficit / High Storage).
   - Precision Savings Counter displaying dynamic water volume saved (kL) and financial savings (₹ INR).
   - Crop growth stage advisory tips and Smart Rain Hold alert banners.
4. **Tab 3: Water Balance (`water_balance_tab.dart`)**:
   - Dynamic Water Satisfaction Index ($WSI = \frac{\text{Applied} + \text{Rain}}{\text{ETc}} \times 100\%$).
   - Volumetric breakdown cards comparing Irrigation Applied (kL), Rainfall Received (kL), and Crop Demand $ET_c$ (kL).
5. **Tab 4: History Logs (`history_logs_tab.dart`)**:
   - Queries backend `GET /api/v1/irrigation/history/{plot_id}` endpoint.
   - Renders historical water sessions with dates, notes, mm depth, and equivalent kL volume.
   - Includes a quick **"+ Log Water Run"** modal button so farmers can log irrigation runs directly from Analytics.

---

## 🔔 6. Phase 5: Notification Center & Emergency Advisory System

JalDrishti features a dual-layer notification architecture driven by `NotificationProvider` and `NotificationService`:

```mermaid
graph TD
    A["Hydrological & Weather Engine Loop"] --> B{"Evaluate Emergency Triggers"}
    
    B -- Soil Depletion Di >= RAW --> C["Trigger Alert: High Water Deficit!<br/>'Run pump for X hrs Y mins today'"]
    B -- Rain Forecast >= 5.0 mm --> D["Trigger Alert: Smart Rain Hold Active!<br/>'Heavy rain incoming. Skip pumping to save ~₹INR'"]
    B -- Microclimate Pest Match --> E["Trigger Alert: Fungal / Insect Outbreak Warning!<br/>'High risk of Rice Blast / Late Blight'"]

    C & D & E --> F["Push Native Device Local Notification"]
    C & D & E --> G["Insert Feed Item into Notification Provider Store"]
    G --> H["Update App Bar Notification Bell Badge Count"]
    H --> I["Display Notification Center Modal Bottom Sheet"]
```

### Emergency Alert Categories:
1. **Critical Water Deficit Alert**: Triggered when root zone depletion $D_i \ge RAW$. Notifies the farmer with exact pump operating duration required.
2. **Smart Rain Hold Emergency Alert**: Triggered when heavy rainfall ($P \ge 5.0\text{ mm}$) is forecast. Advises skipping pump runs to prevent crop asphyxiation and save pumping costs.
3. **Pest & Disease Microclimate Outbreak Warning**: Triggered when temperature and relative humidity match crop-specific epidemiological sporulation rules (e.g., Rice Blast, Potato Late Blight, Fall Armyworm).

---

## 💻 7. Master Repository Code Index

| Functional Phase | Backend Python Code | Mobile Flutter Code |
|---|---|---|
| **Phase 1: User & Plot Setup** | `app/api/v1/endpoints/auth.py`<br/>`app/api/v1/endpoints/farm_plots.py` | `lib/screens/login_screen.dart`<br/>`lib/screens/add_edit_farm_plot_screen.dart` |
| **Phase 2: Hydrological Engine** | `app/engine/penman_monteith.py`<br/>`app/engine/water_bucket_model.py` | `lib/providers/irrigation_provider.dart`<br/>`lib/widgets/dashboard_pump_card.dart` |
| **Phase 3: Rain Hold & ROI** | `app/api/v1/endpoints/irrigation.py` | `lib/widgets/smart_rain_hold_card.dart`<br/>`lib/widgets/farmer_roi_savings_card.dart` |
| **Phase 4: Field Analytics** | `app/api/v1/endpoints/irrigation.py` | `lib/screens/analytics_screen.dart`<br/>`lib/screens/analytics/` |
| **Phase 5: Emergency Alerts** | `app/engine/pest_disease_engine.py` | `lib/providers/notification_provider.dart`<br/>`lib/core/services/notification_service.dart` |
