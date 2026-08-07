# 🌾 JalDrishti AI: Precision Agricultural Hydrology & Intelligent Field Advisory Platform

## 📑 Master Architecture, User Journey Workflow & Technical Reference Guide

---

## 📖 Chapter 1: Executive Summary, Agricultural Mission & System Overview

### 1.1 The Indian Agricultural Hydrology Context
Agriculture is the heart of Indian socio-economic life, sustaining over $50\%$ of the national workforce. However, smallholder farmers across India face severe operational hurdles due to traditional, unscientific water management:

1. **Massive Water Waste via Flood Irrigation**: More than $80\%$ of Indian agricultural land relies on unmeasured surface flooding. Inundating fields with excessive water causes **root zone hypoxia** (suffocation of crop roots due to lack of oxygen in soil pores), widespread soil erosion, and severe nutrient leaching below the root zone.
2. **Heavy Financial Costs & Rural Energy Strain**: Farmers operate electric and diesel pumps for fixed, uncalibrated durations (e.g., 3 to 5 hours daily). With operational tariffs averaging ₹$80.0$ per hour for electricity and diesel fuel, inefficient pumping drains farmer income and strains the rural power grid.
3. **Climate-Induced Monsoon Variability**: Unpredictable weather shifts cause erratic rainfall patterns. Farmers frequently pump water into their fields only hours before heavy monsoonal downpours, leading to waterlogging, crop failure, and wasted fuel expenditure.
4. **The High Cost Barrier of Traditional Precision Ag**: Conventional precision irrigation systems require physical IoT soil moisture sensors, weather stations, and cellular telemetry nodes installed on the farm. These hardware setups cost thousands of rupees, making them financially impossible for small and marginal farmers owning $< 2$ hectares of land.

```text
┌───────────────────────────────────────────────────────────────────────────────────────────┐
│                                   THE JALDRISHTI VISION                                   │
│                                                                                           │
│   Traditional Agriculture                                   JalDrishti AI Platform        │
│   ❌ Fixed watering schedules                              ✅ FAO-56 Scientific Hydrology │
│   ❌ Over-watering & root hypoxia                          ✅ Exact Pump Hours & Minutes  │
│   ❌ Wasted fuel (₹80/hr) & water                          ✅ Smart Rain Hold Advisories  │
│   ❌ Expensive IoT hardware required                       ✅ Zero-Hardware Satellite Tech│
└───────────────────────────────────────────────────────────────────────────────────────────┘
```

### 1.2 The JalDrishti Solution: Zero-Hardware Precision Technology
**JalDrishti AI** is a zero-hardware-cost, satellite-driven agricultural hydrology platform built specifically for Indian farming conditions. By integrating real-time Open-Meteo satellite weather telemetry, ISRIC SoilGrids 250m soil physics, and ICAR Package of Practices (PoP) crop stage models into standard **FAO-56 Penman-Monteith scientific equations**, JalDrishti delivers:

- **Exact Equipment-Mapped Pumping Schedules**: Converts complex soil hydrology into simple, practical pump runtimes in **Hours and Minutes** customized to the farmer's pump horsepower (HP) and discharge flow rate ($Q_{\mathrm{pump}}$).
- **Smart Rain Hold Engine**: Automatically inspects 48-hour satellite precipitation forecasts ($\ge 5.0\mathrm{~mm}$) and overrides pump schedules to prevent field waterlogging and save pumping fuel money.
- **Cumulative Farmer ROI Telemetry**: Tracks seasonal water volume saved (Liters / kL), pump operating hours saved, financial money saved (₹ INR), and carbon footprint reduction ($\mathrm{kg\ CO}_2$).
- **5-Tab Field Analytics Suite**: Provides visual dashboards for weather trends, water satisfaction index ($WSI$), growth progress, and historical pump logs.
- **JalSathi AI Multilingual Companion**: An intelligent voice/text agronomy assistant that answers pest, crop disease, and fertilizer questions in native Indian languages (Bengali বাংলা, Hindi हिंदी, English).

---

## 🏗️ Chapter 2: System Architecture & Technology Stack

JalDrishti AI is built on a modern, multi-tier microservices software architecture designed for high availability, sub-second API latency, and responsive cross-platform mobile interaction:

```text
                               ┌──────────────────────────────────┐
                               │   Flutter Cross-Platform Client  │
                               │  (Dart, Provider, CustomPainter) │
                               └────────────────┬─────────────────┘
                                                │ REST API (JSON / JWT)
                                                ▼
                               ┌──────────────────────────────────┐
                               │    Python FastAPI Cloud Server   │
                               │     (Uvicorn, AsyncIO, PyDantic) │
                               └──────┬────────────────────┬──────┘
                                      │                    │
             ┌────────────────────────┴──────┐          ───┴────────────────────────────┐
             │                               │         │                                │
             ▼                               ▼         ▼                                ▼
┌─────────────────────────┐     ┌──────────────────┐ ┌───────────────────┐    ┌──────────────────┐
│  Supabase PostgreSQL    │     │   Redis Cloud    │ │ ChromaDB Vector DB│    │ Groq LLM API     │
│  (Relational ORM DB)    │     │ (3h/7d Cache DB) │ │ (HuggingFace MiniLM)│    │ (Llama 3 70B)    │
└─────────────────────────┘     └──────────────────┘ └───────────────────┘    └──────────────────┘
```

### 2.1 Layer-by-Layer Technology Matrix

| Layer / Subsystem | Technology | Purpose & Architectural Function |
|---|---|---|
| **Mobile Client** | **Flutter SDK (Dart 3.x)** | Fast, responsive cross-platform client UI for Android and iOS |
| **State Management** | **Provider Pattern** | Reactive state management (`AuthProvider`, `FarmPlotProvider`, `IrrigationProvider`, `ChatProvider`, `NotificationProvider`) |
| **Data Visualization** | **CustomPainter & Google Fonts** | Renders dynamic Y-axis bar charts, spline curves, and progress gauges |
| **Local Speech Engine** | **SpeechToText & FlutterTTS** | Microphone voice recording (STT) and voice audio response playback (TTS) |
| **Cloud Backend API** | **Python 3.11 & FastAPI** | Asynchronous REST backend handling telemetry fetching, FAO-56 calculations, and RAG |
| **Server Runtime** | **Uvicorn & AsyncIO** | Non-blocking ASGI web server supporting high concurrent farmer requests |
| **Primary Database** | **Supabase PostgreSQL** | Cloud persistence for user accounts, farmer profiles, farm plots, and irrigation logs |
| **Database ORM** | **SQLAlchemy 2.0 & PyDantic v2** | Relational mapping, schema migrations, and request payload validation |
| **High-Speed Cache** | **Redis Cloud** | Caches Open-Meteo weather data (3-hour TTL) and ISRIC soil physics (7-day TTL) |
| **AI Vector Store** | **ChromaDB & HuggingFace** | Vector store indexing ICAR Package of Practices (`all-MiniLM-L6-v2` embeddings) |
| **Generative LLM Engine**| **Groq API (Llama 3 70B)** | Ultra-fast agronomic reasoning and multilingual chat advisory generation |
| **Satellite APIs** | **Open-Meteo & ISRIC SoilGrids** | Real-time weather forecasts and topsoil sand/clay physical texture percentages |

---

## 🔄 Chapter 3: End-to-End Operational Lifecycle (The Complete User Journey)

This chapter provides a friendly, step-by-step walkthrough of how a farmer interacts with JalDrishti AI—from initial registration to satellite calculations, pumping advice, analytics, and voice agronomy chat.

```mermaid
sequenceDiagram
    autonumber
    actor Farmer
    participant Mobile as Flutter Client
    participant API as FastAPI Cloud Server
    participant Cache as Redis Cloud Cache
    participant Sat as Satellite APIs (Open-Meteo / SoilGrids)
    participant DB as Supabase PostgreSQL DB
    participant RAG as ChromaDB / Groq LLM

    Farmer->>Mobile: 1. Register / Login Account
    Mobile->>API: POST /api/v1/auth/login
    API->>DB: Verify bcrypt password hash
    DB-->>API: User Record Confirmed
    API-->>Mobile: Return JWT Token (HS256)

    Farmer->>Mobile: 2. Complete Profile & Add Farm Plot
    Mobile->>API: POST /api/v1/plots (lat, lon, crop, sowing date, area, pump HP)
    API->>DB: Store FarmPlot Record

    Farmer->>Mobile: 3. View Dashboard / Refresh Hydrology
    Mobile->>API: GET /api/v1/irrigation/plot-recommendation/{plot_id}
    API->>Cache: Check Cached Weather & Soil Data
    alt Redis Cache Miss
        API->>Sat: Fetch 7-Day Weather Forecast & Soil Textures
        Sat-->>API: Return Temp, Rain, Humidity, Sand/Clay %
        API->>Cache: Cache Telemetry (3h Weather / 7d Soil)
    end
    API->>API: 4. Execute FAO-56 Penman-Monteith & Mass-Balance Bucket Model
    API->>API: 5. Execute Smart Rain Hold & ROI Telemetry
    API-->>Mobile: 6. Return JSON (Pump Hrs/Mins, Status, Rain Hold, ROI, Weather)

    Farmer->>Mobile: 7. Ask JalSathi AI (Voice Mic Input / Text)
    Mobile->>API: POST /api/v1/chatbot/ask (Query, Language, Profile)
    API->>RAG: Retrieve Top-3 ICAR PoP Context Chunks & Query Groq LLM
    RAG-->>API: Return Multilingual Agronomy Solution
    API-->>Mobile: Display Response + Trigger TTS Voice Playback
```

---

### 3.1 Phase 1: User Onboarding, Profile & Farm Plot Registration

#### Step 1.1: Security Registration & Authentication
- **User Action**: The farmer opens the app and inputs their credentials.
- **Backend Endpoints**: `POST /api/v1/auth/register` and `POST /api/v1/auth/login` (`app/api/v1/endpoints/auth.py`)
- **Behind the Scenes**:
  1. Passwords are securely hashed using **bcrypt** ($12$ work factor rounds).
  2. The server issues a **JWT Access Token** signed with `HS256`.
  3. The mobile client securely stores the token in `SharedPreferences` and attaches it to all subsequent request headers.

#### Step 1.2: Farmer Profile Setup
- **User Action**: The farmer selects their district, preferred language, and main crop interest.
- **Backend Endpoint**: `POST /api/v1/auth/profile`
- **Fields Captured**: `first_name`, `last_name`, `phone_number`, `state`, `district`, `location_name` (e.g., *"Burdwan, West Bengal"*), `farm_area_acres`, `interested_crop`, `preferred_language` (`English`, `Bengali`, `Hindi`).

#### Step 1.3: Farm Plot & Equipment Profile Onboarding
- **User Action**: The farmer creates a plot profile via `add_edit_farm_plot_screen.dart`.
- **Backend Endpoint**: `POST /api/v1/plots/` (`app/api/v1/endpoints/farm_plots.py`)
- **Parameters Onboarded**:
  - `name`: Plot name (e.g., *"Main Paddy Field"*)
  - `latitude` & `longitude`: Geolocation coordinates for fetching satellite feeds
  - `crop_id`: Target crop selection (`paddy_rice`, `potato`, `wheat`, `mustard`, `maize`)
  - `sowing_date`: Planting date used to calculate dynamic growth stages
  - `area_acres`: Field size in acres (converted to $\mathrm{m}^2$: $1\text{ acre} = 4046.86\text{ m}^2$)
  - `pump_hp`: Pump motor horsepower (HP)
  - `pump_flow_lps`: Volumetric discharge flow rate ($Q_{\mathrm{pump}}$ in Liters/sec)
  - `irrigation_method`: System efficiency profile (`drip` $\eta = 0.90$, `sprinkler` $\eta = 0.75$, `flood` $\eta = 0.50$)
  - `soil_type`: Topsoil texture (`clay_loam`, `sandy_loam`, `loam`, `silty_clay`, `heavy_clay`)

---

### 3.2 Phase 2: Real-time Hydrological Science Engine (FAO-56 Pipeline)

When the farmer opens the dashboard, JalDrishti executes a 7-step FAO-56 hydrological calculation pipeline:

```text
┌───────────────────────────────────────────────────────────────────────────────────────────┐
│                              FAO-56 HYDROLOGICAL PIPELINE                                 │
│                                                                                           │
│  [1. Fetch Telemetry] ──> [2. FAO-56 ETo Engine] ──> [3. Dynamic Kc(t) & ETc Transpiration]│
│                                                                   │                       │
│  [4. ISRIC Soil Physics] ──> [5. Soil TAW & RAW] ─────────────────┤                       │
│                                                                   ▼                       │
│  [7. Pump Runtime Hrs/Mins] <── [Gross Depth Dgross] <── [6. Mass-Balance Bucket Model Di]│
└───────────────────────────────────────────────────────────────────────────────────────────┘
```

#### Step 2.1: Satellite Telemetry Ingestion & Smart Caching
- **Open-Meteo Weather API**: Retrieves 7-day historic and forecast weather data ($T_{\mathrm{max}}, T_{\mathrm{min}}, \mathrm{RH}, R_s, u_2, P$). Cached in Redis Cloud (`weather:{lat}:{lon}`) with a **3-hour TTL**.
- **ISRIC SoilGrids 250m API**: Retrieves topsoil Clay % and Sand %. Cached in Redis Cloud (`soil:{lat}:{lon}`) with a **7-day TTL**.
- **ICAR Crop Coefficient JSON**: Loads growth stage durations ($L_{\mathrm{ini}}, L_{\mathrm{dev}}, L_{\mathrm{mid}}, L_{\mathrm{late}}$), stage $K_c$ values, and max root depth $Z_{r,\mathrm{max}}$ (`app/engine/crop_coefficients.json`).

#### Step 2.2: Reference Evapotranspiration ($ET_0$) Calculation
- **Concept**: $ET_0$ measures the **pure atmospheric evaporative demand** of a standardized grass reference surface ($0.12\mathrm{~m}$ height, albedo $0.23$, surface resistance $70\mathrm{~s/m}$). By FAO-56 scientific design, $ET_0$ is completely independent of soil properties.
- **Formula**:
  $$ET_0 = \frac{0.408 \Delta (R_n - G) + \gamma \frac{900}{T + 273} u_2 (e_s - e_a)}{\Delta + \gamma (1 + 0.34 u_2)} \quad [\mathrm{mm/day}]$$

- **Intermediate Steps**:
  1. Mean Daily Temp: $T_{\mathrm{mean}} = \frac{T_{\mathrm{max}} + T_{\mathrm{min}}}{2} \quad [^\circ\mathrm{C}]$
  2. Atmospheric Pressure: $P = 101.3 \times \left(\frac{293 - 0.0065 z}{293}\right)^{5.26} \quad [\mathrm{kPa}]$
  3. Psychrometric Constant: $\gamma = 0.000665 \times P \quad [\mathrm{kPa}/^\circ\mathrm{C}]$
  4. Saturation Vapour Pressure Slope: $\Delta = \frac{4098 \times e^0(T_{\mathrm{mean}})}{(T_{\mathrm{mean}} + 237.3)^2} \quad [\mathrm{kPa}/^\circ\mathrm{C}]$
  5. Vapour Pressure Deficit: $e_s - e_a = \frac{e^0(T_{\mathrm{max}}) + e^0(T_{\mathrm{min}})}{2} \times \left(1 - \frac{\mathrm{RH}}{100}\right) \quad [\mathrm{kPa}]$
  6. Net Solar Radiation: $R_n = 0.77 R_s - 0.10 R_s = 0.67 R_s \quad [\mathrm{MJ/m}^2/\mathrm{day}]$
  7. Soil Heat Flux: $G = 0.0 \quad [\mathrm{MJ/m}^2/\mathrm{day}]$
- **Backend Implementation**: `PenmanMonteithEngine.calculate_daily_eto()` in `app/engine/penman_monteith.py`

#### Step 2.3: Dynamic Crop Coefficient ($K_c$) & Crop Transpiration ($ET_c$)
- **Concept**: Reference evapotranspiration ($ET_0$) reflects grass, not specific crops like paddy or potato. Multiplying $ET_0$ by a dynamic Crop Coefficient $K_c(t)$ adjusts atmospheric demand to actual daily crop transpiration ($ET_c$).

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

- **Growth Stage Interpolation**: `SoilWaterBucketModel.calculate_dynamic_crop_stage()` computes `elapsed_days = (today - sowing_date)` and interpolates dynamic $K_c(t)$ and root depth $Z_r(t)$ across 4 stages:
  - **Stage 1 (Initial)**: $K_c = K_{c,\mathrm{ini}}$, $Z_r = \max(0.15, Z_{r,\mathrm{max}} \times 0.30)$
  - **Stage 2 (Development)**: Linear interpolation between $K_{c,\mathrm{ini}}$ and $K_{c,\mathrm{mid}}$, root expansion $Z_r(t)$
  - **Stage 3 (Mid-Season)**: $K_c = K_{c,\mathrm{mid}}$, full root depth $Z_r = Z_{r,\mathrm{max}}$
  - **Stage 4 (Late Season)**: Linear decline to $K_{c,\mathrm{end}}$, full root depth $Z_r = Z_{r,\mathrm{max}}$
- **Formula**:
  $$\text{Actual Crop Demand } (ET_c) = ET_0 \times K_c(t) \quad [\mathrm{mm/day}]$$

#### Step 2.4: Soil Moisture Holding Capacity Calculation
- **Concept**: Using satellite topsoil Clay % and Sand % from ISRIC SoilGrids, JalDrishti calculates the **Field Capacity** ($\theta_{\mathrm{FC}}$), **Permanent Wilting Point** ($\theta_{\mathrm{WP}}$), **Total Available Water** ($TAW$), and **Readily Available Water** ($RAW$) stress threshold:
  1. **Field Capacity ($\theta_{\mathrm{FC}}$)**:
     $$\theta_{\mathrm{FC}} = 0.10 + 0.0025 \times \mathrm{Clay} + 0.0005 \times (100 - \mathrm{Sand}) \quad [\mathrm{m}^3/\mathrm{m}^3]$$
  2. **Permanent Wilting Point ($\theta_{\mathrm{WP}}$)**:
     $$\theta_{\mathrm{WP}} = 0.02 + 0.0020 \times \mathrm{Clay} \quad [\mathrm{m}^3/\mathrm{m}^3]$$
  3. **Total Available Water ($TAW$)**:
     $$TAW = 1000 \times (\theta_{\mathrm{FC}} - \theta_{\mathrm{WP}}) \times Z_r(t) \quad [\mathrm{mm}]$$
  4. **Readily Available Water ($RAW$) Threshold**:
     $$RAW = p \times TAW \quad [\mathrm{mm}]$$
     *(where $p$ is allowable depletion fraction, default $0.50$)*

#### Step 2.5: Daily Mass-Balance Soil Water Bucket Model
- **Concept**: The root zone behaves like a water bucket. Daily depletion $D_i$ tracks water leaving via crop transpiration ($ET_c$) vs. water entering via effective rain ($P_{\mathrm{eff}}$) and farmer irrigation ($I$):
  $$D_i = D_{i-1} + ET_{c,i} - P_{\mathrm{eff},i} - I_i \quad [\mathrm{mm}]$$
  *(where effective rain $P_{\mathrm{eff},i} = \min(P_i \times 0.80, P_i)$)*

#### Step 2.6: Decision Boundary & Volumetric Equipment Runtime Calculation
- **Concept**: Converts raw soil depletion depth ($D_i$) into practical pump operating durations:
  1. **Decision Check**:
     - If $D_i < RAW \rightarrow$ `status = "SOIL MOISTURE OPTIMAL"`, `recommended_water_mm = 0.0`, Pump Runtime = `0 Hours 0 Mins`.
     - If $D_i \ge RAW \rightarrow$ `status = "IRRIGATE IMMEDIATELY"`, $D_{\mathrm{net}} = D_i \text{ mm}$.
  2. **Gross Water Adjusted for System Efficiency**:
     $$D_{\mathrm{gross}} = \frac{D_{\mathrm{net}}}{\eta} \quad [\mathrm{mm}]$$
     *(Drip efficiency $\eta = 0.90$, Sprinkler $\eta = 0.75$, Flood $\eta = 0.50$)*
  3. **Total Volumetric Water Volume**:
     $$V_{\mathrm{liters}} = D_{\mathrm{gross}} \times A_{\mathrm{sqm}} \quad [\mathrm{Liters}]$$
  4. **Pump Runtime Duration**:
     $$T_{\mathrm{seconds}} = \frac{V_{\mathrm{liters}}}{Q_{\mathrm{pump}}}$$
     $$\text{Pump Hours} = \left\lfloor \frac{T_{\mathrm{seconds}}}{3600} \right\rfloor, \quad \text{Pump Minutes} = \mathrm{round}\left( \frac{T_{\mathrm{seconds}} \pmod{3600}}{60} \right)$$

---

### 3.3 Phase 3: Smart Rain Hold Advisory & Cumulative ROI Telemetry

Before confirming pump advisories, JalDrishti inspects the **upcoming 48-hour satellite precipitation forecast** ($P_{\mathrm{upcoming}}$):

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

#### Single-Run & Cumulative ROI Equations:
1. **Single-Run Cost Saved**:
   $$C_{\mathrm{run}} = \mathrm{round}(T_{\mathrm{saved}} \times 80) \quad [\mathrm{INR}]$$
   *(Benchmark operating tariff: ₹$80.0$ / hour for electricity & diesel generator fuel)*

2. **Cumulative Water Saved ($V_{\mathrm{cum}}$)**:
   $$V_{\mathrm{cum}} = \mathrm{round}(D_{\mathrm{gross}} \times A_{\mathrm{sqm}} \times (N_{\mathrm{skipped}} + 3)) \quad [\mathrm{Liters}]$$

3. **Cumulative Financial Savings ($S_{\mathrm{cum}}$)**:
   $$S_{\mathrm{cum}} = \mathrm{round}(T_{\mathrm{cum}} \times 80 + (N_{\mathrm{skipped}} \times C_{\mathrm{run}})) \quad [\mathrm{INR}]$$

4. **Cumulative Carbon Footprint Reduced ($E_{\mathrm{CO2}}$)**:
   $$E_{\mathrm{CO2}} = \mathrm{round}(T_{\mathrm{cum}} \times 2.8, \, 1) \quad [\mathrm{kg\ CO}_2]$$

---

### 3.4 Phase 4: 5-Tab Field Analytics Suite

The mobile client `AnalyticsScreen` provides a modular 5-tab breakdown of field performance:

```text
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                FIELD ANALYTICS SUITE                                    │
│  [🌦️ Weather Stats] [📊 Daily Trend] [💡 Smart Insights] [🌊 Water Balance] [📋 History]│
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

1. **Tab 0: Weather Stats (`weather_stats_tab.dart`)**:
   - Maps 6-day weather forecast directly from `daily_breakdown`.
   - Displays Max/Min temperatures, relative humidity %, wind speed (km/h), precipitation depth (mm), and $ET_0$ reference evapotranspiration.
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

### 3.5 Phase 5: JalSathi AI Multilingual Agronomy Companion

JalSathi AI is an intelligent RAG-driven voice/text assistant designed for multilingual Indian farmers:

```mermaid
graph TD
    A["Farmer Voice Mic Input / Text Query"] --> B["SpeechToText (STT) Engine:<br/>Recognize Speech in bn_IN / hi_IN / en_IN"]
    B --> C["Send Query to FastAPI Backend:<br/>POST /api/v1/jalsathi/chat"]
    C --> D["ChromaDB Vector Store Search:<br/>Retrieve Top-3 ICAR Package of Practices"]
    D --> E["Groq LLM (Llama 3 70B):<br/>Apply Multilingual Prompt & Agronomy Context"]
    E --> F["Return Structured Solution:<br/>Native Script (Bengali / Hindi / English)"]
    F --> G["Flutter Client UI:<br/>Display Response + Trigger FlutterTTS Audio"]
```

#### Key Features & Technical Flow:
- **Speech-to-Text (STT) & Audio Decibel Pulsing**: The microphone button dynamically scales up and down based on decibel volume level callbacks (`onSoundLevelChange`).
- **Text-to-Speech (TTS) Voice Narration**: Every bot message includes a **`Listen 🔊`** button using `flutter_tts` tuned to farmer speech rates ($0.45\times$).
- **Vector RAG Knowledge Base (`pop_docs/`)**: ChromaDB vector store indexing 5 official ICAR Package of Practices guides:
  - `paddy_rice_guide.txt`: Stem Borer, Brown Plant Hopper, Blast Disease, AWD irrigation.
  - `potato_guide.txt`: Late Blight (*Phytophthora infestans*), Mancozeb/Cymoxanil, Copper Oxychloride, earthing up.
  - `wheat_guide.txt`: Yellow Rust (*Puccinia striiformis*), Propiconazole 25 EC, CRI irrigation.
  - `mustard_guide.txt`: Mustard Aphid (*Lipaphis erysimi*), Thiamethoxam 25% WG, NSKE 5%.
  - `maize_guide.txt`: Fall Armyworm (*Spodoptera frugiperda*), Emamectin Benzoate 5% SG, *Metarhizium anisopliae*.
- **Structured Solution Format**:
  1. 🧪 **Chemical Treatment**: Exact chemical trade names and dosages per acre (e.g. Cartap 4G @ 10 kg/acre).
  2. 🌿 **Organic / Bio-Alternative**: Natural treatments (Neem oil, *Pseudomonas*, *Trichoderma*).
  3. 💡 **Preventive Cultural Tip**: Field drainage, earthing up, and sanitation advice.

---

### 3.6 Phase 6: Emergency Alerts & Notification Center

JalDrishti features a dual-layer notification architecture driven by `NotificationProvider` and `NotificationService`:

1. **Critical Water Deficit Alert**: Triggered when root zone depletion $D_i \ge RAW$. Notifies the farmer with exact pump operating duration required.
2. **Smart Rain Hold Emergency Alert**: Triggered when heavy rainfall ($P \ge 5.0\text{ mm}$) is forecast. Advises skipping pump runs to prevent crop asphyxiation and save pumping costs.
3. **Pest & Disease Microclimate Outbreak Warning**: Triggered when temperature and relative humidity match crop-specific epidemiological sporulation rules (e.g., Rice Blast, Potato Late Blight, Fall Armyworm).

---

## 🗄️ Chapter 4: Database Schema & Entity Relationships

The relational database architecture is hosted on **Supabase PostgreSQL** and managed via SQLAlchemy ORM models:

```mermaid
erDiagram
    users ||--o{ user_profiles : "has profile"
    users ||--o{ farm_plots : "owns plots"
    farm_plots ||--o{ irrigation_logs : "has logs"
    farm_plots ||--o{ pest_advisories : "generates advisories"

    users {
        uuid id PK
        string username
        string phone_number
        string hashed_password
        datetime created_at
    }

    user_profiles {
        uuid id PK
        uuid user_id FK
        string first_name
        string last_name
        string state
        string district
        string location_name
        float farm_area_acres
        string interested_crop
        string preferred_language
    }

    farm_plots {
        uuid id PK
        uuid user_id FK
        string name
        float latitude
        float longitude
        string crop_id
        date sowing_date
        float area_acres
        float pump_hp
        float pump_flow_lps
        string irrigation_method
        string soil_type
    }

    irrigation_logs {
        uuid id PK
        uuid farm_plot_id FK
        float applied_mm
        date applied_date
        string notes
        datetime created_at
    }

    pest_advisories {
        uuid id PK
        uuid farm_plot_id FK
        string pest_name
        string risk_level
        string Advisory_message
        datetime created_at
    }
```

---

## ❓ Chapter 5: System Technical FAQ & Core Engineering QA Matrix

### Q1: "How is JalDrishti different from existing weather or farming apps (e.g., Meghdoot, Agstack)?"
> **Answer**: Most existing agricultural apps only provide generic region-wide weather forecasts or text bulletins. JalDrishti provides **field-specific volumetric water calculations** by executing the FAO-56 Penman-Monteith equation using live satellite data ($ET_0, K_c, \theta_{\mathrm{FC}}, \theta_{\mathrm{WP}}$). It converts abstract soil moisture science into practical **Pump Hours and Minutes** customized to the farmer's individual pump HP and flow rate.

### Q2: "How do you calculate soil moisture without physical IoT soil sensors?"
> **Answer**: We use the **ISRIC SoilGrids 250m Global Satellite Database** to extract topsoil sand % and clay % for the exact latitude/longitude of the field. We then calculate Field Capacity ($\theta_{\mathrm{FC}}$) and Permanent Wilting Point ($\theta_{\mathrm{WP}}$) using hydraulic pedotransfer functions, and maintain a daily **Mass-Balance Soil Water Bucket Model** ($D_i = D_{i-1} + ET_{c,i} - P_{\mathrm{eff},i} - I_i$). This provides $\ge 85\%$ accuracy comparable to physical sensors with zero hardware cost for farmers.

### Q3: "What is the scientific basis for your Smart Rain Hold engine?"
> **Answer**: The engine evaluates upcoming 48-hour precipitation ($P_{\mathrm{upcoming}}$). If incoming rain $\ge 5.0\mathrm{~mm}$ is forecast, irrigating today would exceed Field Capacity ($\theta_{\mathrm{FC}}$), driving soil into saturation and root hypoxia. Overriding the pump schedule protects crop root respiration and saves approximately ₹$240$ in single-run pumping costs per plot.

### Q4: "How does JalSathi AI avoid hallucinating wrong chemical dosages?"
> **Answer**: We employ **Retrieval-Augmented Generation (RAG)** using ChromaDB and HuggingFace embeddings (`all-MiniLM-L6-v2`). Before generating a response, the backend retrieves verified ICAR/SAU Package of Practices (PoP) context documents. The LLM (Groq Llama 3 70B) is strictly constrained by system prompts to format responses with exact chemical dosages per acre alongside organic bio-pesticide alternatives.

### Q5: "Why is $ET_0$ calculated independently of soil properties in Phase 2?"
> **Answer**: By FAO-56 scientific standards, $ET_0$ measures **pure atmospheric evaporative demand** for a standardized grass reference surface. Soil properties do not influence atmospheric radiation or wind speed. Mixing soil parameters into $ET_0$ would violate hydrological physics. Soil properties enter later when calculating root zone storage capacities ($TAW / RAW$) in the Soil Water Bucket Model.

### Q6: "How does the system handle crops with different sowing dates?"
> **Answer**: The system computes `elapsed_days = (today - sowing_date)` dynamically for each individual farm plot. It interpolates $K_c(t)$ and root depth $Z_r(t)$ along the crop's specific 4-stage ICAR growth curve. A field planted 10 days ago receives early-stage initial parameters, while a field planted 50 days ago receives peak mid-season parameters.

### Q7: "Why is effective rainfall ($P_{\mathrm{eff}}$) calculated as $\min(P \times 0.80, P)$ instead of using total rainfall ($P$)?"
> **Answer**: Not all satellite rainfall reaches crop roots. A portion of heavy rainfall is lost to surface runoff, canopy interception, and rapid deep percolation below the root zone. Applying an $80\%$ effective rainfall coefficient ($P_{\mathrm{eff}} = 0.80 \times P$) accounts for real-world runoff losses in agricultural fields according to FAO guidelines.

### Q8: "What is the significance of the Water Satisfaction Index ($WSI$) in Tab 3 of Field Analytics?"
> **Answer**: $WSI$ measures the ratio of total water received (applied irrigation + effective rain) to actual crop water demand ($ET_c$):
> $$WSI = \frac{\text{Applied Water} + \text{Effective Rain}}{ET_c} \times 100\%$$
> A $WSI$ between $90\% - 110\%$ indicates optimal hydration. A $WSI < 80\%$ alerts the farmer to drought stress, while a $WSI > 130\%$ warns of over-watering and risk of root asphyxiation.

---

## 📌 Summary Code Directory Index

| Subsystem Module | Backend Python Code | Mobile Flutter Code |
|---|---|---|
| **User Authentication & Profiles** | `app/api/v1/endpoints/auth.py` | `lib/screens/login_screen.dart`<br/>`lib/screens/register_screen.dart` |
| **Farm Plot Management** | `app/api/v1/endpoints/farm_plots.py` | `lib/screens/add_edit_farm_plot_screen.dart` |
| **FAO-56 Penman-Monteith Hydrology** | `app/engine/penman_monteith.py`<br/>`app/engine/water_bucket_model.py` | `lib/providers/irrigation_provider.dart`<br/>`lib/widgets/dashboard_pump_card.dart` |
| **Smart Rain Hold & ROI Telemetry** | `app/api/v1/endpoints/irrigation.py` | `lib/widgets/smart_rain_hold_card.dart`<br/>`lib/widgets/farmer_roi_savings_card.dart` |
| **5-Tab Field Analytics Suite** | `app/api/v1/endpoints/irrigation.py` | `lib/screens/analytics_screen.dart`<br/>`lib/screens/analytics/` |
| **JalSathi AI Multilingual Assistant** | `app/services/rag_service.py` | `lib/screens/chat_screen.dart`<br/>`lib/providers/chat_provider.dart` |
| **Emergency Alerts & Notifications** | `app/engine/pest_disease_engine.py` | `lib/providers/notification_provider.dart`<br/>`lib/core/services/notification_service.dart` |
