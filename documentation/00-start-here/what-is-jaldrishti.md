# What is JalDrishti?

**JalDrishti** (from Sanskrit/Hindi: *Jal* = Water, *Drishti* = Vision / Insight) is an intelligent precision irrigation advisory and agronomy assistance system designed specifically for Indian smallholder farmers.

---

## 🌾 The Problem: Why Water Management is Broken

In India, over **80% of cultivated land** is farmed by smallholders holding plots smaller than 2 hectares (roughly 5 acres). When watering crops like paddy rice, wheat, potato, and maize, most farmers rely on **flood irrigation** powered by electric or diesel tube-well pumps.

Without tools to measure actual soil moisture, farmers face an impossible guessing game:
1. **Pumping on Fixed Calendar Habits**: Farmers often run pumps for 4 to 8 hours on a rigid routine (e.g., every Wednesday and Sunday), regardless of whether the soil actually needs water.
2. **Fear of Crop Stress**: In hot weather, the visible soil surface dries and cracks within hours, even when the plant roots 30 cm deep are sitting in plenty of moisture. Fearing yield loss, farmers pump unnecessarily.
3. **Wasted Energy and Tariffs**: Pumping water burns expensive diesel or racks up high rural electricity bills. In many states, running a 5-horsepower pump needlessly costs thousands of rupees each season.
4. **Rainfall Timing Surprises**: A farmer often spends hours pumping water into a field on Tuesday afternoon, only for a heavy monsoon downpour to flood the field on Wednesday morning, washing away expensive fertilizers and waterlogging crop roots.

---

## 🛰️ How JalDrishti Solves This — Without Costly Physical Sensors

Existing commercial "precision agriculture" solutions rely on **in-situ physical IoT soil sensors** (probes buried in the field with solar transmitters). While highly accurate for research institutions and large industrial estates in California or the Netherlands, IoT probes are **unviable for Indian smallholders**:
- Hardware costs ₹15,000–₹40,000 per plot.
- Tillage, tractors, and weeding operations regularly destroy buried cables and probes.
- Sensors require calibration, battery replacements, and reliable SIM connectivity.

### The JalDrishti Alternative: "Virtual" Satellite Precision

JalDrishti replaces physical field hardware with a **purely software-driven virtual hydrology engine**:

```text
┌───────────────────────┐       ┌────────────────────────┐
│  Open-Meteo Satellite │       │  ISRIC SoilGrids 250m  │
│  Weather Telemetry    │       │  Global Soil Database  │
└──────────┬────────────┘       └───────────┬────────────┘
           │                                │
           ▼                                ▼
   ┌─────────────────────────────────────────────────┐
   │        JalDrishti Virtual Hydrology Engine      │
   │  - FAO-56 Penman-Monteith Solar Evapotranspiration│
   │  - Day-to-day Persistent Water Bucket Balance   │
   │  - Dynamic Root Growth & Depletion Tracking     │
   └───────────────────────┬─────────────────────────┘
                           │
                           ▼
   ┌─────────────────────────────────────────────────┐
   │        Clear, Actionable Advice to Farmer       │
   │  "Soil is fine. Rain expected. Hold pump today."│
   └─────────────────────────────────────────────────┘
```

1. **Local Soil Texture**: When a farmer enters their plot location, JalDrishti queries global satellite data (ISRIC SoilGrids) to determine the exact sand, silt, and clay composition of their field soil. This tells the system how much water that specific soil type can hold before water drains away.
2. **Solar and Weather Telemetry**: JalDrishti pulls daily temperature, solar radiation, relative humidity, wind speed, and rainfall forecasts from Open-Meteo satellites.
3. **Daily Hydrology Accounting**: Using the internationally recognized **FAO-56 Penman-Monteith standard**, the system calculates exactly how many millimeters of water evaporated into the air and transpired through the crop leaves each day.
4. **Actionable Recommendations**: Instead of overwhelming the farmer with charts and millibar measurements, the app gives a single clear instruction:
   - *"Your soil has plenty of water. Do not pump today."*
   - *"Soil moisture is dipping low. Run your 5 HP pump for 1 hour 45 minutes today."*
   - *"Hold off: 14 mm of rain is forecast tomorrow. Let nature water your crop for free."*

---

## ⚖️ Our Honest Framing: Capabilities vs. Trade-Offs

We believe in radical engineering honesty. We do not claim JalDrishti has "IoT-probe-equivalent precision" or "99% laboratory accuracy." A software model running on satellite data has real trade-offs that every user and stakeholder should understand:

| Capability | Real-World Limitation / Trade-off |
|---|---|
| **Zero Hardware Cost**: The farmer needs only a smartphone; no equipment in the mud. | **Satellite Resolution**: Weather and soil data are modeled on 1 km to 250 m regional satellite grids. Micro-climates (such as a brief cloudburst over one specific village) may differ slightly from grid averages. |
| **Grounded Advisory**: Calculations use verified agronomy equations from the UN FAO and ICAR guidelines. | **Soil Compaction & Hardpans**: The model assumes standard soil horizons and cannot see subterranean hardpans or localized drainage blockages without soil testing. |
| **Smart Rain Hold**: Saves pump runs before predicted rain. | **Rain Probability**: Weather forecasts are probabilistic. If a predicted 10 mm rainfall dissipates, the engine detects this the following morning and immediately prompts the farmer to irrigate. |
| **JalSathi AI Companion**: Multilingual voice chat answering questions in Bengali, Hindi, and English. | **ICAR Scope**: The assistant only recommends agrochemicals and dosages explicitly verified in published Package of Practices documents. If an unverified chemical is asked about, it will refer the farmer to the local extension officer rather than guessing. |

---

## 🎯 What JalDrishti Does Today

Following the completion of system remediation (Phases 1–6):
- **Continuous Hydrology**: Persistent day-to-day soil bucket modeling that tracks cumulative moisture balances across the entire crop season.
- **Smart Rain Hold**: Automated hold-offs when significant rain (≥5 mm) is expected within 48 hours, preventing wasted pumping.
- **Real-Time Log Integration**: When a farmer logs a pump run (e.g. 2 hours), the engine instantly credits the exact volume of water to the soil balance and recalculates runtime recommendations.
- **Precision ROI Tracking**: Transparent reporting of estimated water liters saved, diesel/electricity costs avoided, and CO₂ footprint reduced.
- **Grounded AI Companion (JalSathi AI)**: Voice-enabled RAG assistant powered by Groq, providing answers in native Bengali (বাংলা), Hindi (हिंदी), and English with automatic fallback safeguards.
