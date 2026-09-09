# How JalDrishti Decides When to Water

The core of JalDrishti is its decision engine. Rather than relying on static calendar rules or guesswork, the system maintains a **continuous, dynamic simulation** of the water present in the crop root zone every single day.

---

## 🪣 The Mental Model: The "Soil Water Bucket"

To understand how the engine works, picture the soil beneath a crop field as a **bucket**:

```text
┌────────────────────────────────────────────────────────┐
│               THE ROOT ZONE SOIL BUCKET                │
└────────────────────────────────────────────────────────┘

  ▲  =========================================== [FULL: Field Capacity]
  │  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  │  ░░░░░░░░░ READILY AVAILABLE WATER ░░░░░░░░ [COMFORT ZONE]
  │  ░░░░░░░░░░░░░░░ (RAW) ░░░░░░░░░░░░░░░░░░░
  │  - - - - - - - - - - - - - - - - - - - - - - [CRITICAL TRIGGER LINE]
  │  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
  │  ▒▒▒▒▒ DIFFICULT TO EXTRACT WATER ▒▒▒▒▒▒▒▒▒ [STRESS ZONE]
  │  ▒▒▒▒▒▒▒▒ (Plant expends energy to suck) ▒▒▒
  ▼  =========================================== [EMPTY: Permanent Wilting Point]
```

1. **Bucket Depth (Root Zone Depth)**: The size of the bucket is determined by the plant's roots. When seeds are planted, roots are only 10 to 15 cm deep, creating a tiny bucket that empties quickly. As the plant matures into full vegetative growth, roots penetrate 60 to 100 cm deep, expanding the bucket significantly.
2. **Bucket Capacity (Soil Texture)**: The material of the soil dictates how much water can be stored:
   - **Clay soils**: Very fine particles that hold water tightly like a sponge (large capacity).
   - **Sandy soils**: Coarse grains that drain rapidly (small capacity).
3. **Field Capacity (The Rim of the Bucket)**: When rain or irrigation saturates the field, gravity pulls away excess water within 24 hours. The water that remains clinging to soil particles is at **Field Capacity**. If you pour more water in, it simply overflows into deep drainage.
4. **Permanent Wilting Point (The Bottom of the Bucket)**: If no water is added, soil dries out until plant roots can no longer exert enough suction to pull moisture out. At this point, the plant wilts permanently and dies.
5. **Readily Available Water (RAW - The Safe Comfort Zone)**: Crops do not like working hard for water. When the bucket is between 100% full and roughly 50% full (the exact percentage depends on the crop), roots absorb water effortlessly with zero stress. Once water drops below the **Critical Trigger Line**, the crop begins to suffer water stress, stunting growth and reducing grain yield.

---

## 📈 Persistent Day-to-Day Accounting (The Phase 1 Fix)

A major flaw identified during the technical audit of the original codebase was that the engine previously wiped its memory every 3 days, resetting the soil depletion balance to an arbitrary starting point.

**Today, the engine tracks persistent day-to-day depletion across the entire season**:
- **Every Morning at Sunrise**: The engine takes yesterday evening's soil water balance.
- **Water Going Out (Atmospheric Demand)**: Satellite solar radiation, temperature, humidity, and wind calculate how many millimeters the crop transpired ($ET_c$). This amount is subtracted from the bucket.
- **Water Coming In (Rain & Pumping)**: Any rainfall detected by satellite ($P$) or any pump runs logged by the farmer ($I_{net}$) are added back into the bucket.
- **Overflow Protection**: If heavy rain exceeds the bucket's capacity, the excess is capped at zero depletion (runoff / deep percolation); it does not create a fictitious "infinitely full" bucket.

---

## 🚦 What Triggers a Recommendation?

When the farmer opens the app, the engine evaluates the current balance against strict operational thresholds:

### 1. "Soil Moisture is Fine" (Green Status)
- **Condition**: Root zone depletion is within the safe comfort zone ($D_r \le \text{RAW}$).
- **Action**: No irrigation is needed. The app tells the farmer: *"Soil moisture is healthy. Next irrigation estimated in 3 days."*

### 2. "Water Now" (Amber / Urgent Alert)
- **Condition**: Water has dropped past the critical trigger line ($D_r > \text{RAW}$), meaning the plant has entered the stress zone.
- **Action**: The engine calculates the exact millimeter deficit required to refill the bucket back to Field Capacity. It then converts this millimeter depth into an **exact pump runtime** (e.g., *1 hour and 35 minutes*) based on the farmer's plot area and pump horsepower.

### 3. "Hold Off: Rain Expected" (Smart Rain Hold Alert)
- **Condition**: Even if the soil bucket is low and needs water, the satellite weather forecast detects significant upcoming rain (**$\ge 5\text{ mm}$ within 48 hours**).
- **Action**: The system overrides the "Water Now" alert and advises the farmer to hold off: *"Hold your pump: ~14 mm rain forecast tomorrow. Let rainfall refill your soil bucket for free."*

### 4. Boundary States: "Not Yet Sown" & "Harvest Completed"
- **Not Sown**: If the current date is prior to the farmer's recorded sowing date, the engine displays a preparatory nursery/soil status and does not calculate crop transpiration.
- **Harvest Completed**: Once the calendar passes the crop's standard maturity duration (e.g., 125 days for Paddy or 95 days for Potato), the engine automatically closes the seasonal balance, displays a final summary of seasonal water applied, and stops triggering irrigation alerts.

---

## 🛠️ For Technical Readers

The concepts above are implemented directly in the following backend engine modules:
- **Persistent Balance Iteration**: Handled in `calculate_daily_depletion_sequence()` in [`app/engine/water_bucket_model.py`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/water_bucket_model.py).
- **Penman-Monteith Reference Evapotranspiration ($ET_0$)**: Equations [1], [6], [11], and [12] implemented in [`app/engine/penman_monteith.py`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/penman_monteith.py).
- **Crop Stages & Root Zone Depth ($Z_r$)**: Standard FAO-56 stage timelines and $K_c$ coefficients loaded from [`app/engine/crop_coefficients.py`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/crop_coefficients.py).
- **Endpoint Orchestration**: Coordinated asynchronously inside `get_irrigation_recommendation()` in [`app/api/v1/endpoints/irrigation.py`](file:///d:/jaldrishti/jaldrishti-backend/app/api/v1/endpoints/irrigation.py).
