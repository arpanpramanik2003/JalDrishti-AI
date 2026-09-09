# Rain Hold and Economic ROI Formulas

> **Audience**: Agronomists, environmental economists, and backend engineers. For a non-mathematical summary, see [Rain Hold and Savings Explained](../01-concepts-and-workflows/rain-hold-and-savings-explained.md).  
> **Source Implementation**: [`app/api/v1/endpoints/irrigation.py:460-555`](file:///d:/jaldrishti/jaldrishti-backend/app/api/v1/endpoints/irrigation.py#L460-L555)  
> **Centralized Thresholds & Constants**: [`app/core/constants.py:86-129`](file:///d:/jaldrishti/jaldrishti-backend/app/core/constants.py#L86-L129)  
> **Regional Tariffs**: [`app/services/regional_tariff_service.py`](file:///d:/jaldrishti/jaldrishti-backend/app/services/regional_tariff_service.py) & [`app/models/regional_tariff.py`](file:///d:/jaldrishti/jaldrishti-backend/app/models/regional_tariff.py)

---

## 1. Smart Rain Hold Evaluation Logic

When soil moisture depletion reaches or exceeds the Readily Available Water threshold ($D_i \ge RAW$), irrigation is nominally required. Before issuing a "Water Now" advisory, the engine evaluates upcoming precipitation telemetry from Open-Meteo across three distinct temporal windows:

```
                  +------------------------------------------+
                  | Does soil need water? (D_i >= RAW)       |
                  +--------------------+---------------------+
                                       | YES
                                       v
                  +------------------------------------------+
                  | Evaluate Satellite Rainfall Telemetry:   |
                  | 1. Next 24h precipitation >= 3.0 mm OR   |
                  | 2. Next 48h precipitation >= 5.0 mm OR   |
                  | 3. Today's recorded precip >= 4.0 mm     |
                  +--------------------+---------------------+
                                       |
                   +-------------------+-------------------+
                   | YES                                   | NO
                   v                                       v
      +-------------------------+             +-------------------------+
      | SMART RAIN HOLD ACTIVE  |             | ADVISE IRRIGATION NOW   |
      | - Suppress pump run     |             | - Recommend water depth |
      | - Credit avoided run    |             | - Calculate pump hours  |
      +-------------------------+             +-------------------------+
```

### Trigger Conditions & Thresholds
Defined in [`app/core/constants.py:86-98`](file:///d:/jaldrishti/jaldrishti-backend/app/core/constants.py#L86-L98) and evaluated in [`irrigation.py:497-500`](file:///d:/jaldrishti/jaldrishti-backend/app/api/v1/endpoints/irrigation.py#L497-L500):

$$\text{rain\_hold\_active} = \begin{cases} 
\text{True} & \text{if } P_{24\text{h}} \ge 3.0\text{ mm} \\ 
\text{True} & \text{if } P_{48\text{h}} \ge 5.0\text{ mm} \\ 
\text{True} & \text{if } P_{\text{today}} \ge 4.0\text{ mm} \\ 
\text{False} & \text{otherwise} 
\end{cases}$$

### Operational Override Actions
If $\text{rain\_hold\_active}$ is `True` and $D_i \ge RAW$ (`needs_irrigation_would_have_been_true`):
1. `needs_irrigation_today` is overridden to `False`.
2. `status_summary` transitions to `"RAIN_HOLD"`.
3. Avoided pumping time and cost savings are computed for the day.
4. If soil moisture is already fine ($D_i < RAW$), the system flags a passive `"RAIN_ADVISORY"` note rather than claiming an active cost saving.

---

## 2. Avoided Pumping & Single-Session Savings Derivation

When Rain Hold intervenes to cancel an otherwise necessary irrigation event, avoided pump runtime is derived from the gross water volume required ([`irrigation.py:453-458, 504-505`](file:///d:/jaldrishti/jaldrishti-backend/app/api/v1/endpoints/irrigation.py#L453-L458)):

### Step 1: Gross Irrigation Depth ($d_{\text{gross}}$)
Accounts for application inefficiencies based on irrigation hardware (FAO-56 Chapter 8):

$$d_{\text{gross}} = \frac{D_i}{\eta_{\text{irrigation}}}$$

Where application efficiency $\eta_{\text{irrigation}}$ is:
- **Drip**: $90\%$ ($\eta = 0.90$)
- **Sprinkler**: $75\%$ ($\eta = 0.75$)
- **Flood / Furrow**: $50\%$ ($\eta = 0.50$)

### Step 2: Avoided Pumping Hours ($H_{\text{saved}}$)
$$V_{\text{liters}} = d_{\text{gross}} \times A_{\text{sqm}} \times 1.0\frac{\text{L}}{\text{m}^2\cdot\text{mm}}$$

$$T_{\text{seconds}} = \frac{V_{\text{liters}}}{Q_{\text{pump}}}$$

Where:
- $A_{\text{sqm}} = \text{area\_acres} \times 4046.86\frac{\text{m}^2}{\text{acre}}$ ([`constants.py:67`](file:///d:/jaldrishti/jaldrishti-backend/app/core/constants.py#L67))
- $Q_{\text{pump}}$: Pump flow rate in Liters per second (default $5.0\text{ L/s}$, [`constants.py:126`](file:///d:/jaldrishti/jaldrishti-backend/app/core/constants.py#L126))

To avoid zero-credit anomalies in early crop stages where gross volume is small, avoided runtime is clamped to a minimum benchmark (`MINIMUM_HOURS_SAVED_RAIN_HOLD = 1.5\text{ h}`, [`constants.py:97`](file:///d:/jaldrishti/jaldrishti-backend/app/core/constants.py#L97)):

$$H_{\text{saved}} = \max\left( \frac{T_{\text{seconds}}}{3600}, 1.5 \right)$$

### Step 3: Single-Session Cost Savings ($\text{INR}_{\text{saved}}$)
$$\text{INR}_{\text{saved}} = \text{round}(H_{\text{saved}} \times \text{Tariff}_{\text{energy}}, 0)$$

Where $\text{Tariff}_{\text{energy}}$ is loaded from `RegionalTariffService` (or fallback defaults in [`constants.py:105-108`](file:///d:/jaldrishti/jaldrishti-backend/app/core/constants.py#L105-L108)):
- Subsidized Agricultural Electricity: ₹$25\text{--}80/\text{hour}$ (default ₹$80.0/\text{hr}$)
- Agricultural Diesel Fuel: ₹$80\text{--}145/\text{hour}$ (default ₹$145.0/\text{hr}$)

---

## 3. Cumulative Seasonal ROI & Skipped Runs Accounting

In Phase 1 ([`PHASE1_CHANGELOG.md`](file:///d:/jaldrishti/PHASE1_CHANGELOG.md)), the cumulative ROI tracker was completely overhauled to remove artificial hardcoded offsets (`+3` and `+4` run inflations found during the audit).

### Idempotent Counter Incrementing
Implemented in [`irrigation.py:519-528`](file:///d:/jaldrishti/jaldrishti-backend/app/api/v1/endpoints/irrigation.py#L519-L528):
1. `skipped_runs_count` increments if and only if:
   - `rain_hold_active == True` **AND**
   - `needs_irrigation_would_have_been_true == True` **AND**
   - `depletion_record.last_rain_hold_date != today_obj` (date-gated idempotency)
2. When incremented, `last_rain_hold_date` is updated to today's date. Subsequent requests on the same calendar day leave `skipped_runs_count` unchanged.

### Cumulative Formulas (When $\text{session\_count} > 0$)
Implemented in [`irrigation.py:532-545`](file:///d:/jaldrishti/jaldrishti-backend/app/api/v1/endpoints/irrigation.py#L532-L545):

1. **Water Saved per Session Depth ($d_{\text{saved}}$)**:
   Accounts for the $45\%$ baseline water wastage inherent to traditional unmetered flood irrigation (`TRADITIONAL_FLOOD_WASTE_FRACTION = 0.45`, [`constants.py:117`](file:///d:/jaldrishti/jaldrishti-backend/app/core/constants.py#L117)):
   $$d_{\text{saved}} = \max\left( 4.0\text{ mm}, d_{\text{gross}} \times 0.45 \right)$$
   *(If $d_{\text{gross}} = 0$, defaults to fallback $12.0\text{ mm}$, [`constants.py:123`](file:///d:/jaldrishti/jaldrishti-backend/app/core/constants.py#L123)).*

2. **Cumulative Water Volume Saved ($V_{\text{cum}}$)**:
   $$V_{\text{cum}} = d_{\text{saved}} \times A_{\text{sqm}} \times \text{skipped\_runs\_count} \quad [\text{Liters}]$$

3. **Cumulative Avoided Pump Hours ($H_{\text{cum}}$)**:
   $$H_{\text{cum}} = \frac{V_{\text{cum}}}{Q_{\text{pump}} \times 3600} \quad [\text{hours}]$$

4. **Cumulative Money Saved ($\text{Cost}_{\text{cum}}$)**:
   $$\text{Cost}_{\text{cum}} = (H_{\text{cum}} \times \text{Tariff}_{\text{energy}}) + \text{INR}_{\text{today\_if\_active}} \quad [\text{INR}]$$

5. **Cumulative Avoided Carbon Emissions ($CO_{2, \text{cum}}$)**:
   $$CO_{2, \text{cum}} = H_{\text{cum}} \times \text{EmissionFactor}_{\text{energy}} \quad [\text{kg } CO_2]$$
   - Electric pump grid emission factor: $0.72\text{--}2.68\text{ kg } CO_2/\text{hr}$ (CEA India Baseline Database v19, [`constants.py:111`](file:///d:/jaldrishti/jaldrishti-backend/app/core/constants.py#L111))
   - Diesel pump emission factor: $2.68\text{--}3.42\text{ kg } CO_2/\text{hr}$ ([`constants.py:114`](file:///d:/jaldrishti/jaldrishti-backend/app/core/constants.py#L114))

---

## 4. Calm Zero-State Validation

When a plot is newly registered or has had no Rain Hold events ($\text{session\_count} = 0$), the backend returns an exact zero-state ([`irrigation.py:546-554`](file:///d:/jaldrishti/jaldrishti-backend/app/api/v1/endpoints/irrigation.py#L546-L554)):

```json
{
  "cumulative_savings": {
    "total_water_saved_liters": 0.0,
    "total_money_saved_inr": 0.0,
    "total_co2_avoided_kg": 0.0,
    "skipped_sessions_count": 0
  }
}
```

No speculative numbers or unearned savings are displayed.
