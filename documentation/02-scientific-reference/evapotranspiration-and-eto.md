# Evapotranspiration and Reference ETo Calculation

> **Audience**: Hydrologists, software engineers, and agronomists. For a non-mathematical summary, see [How JalDrishti Decides When to Water](../01-concepts-and-workflows/how-jaldrishti-decides-when-to-water.md).  
> **Source Implementation**: [`app/engine/penman_monteith.py`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/penman_monteith.py)  
> **Centralized Constants**: [`app/core/constants.py`](file:///d:/jaldrishti/jaldrishti-backend/app/core/constants.py#L17-L48)  
> **Primary Authority**: Food and Agriculture Organization Irrigation and Drainage Paper No. 56 (*FAO-56*, Allen et al., 1998).

---

## 1. Mathematical Formulation

JalDrishti implements the standardized FAO-56 Penman-Monteith equation to determine the daily Reference Evapotranspiration ($ET_o$, expressed in $\text{mm}\cdot\text{day}^{-1}$) from a hypothetical grass reference surface having an assumed crop height of $0.12\text{ m}$, a surface canopy resistance of $70\text{ s}\cdot\text{m}^{-1}$, and an albedo of $0.23$.

The governing equation (FAO-56 Eq. 6, [`penman_monteith.py:134-138`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/penman_monteith.py#L134-L138)) is:

$$ET_o = \frac{0.408 \Delta (R_n - G) + \gamma \frac{900}{T_{\text{mean}} + 273} u_2 (e_s - e_a)}{\Delta + \gamma (1 + 0.34 u_2)}$$

Where:
- $ET_o$: Reference evapotranspiration [$\text{mm}\cdot\text{day}^{-1}$]
- $R_n$: Net radiation at the crop surface [$\text{MJ}\cdot\text{m}^{-2}\cdot\text{day}^{-1}$]
- $G$: Soil heat flux density [$\text{MJ}\cdot\text{m}^{-2}\cdot\text{day}^{-1}$]
- $T_{\text{mean}}$: Mean daily air temperature at 2 m height [$^\circ\text{C}$]
- $u_2$: Wind speed measured or converted to 2 m height [$\text{m}\cdot\text{s}^{-1}$]
- $e_s$: Saturation vapor pressure [$\text{kPa}$]
- $e_a$: Actual vapor pressure [$\text{kPa}$]
- $e_s - e_a$: Vapor pressure deficit (VPD) [$\text{kPa}$]
- $\Delta$: Slope of saturation vapor pressure curve [$\text{kPa}\cdot{^\circ\text{C}}^{-1}$]
- $\gamma$: Psychrometric constant [$\text{kPa}\cdot{^\circ\text{C}}^{-1}$]

---

## 2. Step-by-Step Derivation as Implemented in Code

### Step 1: Mean Temperature ($T_{\text{mean}}$)
Calculated as the arithmetic mean of daily maximum and minimum air temperature (FAO-56 Eq. 9, [`penman_monteith.py:87`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/penman_monteith.py#L87)):

$$T_{\text{mean}} = \frac{T_{\text{max}} + T_{\text{min}}}{2}$$

### Step 2: Atmospheric Pressure ($P$) and Psychrometric Constant ($\gamma$)
Atmospheric pressure is computed from farm terrain elevation above sea level $z$ (FAO-56 Eq. 7, [`penman_monteith.py:90`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/penman_monteith.py#L90)):

$$P = 101.3 \left( \frac{293 - 0.0065 z}{293} \right)^{5.26}$$

The psychrometric constant $\gamma$ is derived from atmospheric pressure (FAO-56 Eq. 8, [`penman_monteith.py:93`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/penman_monteith.py#L93), constant in [`constants.py:29-30`](file:///d:/jaldrishti/jaldrishti-backend/app/core/constants.py#L29-L30)):

$$\gamma = 0.000665 \times P$$

### Step 3: Slope of Saturation Vapor Pressure Curve ($\Delta$)
Calculated at mean air temperature $T_{\text{mean}}$ (FAO-56 Eq. 13, [`penman_monteith.py:96`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/penman_monteith.py#L96)):

$$\Delta = \frac{4098 \left[ 0.6108 \exp\left( \frac{17.27 T_{\text{mean}}}{T_{\text{mean}} + 237.3} \right) \right]}{(T_{\text{mean}} + 237.3)^2}$$

### Step 4: Saturation and Actual Vapor Pressures ($e_s, e_a$)
Saturation vapor pressure is evaluated separately at daily maximum and minimum temperatures and averaged (FAO-56 Eq. 11 & 12, [`penman_monteith.py:98-101`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/penman_monteith.py#L98-L101)):

$$e^\circ(T) = 0.6108 \exp\left( \frac{17.27 T}{T + 237.3} \right)$$

$$e_s = \frac{e^\circ(T_{\text{max}}) + e^\circ(T_{\text{min}})}{2}$$

Actual vapor pressure $e_a$ is derived from mean relative humidity $RH_{\text{mean}}$ (FAO-56 Eq. 17, [`penman_monteith.py:104`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/penman_monteith.py#L104)):

$$e_a = \frac{RH_{\text{mean}}}{100} \times e_s$$

### Step 5: Net Shortwave Radiation ($R_{ns}$)
Using the standard reference grass canopy albedo $\alpha = 0.23$ (FAO-56 Eq. 38, [`penman_monteith.py:106-107`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/penman_monteith.py#L106-L107), constants in [`constants.py:24-27`](file:///d:/jaldrishti/jaldrishti-backend/app/core/constants.py#L24-L27)):

$$R_{ns} = (1 - \alpha) R_s = 0.77 \times R_s$$

Where $R_s$ is daily downwelling shortwave solar radiation [$\text{MJ}\cdot\text{m}^{-2}\cdot\text{day}^{-1}$]. If satellite telemetry is unavailable, a regional default fallback of $21.0\text{ MJ}\cdot\text{m}^{-2}\cdot\text{day}^{-1}$ is used ([`constants.py:46`](file:///d:/jaldrishti/jaldrishti-backend/app/core/constants.py#L46)).

### Step 6: Extraterrestrial ($R_a$) & Clear-Sky Radiation ($R_{so}$)
Derived from day-of-year $J$ and latitude $\phi$ in radians (FAO-56 Eq. 21, 23, 24, 25 & Eq. 37, [`penman_monteith.py:110-117`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/penman_monteith.py#L110-L117)):

$$d_r = 1 + 0.033 \cos\left(\frac{2\pi}{365} J\right)$$

$$\delta = 0.409 \sin\left(\frac{2\pi}{365} J - 1.39\right)$$

$$\omega_s = \arccos(-\tan \phi \tan \delta)$$

$$R_a = \frac{24(60)}{\pi} G_{sc} d_r \left[ \omega_s \sin \phi \sin \delta + \cos \phi \cos \delta \sin \omega_s \right]$$

*(Solar constant $G_{sc} = 0.0820\text{ MJ}\cdot\text{m}^{-2}\cdot\text{min}^{-1}$)*

$$R_{so} = (0.75 + 2 \times 10^{-5} z) R_a$$

Relative solar radiation ratio $R_s / R_{so}$ is physically clamped to the range $[0.3, 1.0]$ per FAO-56 Eq. 39 ([`penman_monteith.py:120`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/penman_monteith.py#L120)).

### Step 7: Stefan-Boltzmann Net Longwave Radiation ($R_{nl}$)
Calculated using the full Stefan-Boltzmann formulation with vapor pressure and cloudiness factor weighting (FAO-56 Eq. 39, [`penman_monteith.py:122-126`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/penman_monteith.py#L122-L126), constant $\sigma = 4.903 \times 10^{-9}\text{ MJ}\cdot\text{K}^{-4}\cdot\text{m}^{-2}\cdot\text{day}^{-1}$ in [`constants.py:21`](file:///d:/jaldrishti/jaldrishti-backend/app/core/constants.py#L21)):

$$R_{nl} = \sigma \left( \frac{T_{\text{max, K}}^4 + T_{\text{min, K}}^4}{2} \right) (0.34 - 0.14 \sqrt{e_a}) \left( 1.35 \frac{R_s}{R_{so}} - 0.35 \right)$$

Net radiation $R_n$ is then (FAO-56 Eq. 40, [`penman_monteith.py:128`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/penman_monteith.py#L128)):

$$R_n = R_{ns} - R_{nl}$$

### Step 8: Soil Heat Flux Density ($G$)
For daily operational time steps, temperature fluctuations beneath a vegetative canopy average out, meaning $G \approx 0$ (FAO-56 Section 3, [`penman_monteith.py:130-131`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/penman_monteith.py#L130-L131), constant in [`constants.py:33`](file:///d:/jaldrishti/jaldrishti-backend/app/core/constants.py#L33)):

$$G = 0.0\text{ MJ}\cdot\text{m}^{-2}\cdot\text{day}^{-1}$$

---

## 3. Logarithmic Wind Speed Height Correction (Phase 1 Fix)

A crucial physical correction added in Phase 1 ([`PHASE1_CHANGELOG.md`](file:///d:/jaldrishti/PHASE1_CHANGELOG.md)) reconciles satellite anemometer heights with FAO-56 standards.

Meteorological services (including Open-Meteo) typically report wind speed at $10\text{ m}$ height ($u_{10}$). However, the FAO Penman-Monteith formulation strictly requires wind speed measured at $2\text{ m}$ height ($u_2$). Applying $10\text{ m}$ wind directly overestimates aerodynamic conductance by 25–35%, artificially inflating calculated water demand.

JalDrishti adjusts wind speed using the logarithmic wind profile formula (FAO-56 Eq. 47, [`penman_monteith.py:24-53`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/penman_monteith.py#L24-L53)):

$$u_2 = u_z \frac{4.87}{\ln(67.8 z - 5.42)}$$

For $z = 10.0\text{ m}$:

$$u_2 = u_{10} \frac{4.87}{\ln(67.8 \times 10.0 - 5.42)} = u_{10} \frac{4.87}{\ln(672.58)} = u_{10} \frac{4.87}{6.5111} \approx 0.748 \times u_{10}$$

If $z \le 2.0\text{ m}$, $u_2 = u_z$ without transformation ([`penman_monteith.py:44-45`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/penman_monteith.py#L44-L45)).

---

## 4. Documentation Drift Correction: Where Code Outperformed Old Docs

During the Phase 1 engineering audit, a notable discrepancy was discovered between legacy documentation and the actual backend code:

> [!NOTE]
> **Documentation Drift**: Legacy documentation in `docs/` claimed the backend used an oversimplified shortcut for net longwave radiation:
> 
> $$R_{nl, \text{old doc claim}} = 0.10 \times R_s$$
> 
> **Actual Code State**: The actual codebase implements the full, rigorous **Stefan-Boltzmann Net Longwave Radiation equation** (FAO-56 Eq. 39) with quartics of absolute temperatures ($T_K^4$), vapor pressure atmospheric emissivity adjustments ($0.34 - 0.14\sqrt{e_a}$), and cloudiness index weighting ($1.35 \frac{R_s}{R_{so}} - 0.35$).
> 
> The code was already substantially more scientifically rigorous than the old docs claimed. This document corrects the record to match the actual code.
