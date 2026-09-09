# The Irrigation Problem

Across the agricultural heartlands of India, irrigation is the single most important factor determining whether a farming family turns a profit or falls into debt. Yet, the traditional methods used to water crops remain largely unchanged from decades ago.

---

## 🛑 The Three Core Failures of Traditional Irrigation

Traditional irrigation practices suffer from three interrelated breakdowns: **technological mismatch**, **habitual over-pumping**, and **weather unpredictability**.

```text
       ┌─────────────────────────────────────────────────────────┐
       │             TRADITIONAL IRRIGATION CYCLE                │
       └─────────────────────────────────────────────────────────┘
                                   │
              ┌────────────────────┴────────────────────┐
              ▼                                         ▼
   1. FLOOD IRRIGATION                       2. FIXED CALENDAR ROUTINE
   - Floods topsoil                          - "Every 4 days for 6 hours"
   - 40-60% lost to deep drainage            - Ignores actual soil moisture
   - Leaches nitrogen fertilizers            - Drains farmer cash reserves
              │                                         │
              └────────────────────┬────────────────────┘
                                   │
                                   ▼
                      3. MONSOON DISRUPTION
                      - Farmer pumps on Tuesday
                      - 25mm rain falls on Wednesday
                      - Root rot, waterlogging, wasted fuel
```

---

### 1. Flood Irrigation & The Surface Moisture Illusion

Over 90% of Indian tube-well farms use **surface flood irrigation** (furrows or basin flooding). While simple and requiring no pressurized piping, flood irrigation suffers from fundamental inefficiencies:
- **Massive Infiltration Losses**: In sandy or loam soils, 40% to 60% of pumped water sinks rapidly past the active root zone into deep subsoil layers where crop roots cannot reach it.
- **Nutrient Leaching**: Excess water dissolves and carries expensive urea and DAP fertilizers deep into the groundwater table, depriving the crop of nutrients and polluting rural aquifers.
- **The Cracked Soil Trap**: Under strong tropical sun and wind, the top 2–3 centimeters of soil dry into hard, cracked crusts within 24 hours of watering. Seeing this dry surface, farmers assume the field is parched. In reality, the crop's active roots—situated between 15 cm and 60 cm below the surface—are often surrounded by ample moisture. Pumping water onto an already moist subsoil causes **root asphyxiation** (oxygen starvation) and fungal diseases.

---

### 2. Fixed Calendar Schedules & Energy Tariffs

Because farmers lack real-time soil feedback, they fall back on rigid calendar rules of thumb:
- *"Wheat must be watered every 15 days."*
- *"Paddy nurseries must be flooded for 6 hours twice a week."*

These fixed schedules ignore weather reality. On a cool, cloudy week with 85% humidity, a crop loses less than **2 mm of water per day**. On a scorching, dry pre-monsoon week with 42°C heat and hot winds, the same crop loses **7 to 9 mm per day**.

Applying the same fixed pump duration in both scenarios results in severe over-irrigation during cool spells and severe crop stress during heatwaves. Furthermore, running a 5-horsepower or 7.5-horsepower diesel or electric pump costs money with every minute of operation:
- **Diesel Pumps**: Burning 1.2 to 1.8 liters of diesel per hour costs ₹110–₹165 per hour. A 6-hour unnecessary pump run wastes nearly ₹1,000 in cash.
- **Electric Pumps**: In states with metered agricultural tariffs or flat-rate quotas, over-pumping burns through subsidized quotas early in the season, leaving farmers exposed to high commercial rates during peak harvest.

---

### 3. Monsoon Unpredictability & "Pumping Before the Rain"

The Indian monsoon is notoriously erratic. A dry spell of 10 days often tempts farmers to run their pumps to save wilting crops. Frequently, the farmer finishes an 8-hour irrigation cycle on a Tuesday evening, only for a convective storm to dump 30 mm of rain on Wednesday morning.

The consequences are catastrophic:
- The entire expenditure on diesel or electricity was completely wasted.
- The field becomes severely waterlogged, increasing the risk of diseases like **Sheath Blight in Paddy** or **Late Blight in Potato**.
- Valuable topsoil and newly applied fertilizers wash off the field into drainage ditches.

---

## 💡 The Solution: Dynamic, Data-Driven Water Accounting

Solving this crisis does not require multi-lakh rupee drip systems or fragile field sensors. It requires **accurate, daily water accounting**:
1. Knowing the exact water-holding capacity of the farmer's specific soil texture.
2. Calculating the exact millimeter loss to the atmosphere every 24 hours based on local solar radiation, wind, and temperature.
3. Checking real-time satellite forecasts to anticipate upcoming rain *before* the pump switch is flipped.
4. Translating these calculations into simple, actionable runtimes in the farmer's native language.

---

## 🛠️ For Technical Readers

The problem described above is formalized in JalDrishti's core hydrology services:
- **Crop Water Consumption ($ET_c$)**: Computed using the FAO-56 dual crop coefficient methodology in [`app/engine/penman_monteith.py`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/penman_monteith.py).
- **Soil Water Retention Bounds (FC, WP, RAW)**: Modeled from sand/clay ratios in [`app/engine/water_bucket_model.py`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/water_bucket_model.py).
- **Tariff & Energy Optimization**: Translates water depth into pump runtimes and financial costs across state tariffs in [`app/services/regional_tariff_service.py`](file:///d:/jaldrishti/jaldrishti-backend/app/services/regional_tariff_service.py).
