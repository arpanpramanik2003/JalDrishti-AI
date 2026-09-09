# Crop Coefficients and Phenological Growth Stages

> **Audience**: Agronomists, hydrological modelers, and software developers. For a non-mathematical summary, see [How JalDrishti Decides When to Water](../01-concepts-and-workflows/how-jaldrishti-decides-when-to-water.md).  
> **Source Implementation**: [`app/engine/water_bucket_model.py:19-132`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/water_bucket_model.py#L19-L132)  
> **Crop Phenology Configuration**: `app/data/crop_coefficients.json`  
> **Constants**: [`app/core/constants.py:70-82`](file:///d:/jaldrishti/jaldrishti-backend/app/core/constants.py#L70-L82)  
> **Primary Authority**: FAO Irrigation and Drainage Paper No. 56, Chapter 6 (*ETc - Single Crop Coefficient*).

---

## 1. The Crop Evapotranspiration Relationship

Crop water demand ($ET_c$, in $\text{mm}\cdot\text{day}^{-1}$) varies across the growing season as the crop establishes foliage, flowers, and matures. Under standard non-stress conditions, it is calculated as (FAO-56 Eq. 56):

$$ET_c(t) = K_c(t) \times ET_o(t)$$

Where:
- $ET_o(t)$: Reference evapotranspiration calculated via FAO-56 Penman-Monteith
- $K_c(t)$: Dynamic single crop coefficient on day $t$ of the growing season

---

## 2. Four-Stage Phenological Interpolation

JalDrishti implements the continuous four-stage FAO-56 crop growth curve based on farmer-provided sowing date ($t_0$) and days elapsed ($t = \text{today} - t_0$):

```
       Kc ^
          |                 Mid-Season (Peak Kc)
  Kc_mid -+                   +---------------+
          |                  /                 \   Late-Season Linear Decay
          |                 /                   \  (FAO-56 Eq. 66)
          |   Crop Dev     /                     \
  Kc_ini -+  +------------+                       +-------- Kc_end
          |  |  Initial   |                       |
          +--+------------+-----------------------+------------->
             0          L_ini     L_dev         L_mid    L_late   Time (days)
```

The four stages are parameterized by duration ($L_i$ in days) and coefficient ($K_{c,i}$):
1. **Initial Stage ($L_{\text{ini}}$)**: Sowing, germination, and early ground cover ($< 10\%$).
2. **Crop Development ($L_{\text{dev}}$)**: Rapid vegetative growth, leaf area expansion, ground cover reaching $70\text{--}80\%$.
3. **Mid-Season ($L_{\text{mid}}$)**: Flowering, grain/fruit fill, maximum canopy density.
4. **Late-Season ($L_{\text{late}}$)**: Ripening, leaf senescence, and dry-down until harvest.

### Stage 1: Initial ($0 \le t \le L_{\text{ini}}$)
$K_c$ remains constant at the baseline initial value ([`water_bucket_model.py:89-93`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/water_bucket_model.py#L89-L93)):

$$K_c(t) = K_{c,\text{ini}}$$

### Stage 2: Crop Development ($L_{\text{ini}} < t \le L_{\text{ini}} + L_{\text{dev}}$)
$K_c$ increases linearly as vegetative canopy expands (FAO-56 Eq. 66, [`water_bucket_model.py:95-102`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/water_bucket_model.py#L95-L102)):

$$\text{progress}(t) = \frac{t - L_{\text{ini}}}{L_{\text{dev}}}$$

$$K_c(t) = K_{c,\text{ini}} + \text{progress}(t) \times (K_{c,\text{mid}} - K_{c,\text{ini}})$$

### Stage 3: Mid-Season ($L_{\text{ini}} + L_{\text{dev}} < t \le L_{\text{ini}} + L_{\text{dev}} + L_{\text{mid}}$)
$K_c$ holds constant at peak transpiration demand ([`water_bucket_model.py:104-108`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/water_bucket_model.py#L104-L108)):

$$K_c(t) = K_{c,\text{mid}}$$

### Stage 4: Late-Season Linear Decay (Phase 1 Fix)
In legacy versions of the backend, the late-season stage improperly snapped to a static hardcoded $0.75$ regardless of crop species. In Phase 1 ([`PHASE1_CHANGELOG.md`](file:///d:/jaldrishti/PHASE1_CHANGELOG.md)), this was corrected to the true FAO-56 continuous linear decay formulation ([`water_bucket_model.py:110-118`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/water_bucket_model.py#L110-L118)):

$$\text{progress}_{\text{late}}(t) = \frac{t - (L_{\text{ini}} + L_{\text{dev}} + L_{\text{mid}})}{L_{\text{late}}}$$

$$K_c(t) = K_{c,\text{mid}} + \text{progress}_{\text{late}}(t) \times (K_{c,\text{end}} - K_{c,\text{mid}})$$

---

## 3. Dynamic Root Zone Expansion ($Z_r(t)$)

Root depth directly dictates Total Available Water ($TAW$). Rather than assuming a static full-season root depth, JalDrishti dynamically expands effective root depth from initial seedling emergence to full vegetative maturity ([`water_bucket_model.py:92-101`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/water_bucket_model.py#L92-L101)):

Constants defined in [`app/core/constants.py:78-80`](file:///d:/jaldrishti/jaldrishti-backend/app/core/constants.py#L78-L80):
- `INITIAL_ROOT_DEPTH_FRACTION = 0.30`
- `MINIMUM_EFFECTIVE_ROOT_DEPTH_M = 0.15`

### Formulations:
- **Initial Stage**:
  $$Z_r(t) = \max(0.15, Z_{r,\text{max}} \times 0.30)$$
- **Development Stage**:
  $$Z_r(t) = Z_{r,\text{max}} \left[ 0.30 + (1.0 - 0.30) \times \text{progress}(t) \right]$$
- **Mid & Late Stages**:
  $$Z_r(t) = Z_{r,\text{max}}$$

---

## 4. Boundary State Mechanics (Phase 1 Fixes)

Real-world agricultural usage introduces edge conditions that cause uncapped runaway loops if unhandled. Phase 1 introduced explicit boundary state validation in [`water_bucket_model.py:60-86`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/water_bucket_model.py#L60-L86):

### 1. Future Sowing Date (`crop_status = "NOT_YET_SOWN"`)
- **Trigger**: Sowing date entered by farmer is in the future ($t < 0$).
- **Behavior**:
  - `dynamic_kc = 0.0`
  - `effective_root_depth_m = 0.0`
  - `needs_irrigation_today = False`
  - `status_message`: Informs farmer how many days remain until scheduled planting.
  - Zero irrigation run recommended.

### 2. Post-Harvest Runaway Tolerance (`crop_status = "HARVEST_OVERDUE"`)
- **Trigger**: Days elapsed exceed cumulative lifecycle $L_{\text{total}} = L_{\text{ini}} + L_{\text{dev}} + L_{\text{mid}} + L_{\text{late}}$ plus a 15-day grace tolerance (`POST_HARVEST_MAX_OVERDUE_DAYS = 15`, [`constants.py:76`](file:///d:/jaldrishti/jaldrishti-backend/app/core/constants.py#L76)).
- **Behavior**:
  - `dynamic_kc = 0.0`
  - Active irrigation advisories are halted immediately.
  - `status_message`: Informs farmer that the crop lifecycle is finished and prompts plot deregistration or re-sowing.
- **Grace Period**: Between day $L_{\text{total}}$ and $L_{\text{total}} + 15$, status is `"Maturity Reached (Awaiting Harvest)"` with $K_c = K_{c,\text{end}}$ to support late pre-harvest soil moisture maintenance.
