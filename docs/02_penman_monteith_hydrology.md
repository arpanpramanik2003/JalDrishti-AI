# 📐 FAO-56 Penman-Monteith Hydrological Engine & Soil Water Bucket Model

## 📖 1. Overview & Core Objective

The **JalDrishti Hydrological Engine** implements the scientific principles of **FAO-56 Irrigation and Drainage Paper Guidelines** to provide precision agricultural irrigation advisories. 

Traditional farming relies on fixed calendars or visual soil inspection, leading to severe water wastage, nutrient leaching, or crop drought stress. JalDrishti eliminates guesswork by dynamically modeling daily reference crop evapotranspiration ($ET_0$), actual crop water consumption ($ET_c$), dynamic root zone expansion ($Z_r$), satellite-derived soil moisture retention ($TAW/RAW$), and daily mass-balance water depletion ($D_i$).

```text
┌─────────────────────────┐    ┌─────────────────────────┐    ┌─────────────────────────┐
│  Meteorology & Weather  │ ──>│ FAO-56 Penman-Monteith  │ ──>│ Reference Evapo-        │
│  (Open-Meteo API)       │    │ Equation Engine         │    │ transpiration (ETo)     │
└─────────────────────────┘    └─────────────────────────┘    └────────────┬────────────┘
                                                                           │
┌─────────────────────────┐    ┌─────────────────────────┐                 │
│  ICAR Agronomy Rules    │ ──>│ Dynamic Crop Factor     │ ──> ETc = ETo × Kc(t)
│  (Growth Stages & Kc)   │    │ Kc(t) & Root Depth Zr   │                 │
└─────────────────────────┘    └─────────────────────────┘                 ▼
┌─────────────────────────┐    ┌─────────────────────────┐    ┌─────────────────────────┐
│  Soil Physical Textures │ ──>│ Mass-Balance Soil Water │ ──>│ Net & Gross Water Depth │
│  (ISRIC SoilGrids API)  │    │ Bucket Depletion Model  │    │ ──> Pumping Duration    │
└─────────────────────────┘    └─────────────────────────┘    └─────────────────────────┘
```

---

## 🛰️ 2. Data Sources & Ingestion Matrix

Every variable in JalDrishti's hydrological pipeline is sourced dynamically from authoritative satellite telemetry and scientific datasets:

| Data Parameter | Source / Service | Code Ingestion Location | Description & Unit |
|---|---|---|---|
| **Max / Min Temperature ($T_{\text{max}}, T_{\text{min}}$)** | Open-Meteo Weather API | [`app/services/weather_service.py`](file:///d:/jaldrishti/jaldrishti-backend/app/services/weather_service.py) | 2-meter air temperature [$^\circ\text{C}$] |
| **Relative Humidity ($\text{RH}$)** | Open-Meteo Weather API | [`app/services/weather_service.py`](file:///d:/jaldrishti/jaldrishti-backend/app/services/weather_service.py) | Daily mean relative humidity [$\%$] |
| **Wind Speed ($u_2$)** | Open-Meteo Weather API | [`app/services/weather_service.py`](file:///d:/jaldrishti/jaldrishti-backend/app/services/weather_service.py) | 2-meter wind velocity [$\text{m/s}$] |
| **Solar Radiation ($R_s$)** | Open-Meteo Weather API | [`app/services/weather_service.py`](file:///d:/jaldrishti/jaldrishti-backend/app/services/weather_service.py) | Daily global solar radiation [$\text{MJ/m}^2/\text{day}$] |
| **Precipitation ($P$)** | Open-Meteo Weather API | [`app/services/weather_service.py`](file:///d:/jaldrishti/jaldrishti-backend/app/services/weather_service.py) | 24-hour satellite rainfall depth [$\text{mm}$] |
| **Clay & Sand Content** | ISRIC SoilGrids 250m API | [`app/services/soil_service.py`](file:///d:/jaldrishti/jaldrishti-backend/app/services/soil_service.py) | Topsoil clay and sand composition [$\%$] |
| **Crop Stage & $K_c$ Curves** | ICAR Package of Practices | [`app/engine/crop_coefficients.json`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/crop_coefficients.json) | Stage durations (days) and base $K_c$ values |
| **Field Size & Pump HP** | Farmer Plot Profile | PostgreSQL (`farm_plots` table) | Plot area [Acres] and pump rating [HP, Flow L/s] |

---

## 🧮 3. Step-by-Step Mathematical Equations

### Step 1: Reference Crop Evapotranspiration ($ET_0$)

The **FAO-56 Penman-Monteith equation** represents the rate of evapotranspiration from a standardized grass reference surface ($0.12\text{ m}$ height, surface resistance $70\text{ s/m}$, albedo $0.23$):

$$ET_0 = \frac{0.408 \Delta (R_n - G) + \gamma \frac{900}{T + 273} u_2 (e_s - e_a)}{\Delta + \gamma (1 + 0.34 u_2)}$$

#### Intermediate Variable Calculations:

1. **Mean Daily Air Temperature ($T_{\text{mean}}$)**:
   $$T_{\text{mean}} = \frac{T_{\text{max}} + T_{\text{min}}}{2} \quad [^\circ\text{C}]$$

2. **Atmospheric Pressure ($P$) & Psychrometric Constant ($\gamma$)**:
   $$P = 101.3 \times \left( \frac{293 - 0.0065 z}{293} \right)^{5.26} \quad [\text{kPa}]$$
   $$\gamma = 0.000665 \times P \quad [\text{kPa/}^\circ\text{C}]$$
   *(where $z$ is elevation above sea level in meters)*

3. **Slope of Saturation Vapour Pressure Curve ($\Delta$)**:
   $$\Delta = \frac{4098 \times \left[ 0.6108 \exp\left( \frac{17.27 T_{\text{mean}}}{T_{\text{mean}} + 237.3} \right) \right]}{(T_{\text{mean}} + 237.3)^2} \quad [\text{kPa/}^\circ\text{C}]$$

4. **Saturation Vapour Pressure ($e_s$) & Actual Vapour Pressure ($e_a$)**:
   $$e^0(T) = 0.6108 \exp\left( \frac{17.27 T}{T + 237.3} \right) \quad [\text{kPa}]$$
   $$e_s = \frac{e^0(T_{\text{max}}) + e^0(T_{\text{min}})}{2} \quad [\text{kPa}]$$
   $$e_a = \left( \frac{\text{RH}}{100} \right) \times e_s \quad [\text{kPa}]$$

5. **Net Solar Radiation ($R_n$)**:
   $$R_{ns} = 0.77 \times R_s \quad (\text{Net shortwave radiation})$$
   $$R_{nl} = 0.10 \times R_s \quad (\text{Net longwave radiation loss approximation})$$
   $$R_n = R_{ns} - R_{nl} \quad [\text{MJ/m}^2/\text{day}]$$

6. **Soil Heat Flux ($G$)**:
   $$G = 0.0 \quad [\text{MJ/m}^2/\text{day}] \quad (\text{Assumed zero for daily time steps})$$

#### Penman-Monteith Variable Glossary:

- **`ETo`**: Reference crop evapotranspiration rate [`mm/day`]
- **`Rn`**: Net surface radiation flux density [`MJ/m²/day`]
- **`G`**: Soil heat flux density [`MJ/m²/day`] (Set to `0.0` for daily calculations)
- **`T`**: Mean daily air temperature at 2m height [`°C`]
- **`u₂`**: Wind speed measured at 2m height [`m/s`]
- **`eₛ`**: Saturation vapour pressure of the air [`kPa`]
- **`eₐ`**: Actual vapour pressure of the air [`kPa`]
- **`eₛ - eₐ`**: Vapour pressure deficit (VPD) [`kPa`]
- **`Δ` (Delta)**: Slope of the saturation vapour pressure curve [`kPa/°C`]
- **`γ` (Gamma)**: Psychrometric constant [`kPa/°C`]

---

### Step 2: Dynamic Crop Coefficient ($K_c$) & Crop Transpiration ($ET_c$)

Crop water demand varies significantly across the growing season. The actual crop evapotranspiration ($ET_c$) is determined by adjusting $ET_0$ with a time-dependent Crop Coefficient $K_c(t)$:

$$ET_c = ET_0 \times K_c(t)$$

#### Dynamic $K_c$ Growth Curve:

```text
  Kc Value
    ▲
Kc_mid ├───────────────────────────────┐
       │                              │ ╲
       │   Stage 2 (Development)      │  ╲ Stage 4 (Late Season)
       │  ╱                           │   ╲
Kc_ini ├─╱   Stage 1 (Initial)        │    ╲
       └─┴────────────────────────────┴────┴───────────► Time (Days)
        0   L_initial               L_mid  L_late
```

1. **Stage 1 (Initial Stage - Sowing/Germination)**:
   $$K_c = K_{c,\text{ini}}$$
   $$Z_r = \max(0.15, Z_{r,\text{max}} \times 0.30) \quad [\text{m}]$$

2. **Stage 2 (Crop Development / Vegetative)**:
   $$\text{Progress} = \frac{\text{Elapsed Days} - L_{\text{ini}}}{L_{\text{dev}}}$$
   $$K_c = K_{c,\text{ini}} + \text{Progress} \times (K_{c,\text{mid}} - K_{c,\text{ini}})$$
   $$Z_r = Z_{r,\text{max}} \times (0.30 + 0.70 \times \text{Progress}) \quad [\text{m}]$$

3. **Stage 3 (Mid-Season - Flowering & Yield Formation)**:
   $$K_c = K_{c,\text{mid}}$$
   $$Z_r = Z_{r,\text{max}} \quad [\text{m}]$$

4. **Stage 4 (Late Season - Ripening & Maturity)**:
   $$\text{Progress} = \frac{\text{Elapsed Days} - (L_{\text{ini}} + L_{\text{dev}} + L_{\text{mid}})}{L_{\text{late}}}$$
   $$K_c = K_{c,\text{mid}} + \text{Progress} \times (K_{c,\text{end}} - K_{c,\text{mid}})$$
   $$Z_r = Z_{r,\text{max}} \quad [\text{m}]$$

---

### Step 3: ISRIC Soil Physics & Soil Moisture Holding Capacity

Using clay and sand percentages from satellite soil databases, JalDrishti computes the **Field Capacity** ($\theta_{\text{FC}}$), **Permanent Wilting Point** ($\theta_{\text{WP}}$), **Total Available Water** ($TAW$), and **Readily Available Water** ($RAW$):

1. **Field Capacity ($\theta_{\text{FC}}$)**:
   $$\theta_{\text{FC}} = 0.10 + 0.0025 \times \text{Clay}\% + 0.0005 \times (100 - \text{Sand}\%) \quad [\text{m}^3/\text{m}^3]$$

2. **Permanent Wilting Point ($\theta_{\text{WP}}$)**:
   $$\theta_{\text{WP}} = 0.02 + 0.0020 \times \text{Clay}\% \quad [\text{m}^3/\text{m}^3]$$

3. **Total Available Water ($TAW$)**:
   $$TAW = 1000 \times (\theta_{\text{FC}} - \theta_{\text{WP}}) \times Z_r \quad [\text{mm}]$$

4. **Readily Available Water ($RAW$) Threshold**:
   $$RAW = p \times TAW \quad [\text{mm}]$$
   *(where $p$ is the crop-specific allowable depletion fraction, typically $0.40 - 0.65$)*

---

### Step 4: Daily Mass-Balance Soil Water Bucket Model

Daily soil moisture depletion ($D_i$) in the effective root zone ($Z_r$) is tracked via a mass-balance conservation equation:

$$D_i = D_{i-1} + ET_{c,i} - P_{\text{eff},i} - I_i$$

Where:
- **`D_{i}`**: Root zone water depletion at the end of day $i$ [`mm`]
- **`D_{i-1}`**: Root zone water depletion at the end of previous day $i-1$ [`mm`]
- **`ET_{c,i}`**: Crop evapotranspiration loss on day $i$ [`mm`]
- **`P_{eff,i}`**: Effective rainfall entering root zone on day $i$ [`mm`], calculated as:
  $$P_{\text{eff},i} = \min(P_i \times 0.80, P_i)$$
- **`I_{i}`**: Net irrigation water applied on day $i$ [`mm`]

#### Decision Boundary Rules:

- **Condition 1 ($D_i < RAW$)**: Soil moisture is within optimal levels (`SOIL MOISTURE OPTIMAL`). No pumping required. Recommended net water = `0.0 mm`.
- **Condition 2 ($D_i \ge RAW$)**: Soil moisture has reached stress thresholds (`IRRIGATE IMMEDIATELY`). Irrigation required. Recommended net water depth = $D_i$ `mm`.

---

### Step 5: Irrigation Efficiency & Pump Operating Hours Engine

When irrigation is triggered, net water depth ($D_i$) is converted into gross depth based on field application efficiency ($\eta_{\text{irrigation}}$):

$$Gross\_Water\_Depth = \frac{Net\_Water\_Depth}{\eta_{\text{irrigation}}}$$

#### System Efficiency Map ($\eta_{\text{irrigation}}$):

- **Drip Irrigation**: $\eta = 90\%$ ($0.90$)
- **Overhead Sprinkler**: $\eta = 75\%$ ($0.75$)
- **Surface / Flood Irrigation**: $\eta = 50\%$ ($0.50$)

#### Volumetric Flow & Pump Operating Runtime:

1. **Total Volumetric Water Needed ($V_{\text{liters}}$)**:
   $$\text{Area}_{\text{sqm}} = \text{Area}_{\text{acres}} \times 4046.86 \quad [\text{m}^2]$$
   $$V_{\text{liters}} = Gross\_Water\_Depth \text{ [mm]} \times \text{Area}_{\text{sqm}}$$
   *(Note: $1\text{ mm}$ depth over $1\text{ m}^2$ area equals exactly $1\text{ Liter}$ of water)*

2. **Total Pumping Seconds ($T_{\text{seconds}}$)**:
   $$T_{\text{seconds}} = \frac{V_{\text{liters}}}{Q_{\text{pump}} \text{ [L/s]}}$$
   *(where $Q_{\text{pump}}$ is the pump flow rate in Liters per second)*

3. **Hours & Minutes Formatting for Farmer**:
   $$\text{Pump Hours} = \lfloor \frac{T_{\text{seconds}}}{3600} \rfloor$$
   $$\text{Pump Minutes} = \text{round}\left( \frac{T_{\text{seconds}} \pmod{3600}}{60} \right)$$

---

## 📊 4. End-to-End Execution Flowchart

```mermaid
graph TD
    A["Request: Farm Plot ID & Coordinates"] --> B["Fetch Open-Meteo Weather & Solar Radiation"]
    A --> C["Fetch ISRIC SoilGrids Clay/Sand Content"]
    A --> D["Fetch Crop Sowing Date & Characteristics"]

    B --> E["PenmanMonteithEngine: Calculate ETo (mm/day)"]
    D --> F["SoilWaterBucketModel: Calculate Kc(t) & Root Depth Zr"]
    C --> G["SoilWaterBucketModel: Calculate FC, WP, TAW & RAW"]

    E & F --> H["Calculate ETc = ETo × Kc(t)"]
    G & H --> I["SoilWaterBucketModel: Run Daily Mass Balance Di"]

    I --> J{"Is Di >= RAW Threshold?"}
    J -- No --> K["Status: SOIL MOISTURE OPTIMAL<br/>Net Water = 0.0 mm<br/>Pump Time = 0 Hours 0 Mins"]
    J -- Yes --> L["Calculate Gross Water = Net Water / Efficiency"]

    L --> M["Calculate Total Volume = Gross Water × Plot Area"]
    M --> N["Calculate Pump Runtime = Volume / Flow Rate"]
    N --> O["Output: Exact Pump Operating Hours & Minutes<br/>Status: IRRIGATE IMMEDIATELY"]
```

---

## 💻 5. Python Implementation Reference

All hydrological calculations are implemented in modular Python classes within the backend engine:

- **Penman-Monteith Engine**: [`app/engine/penman_monteith.py`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/penman_monteith.py)
- **Soil Water Bucket Model**: [`app/engine/water_bucket_model.py`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/water_bucket_model.py)
- **Crop Coefficient Config**: [`app/engine/crop_coefficients.json`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/crop_coefficients.json)
- **API Endpoint Router**: [`app/api/v1/endpoints/irrigation.py`](file:///d:/jaldrishti/jaldrishti-backend/app/api/v1/endpoints/irrigation.py)
