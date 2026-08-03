# 📐 FAO-56 Penman-Monteith Hydrological Engine & Bucket Model

## 📖 Overview
The core irrigation recommendation engine in **JalDrishti** strictly follows the **FAO-56 Irrigation and Drainage Paper Guidelines**. It computes daily reference crop evapotranspiration ($ET_0$), dynamic crop evapotranspiration ($ET_c$), daily soil water depletion, and translates water volume into actionable pump runtimes.

---

## 🧮 Mathematical Formulas

### 1. FAO-56 Penman-Monteith Equation for Reference Evapotranspiration ($ET_0$)

$$ET_0 = \frac{0.408 \Delta (R_n - G) + \gamma \frac{900}{T + 273} u_2 (e_s - e_a)}{\Delta + \gamma (1 + 0.34 u_2)}$$

Where:
- $ET_0$: Reference evapotranspiration [$\text{mm day}^{-1}$]
- $R_n$: Net radiation at the crop surface [$\text{MJ m}^{-2} \text{day}^{-1}$]
- $G$: Soil heat flux density [$\text{MJ m}^{-2} \text{day}^{-1}$] (assumed $0$ for daily step)
- $T$: Mean daily air temperature at $2\text{ m}$ height [$^\circ\text{C}$]
- $u_2$: Wind speed at $2\text{ m}$ height [$\text{m s}^{-1}$]
- $e_s$: Saturation vapour pressure [$\text{kPa}$]
- $e_a$: Actual vapour pressure [$\text{kPa}$]
- $e_s - e_a$: Vapour pressure deficit [$\text{kPa}$]
- $\Delta$: Slope of saturation vapour pressure curve [$\text{kPa }^\circ\text{C}^{-1}$]
- $\gamma$: Psychrometric constant [$\text{kPa }^\circ\text{C}^{-1}$]

---

### 2. Dynamic Crop Coefficient ($K_c$) & Crop Evapotranspiration ($ET_c$)

Crop water demand changes dynamically throughout the growth season:

$$ET_c = ET_0 \times K_c(t)$$

```text
  Kc Value
    ▲
Kc_mid ├───────────────────────────┐
       │                          │ ╲
       │   Stage 2 (Dev)          │  ╲ Stage 4 (Late)
       │  ╱                       │   ╲
Kc_ini ├─╱   Stage 1 (Ini)        │    ╲
       └─┴────────────────────────┴────┴───────────► Time (Days)
        0   L_ini               L_mid  L_late
```

- **Stage 1 (Initial)**: $K_c = K_{c,\text{ini}}$
- **Stage 2 (Development)**: Linear interpolation from $K_{c,\text{ini}}$ to $K_{c,\text{mid}}$
- **Stage 3 (Mid-Season)**: $K_c = K_{c,\text{mid}}$ (Maximum transpiration)
- **Stage 4 (Late-Season)**: Linear interpolation from $K_{c,\text{mid}}$ to $K_{c,\text{end}}$

---

### 3. Soil Water Bucket Balance Model

Daily depletion ($D_i$) in the root zone is calculated using the mass-balance bucket model:

$$D_i = D_{i-1} + ET_{c,i} - P_i - I_i + RO_i + DP_i$$

Where:
- $D_{i-1}$: Water depletion at the end of previous day [$\text{mm}$]
- $P_i$: Daily precipitation [$\text{mm}$]
- $I_i$: Applied irrigation depth [$\text{mm}$]
- $RO_i$: Surface runoff [$\text{mm}$]
- $DP_i$: Deep percolation beyond root zone [$\text{mm}$]

#### Readily Available Water ($RAW$) Threshold:

$$TAW = 1000 \times (\theta_{FC} - \theta_{WP}) \times Z_r$$
$$RAW = p \times TAW$$

Irrigation is triggered when $D_i \ge RAW$.

---

### 4. Pump Runtime Calculation Engine

To convert net water demand ($RAW$) into practical pumping hours for the farmer:

$$Net\_Water\_Depth = D_i \text{ [mm]}$$
$$Gross\_Water\_Depth = \frac{Net\_Water\_Depth}{\eta_{irrigation}}$$

Where efficiency ($\eta_{irrigation}$) is:
- **Drip Irrigation**: $90\%$
- **Overhead Sprinkler**: $75\%$
- **Surface / Flood Irrigation**: $50\%$

#### Total Volume & Pump Time:

$$Total\_Liters = Gross\_Water\_Depth \text{ [mm]} \times (Area \text{ [Acres]} \times 4046.86 \text{ m}^2/\text{Acre})$$
$$Pump\_Time \text{ [seconds]} = \frac{Total\_Liters}{Pump\_Flow\_Rate \text{ [L/sec]}}$$

$$\text{Pump Hours} = \lfloor \frac{Pump\_Time}{3600} \rfloor, \quad \text{Pump Minutes} = \text{round}(\frac{Pump\_Time \pmod{3600}}{60})$$

---

## 💻 Code Reference

- **Penman-Monteith Calculation**: [`app/engine/penman_monteith.py`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/penman_monteith.py)
- **Soil Water Bucket Model**: [`app/engine/water_bucket_model.py`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/water_bucket_model.py)
- **Crop Parameters Database**: [`app/engine/crop_coefficients.json`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/crop_coefficients.json)
- **Irrigation API Endpoint**: `POST /api/v1/irrigation/recommendation`
