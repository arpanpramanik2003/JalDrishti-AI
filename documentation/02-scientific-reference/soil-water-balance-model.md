# Soil Water Balance and Root-Zone Depletion Model

> **Audience**: Hydrologists, irrigation engineers, and software architects. For a plain-language summary with physical analogies, see [How JalDrishti Decides When to Water](../01-concepts-and-workflows/how-jaldrishti-decides-when-to-water.md).  
> **Source Implementation**: [`app/engine/water_bucket_model.py:134-190`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/water_bucket_model.py#L134-L190)  
> **State Persistence Layer**: [`app/models/farm_plot.py:50-69`](file:///d:/jaldrishti/jaldrishti-backend/app/models/farm_plot.py#L50-L69)  
> **Routing Execution**: [`app/api/v1/endpoints/irrigation.py:258-375`](file:///d:/jaldrishti/jaldrishti-backend/app/api/v1/endpoints/irrigation.py#L258-L375)  
> **Pedotransfer Service**: [`app/services/soilgrids_service.py`](file:///d:/jaldrishti/jaldrishti-backend/app/services/soilgrids_service.py)  
> **Primary Authority**: FAO Irrigation and Drainage Paper No. 56, Chapter 8 (*Daily Soil Water Balance in the Root Zone*).

---

## 1. The Root-Zone Mass Balance Formulation

JalDrishti tracks root-zone soil water using the standardized FAO-56 daily depletion mass balance equation (FAO-56 Eq. 85, [`water_bucket_model.py:163-177`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/water_bucket_model.py#L163-L177)):

$$D_i = D_{i-1} - P_{\text{eff}, i} - I_{\text{applied}, i} + ET_{c, i}$$

Where:
- $D_i$: Cumulative root-zone soil water depletion at the end of day $i$ [$\text{mm}$]. Depletion represents the depth of water needed to bring soil moisture back up to Field Capacity ($\theta_{FC}$).
- $D_{i-1}$: Depletion carried over from the end of day $i-1$ [$\text{mm}$].
- $P_{\text{eff}, i}$: Effective rainfall infiltrating the root zone on day $i$ [$\text{mm}$].
- $I_{\text{applied}, i}$: Irrigation water applied directly to the plot on day $i$ [$\text{mm}$] as recorded in farmer logs.
- $ET_{c, i}$: Crop evapotranspiration loss on day $i$ [$\text{mm}$].

### Effective Precipitation ($P_{\text{eff}}$)
Precipitation does not infiltrate 100% into the root zone due to canopy interception, surface runoff, and rapid macro-pore bypass. JalDrishti applies a standard FAO-56 effective precipitation coefficient (FAO-56 Chapter 8, [`water_bucket_model.py:175`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/water_bucket_model.py#L175), constant in [`constants.py:55`](file:///d:/jaldrishti/jaldrishti-backend/app/core/constants.py#L55)):

$$P_{\text{eff}, i} = \min(P_i \times 0.80, P_i)$$

---

## 2. Soil Moisture Thresholds & Pedotransfer Functions

To determine whether water balance depletion triggers an irrigation event, soil physical moisture thresholds are derived from soil texture data (clay and sand fractions):

### Pedotransfer Equations (Saxton & Rawls / FAO-56 Chapter 8)
Implemented in [`water_bucket_model.py:135-151`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/water_bucket_model.py#L135-L151):

1. **Field Capacity ($\theta_{FC}$)**: Volumetric water content at $-33\text{ kPa}$ matric potential:
   $$\theta_{FC} = 0.10 + 0.0025 \times (\% \text{clay}) + 0.0005 \times (100 - \% \text{sand})$$

2. **Wilting Point ($\theta_{WP}$)**: Volumetric water content at $-1500\text{ kPa}$ matric potential:
   $$\theta_{WP} = 0.02 + 0.0020 \times (\% \text{clay})$$

3. **Total Available Water ($TAW$)**: Total depth of water retained in root depth $Z_r$ between Field Capacity and Permanent Wilting Point (FAO-56 Eq. 82):
   $$TAW = 1000 \times (\theta_{FC} - \theta_{WP}) \times Z_r$$
   *(Clamped to a minimum physical threshold of $10.0\text{ mm}$).*

4. **Readily Available Water ($RAW$)**: The fraction of $TAW$ a crop can extract without encountering stomatal closure or moisture stress (FAO-56 Eq. 83, [`water_bucket_model.py:174`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/water_bucket_model.py#L174)):
   $$RAW = p \times TAW$$
   Where $p$ is the crop-specific depletion fraction (typically $0.40\text{--}0.65$, loaded from `crop_coefficients.json`).

---

## 3. Physical Boundary Clamping

Physical soil cannot hold infinite moisture, nor can transpiration drain soil past permanent dryness without biological cessation. JalDrishti enforces strict physical clamping on daily depletion (FAO-56 Chapter 8, [`water_bucket_model.py:178`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/water_bucket_model.py#L178)):

$$0.0 \le D_i \le TAW$$

- **Lower Bound ($D_i < 0.0 \to D_i = 0.0$)**: If heavy rainfall or over-irrigation exceeds Field Capacity ($D_i < 0$), the surplus water is lost to surface runoff or deep percolation below the root zone within 24–48 hours. Soil moisture resets to Field Capacity ($D_i = 0.0\text{ mm}$).
- **Upper Bound ($D_i > TAW \to D_i = TAW$)**: If drought continues unabated, soil cannot dry past the Permanent Wilting Point ($D_i = TAW$). Beyond this point, plant stomata close and transpirational flux halts.

---

## 4. State Persistence: The Phase 1 Fix

### The Legacy Problem (3-Day Memory Wipe)
Prior to Phase 1 remediation, the backend re-initialized soil depletion to $0.0\text{ mm}$ every time weather was queried over a rolling 3-to-7 day window. If a farmer did not irrigate for 10 days, the engine continually forgot day 1–7 deficits, repeatedly reporting the soil as "fine" because only 3 days of evapotranspiration were counted.

### The Remediated Persistent Model
Phase 1 introduced the `SoilDepletionState` database model ([`farm_plot.py:50-69`](file:///d:/jaldrishti/jaldrishti-backend/app/models/farm_plot.py#L50-L69)):

| Database Column | Type | Purpose |
|:----------------|:-----|:--------|
| `farm_plot_id` | `Integer` (PK, FK) | One-to-one mapping to `farm_plots.id`. |
| `current_depletion_mm` | `Float` | Current cumulative depletion $D_i$ at end of today. |
| `yesterday_depletion_mm` | `Float` | Depletion $D_{i-1}$ from yesterday used as idempotent baseline. |
| `last_updated_date` | `Date` | Timestamp of the last successful mass balance run. |
| `skipped_runs_count` | `Integer` | Number of genuine Rain Hold override events accumulated. |
| `last_rain_hold_date` | `Date` (nullable) | Guards against duplicate incrementing within the same day. |

### Idempotency and Daily Execution
When `POST /api/v1/irrigation/recommendation` is invoked ([`irrigation.py:330-375`](file:///d:/jaldrishti/jaldrishti-backend/app/api/v1/endpoints/irrigation.py#L330-L375)):
1. If `last_updated_date < today`, the stored `current_depletion_mm` becomes today's baseline $D_{i-1}$.
2. If `last_updated_date == today` (multiple calls on the same day), the calculation reuses `yesterday_depletion_mm` as baseline $D_{i-1}$. This guarantees that repeated requests within the same day produce deterministic, idempotent results rather than compounding depletion repeatedly.
3. Today's mass balance runs: $D_i = D_{i-1} - P_{\text{eff}} - I_{\text{applied}} + ET_c$.
4. The resulting $D_i$ is committed back to `soil_depletion_state`.

### Pre-Migration Backfill Simulation
For plots registered before persistent tracking was enabled, the engine initializes depletion by simulating backward to the earlier of (sowing date, 7 days ago) starting from Field Capacity ($D = 0.0\text{ mm}$) and integrating forward day-by-day across real logged weather ([`irrigation.py:280-322`](file:///d:/jaldrishti/jaldrishti-backend/app/api/v1/endpoints/irrigation.py#L280-L322)). This prevents inventing synthetic history while ensuring realistic soil moisture state on first run.

---

## 5. SoilGrids Data Ingestion & Honest Resolution Notes

Soil texture parameters ($\% \text{clay}$, $\% \text{sand}$) are fetched asynchronously from the ISRIC SoilGrids v2.0 REST API ([`soilgrids_service.py:54-138`](file:///d:/jaldrishti/jaldrishti-backend/app/services/soilgrids_service.py#L54-L138)).

> [!IMPORTANT]
> **Spatial Precision Clarification**:
> - **Legacy Documentation Claim**: Old documentation claimed the system utilized SoilGrids at native "$250\text{ m}$ sub-plot hyper-resolution".
> - **Actual Implementation Reality**: To optimize external API rate limits, network latency, and cache hits across nearby plots, the backend coarsens coordinates to a $0.05^\circ$ binning factor ([`soilgrids_service.py:64-65`](file:///d:/jaldrishti/jaldrishti-backend/app/services/soilgrids_service.py#L64-L65)):
>   $$\text{grid\_lat} = \frac{\text{round}(\text{lat} \times 20)}{20}$$
>   $$\text{grid\_lon} = \frac{\text{round}(\text{lon} \times 20)}{20}$$
>   At the equator, $0.05^\circ \approx 5.5\text{ km} \times 5.5\text{ km}$. In the Indo-Gangetic Plains, this corresponds to approximately $5.5\text{ km} \times 5.1\text{ km}$.
> - **Cache Strategy**: Successful profile queries are cached in Redis with a **30-day TTL** ($2,592,000\text{ s}$, [`soilgrids_service.py:130`](file:///d:/jaldrishti/jaldrishti-backend/app/services/soilgrids_service.py#L130)), reflecting that mineral soil texture changes imperceptibly over agronomic seasons.
