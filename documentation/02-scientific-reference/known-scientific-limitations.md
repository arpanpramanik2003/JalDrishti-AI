# Known Scientific Limitations & Agronomic Assumptions

> **Audience**: Agronomists, hydrological researchers, and engineering leads.  
> **Purpose**: A centralized, honest disclosure of physical simplifications, unvalidated assumptions, and known operational risks in JalDrishti's current scientific pipeline.

---

## 1. Spatial Resolution & Soil Texture Coarsening

- **Actual Resolution**: Soil texture fractions ($\% \text{clay}$, $\% \text{sand}$) are queried from ISRIC SoilGrids v2.0 using a $0.05^\circ$ coordinate binning factor ([`soilgrids_service.py:64-65`](file:///d:/jaldrishti/jaldrishti-backend/app/services/soilgrids_service.py#L64-L65)):
  $$\text{grid\_lat} = \frac{\text{round}(\text{lat} \times 20)}{20}, \quad \text{grid\_lon} = \frac{\text{round}(\text{lon} \times 20)}{20}$$
- **Physical Grid Scale**: At typical Indian latitudes ($20^\circ\text{--}28^\circ\text{N}$), $0.05^\circ$ represents approximately $5.5\text{ km} \times 5.1\text{ km}$ per grid cell ($\approx 28\text{ km}^2$).
- **Limitation**: Highly heterogeneous micro-topographies (e.g. river levee sands juxtaposed against back-swamp heavy clays within 500 meters) will be assigned the same homogenized grid cell value. Farmers on atypical micro-plots must use the manual soil texture override preset in plot settings.
- **Legacy Correction**: Earlier project documentation claimed "native $250\text{ m}$ sub-plot hyper-resolution". That claim was inaccurate and has been withdrawn.

---

## 2. In-Situ Physical Sensor Benchmarking (Unvalidated Accuracy)

- **Ground-Truthing Status**: JalDrishti has **not** yet been empirically benchmarked against in-situ, calibrated physical soil moisture instruments (such as Time-Domain Reflectometry [TDR], capacitance probes, or neutron moisture meters).
- **Model Uncertainty**: The FAO-56 Penman-Monteith equation and Saxton-Rawls pedotransfer functions are globally respected empirical models with decades of peer-reviewed validation. However, numerical predictions of daily depletion without local calibration are subject to:
  - Satellite numerical weather prediction variance ($\pm 1\text{--}2^\circ\text{C}$ temperature, localized convective rain errors)
  - Estimated root depth variance across diverse local landraces
  - Simplified effective rainfall fractions ($P_{\text{eff}} = 0.80 \times P$)
- **Ethical & Engineering Positioning**: JalDrishti does not claim "$\ge 85\%$ IoT-sensor-equivalent precision". It is positioned honestly as a zero-hardware decision-support tool providing defensible operational guidance.

---

## 3. Static Rain Hold Heuristics (Audit Finding 6.4)

- **Current Implementation**: The Smart Rain Hold engine evaluates three static rainfall thresholds ([`constants.py:86-98`](file:///d:/jaldrishti/jaldrishti-backend/app/core/constants.py#L86-L98)):
  - $P_{24\text{h}} \ge 3.0\text{ mm}$
  - $P_{48\text{h}} \ge 5.0\text{ mm}$
  - $P_{\text{today}} \ge 4.0\text{ mm}$
- **Agronomic Limitation**: These thresholds are fixed numbers applied uniformly regardless of soil texture or current soil moisture deficit:
  - In a sandy loam with low retention ($TAW \approx 40\text{ mm}$), $5.0\text{ mm}$ of forecast rain replenishes over $12\%$ of available storage, easily justifying a hold.
  - In a deep heavy clay with severe depletion ($D_i \approx 80\text{ mm}$), $5.0\text{ mm}$ represents only $6\%$ of the deficit, leaving roots in moisture stress despite the hold.
- **Future Enhancement Path**: Future iterations should replace static millimeter thresholds with a dynamic criterion: $\text{RainHoldTrigger} = \text{True}$ only if $P_{\text{forecast}} \ge (RAW - D_i) \times \gamma_{\text{confidence}}$.

---

## 4. Satellite Outage & Circuit Breaker Fallback Behavior

When external third-party satellite APIs experience service degradation or rate limiting, JalDrishti protects backend availability using circuit breakers and deterministic fallbacks:

### SoilGrids Fallback Profile
- **Circuit Breaker**: Trips for 15 minutes after 3 consecutive failures ([`soilgrids_service.py:141-143`](file:///d:/jaldrishti/jaldrishti-backend/app/services/soilgrids_service.py#L141-L143)).
- **Fallback Value**: Default Gangetic Alluvium profile ($30\%$ clay, $25\%$ sand, bulk density $1.35\text{ kg/dm}^3$, [`constants.py:57-62`](file:///d:/jaldrishti/jaldrishti-backend/app/core/constants.py#L57-L62)).
- **Operational Risk**: If a farm in the arid Deccan plateau (shallow red sandy soil) experiences a SoilGrids outage, it will temporarily calculate water balance using Indo-Gangetic clay-loam properties until the circuit breaker resets.

### Open-Meteo Fallback Telemetry
- **Circuit Breaker**: Stale-while-revalidate cache serves the last known good 3-hour forecast ([`weather_service.py:44-51`](file:///d:/jaldrishti/jaldrishti-backend/app/services/weather_service.py#L44-L51)).
- **Synthetic Default**: If no stale cache exists, fallback solar radiation defaults to $21.0\text{ MJ}\cdot\text{m}^{-2}\cdot\text{day}^{-1}$ ([`constants.py:46`](file:///d:/jaldrishti/jaldrishti-backend/app/core/constants.py#L46)).
- **Operational Risk**: Sustained multi-day meteorological API outages would halt real-time rainfall adjustments, requiring farmers to log irrigation events manually.

---

## 5. Single-Layer "Bucket" vs. Multi-Layer Unsaturated Flow

- **Single-Layer Simplification**: JalDrishti models the root zone as a single homogeneous depth compartment ($Z_r$). Water is assumed to distribute instantaneously throughout this layer.
- **Physical Reality**: Real unsaturated soil water movement follows the non-linear Richards equation, with distinct hydraulic conductivity gradients across surface crusting ($0\text{--}5\text{ cm}$), main root zones ($5\text{--}40\text{ cm}$), and sub-root horizons.
- **Agronomic Impact**: Surface evaporation immediately following light showers ($2\text{--}3\text{ mm}$) may dry out the top 3 cm before roots at 30 cm depth can absorb it. JalDrishti's effective rainfall factor ($0.80$) partially compensates for this, but cannot simulate layered wetting fronts.

---

## 6. Flat-Terrain Hydrology Assumption

- **Slope and Runoff**: The current mass balance model assumes an idealized flat field.
- **Physical Reality**: Terraced hillsides (e.g. tea plantations or hill maize) experience significant lateral surface runoff and ridge-furrow divergence.
- **Agronomic Impact**: Farmers cultivating steep terrain may experience faster surface drying than the flat-plane mass balance predicts.
