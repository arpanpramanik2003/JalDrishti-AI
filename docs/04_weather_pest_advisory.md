# 🐛 Weather-Based Pest & Disease Early Warning Engine

## 📖 1. Overview & Agronomic Importance

Fungal spores, bacterial blights, and insect larvae proliferate under precise microclimatic windows of ambient temperature, relative humidity ($\mathrm{RH}$), and leaf surface wetness. Traditionally, Indian farmers detect pest infestations only after visual damage appears (such as leaf blast lesions or whorl feeding holes), when crop yield loss is already irreversible.

The **Weather-Based Pest & Disease Early Warning Engine** in JalDrishti continuously evaluates real-time Open-Meteo satellite weather telemetry against agricultural university epidemiology models (ICAR / SAU **Package of Practices**). By predicting microclimate sporulation windows **before pathogen establishment**, JalDrishti provides preventive chemical dosages and organic bio-control solutions, protecting crop yields while reducing unnecessary pesticide expenditure.

```text
┌─────────────────────────┐    ┌─────────────────────────┐    ┌─────────────────────────┐
│  Microclimate Weather   │ ──>│ Epidemiological Match   │ ──>│ Calculate Risk Score    │
│  (Temp, Humidity, Rain) │    │ (Temp & RH Thresholds)  │    │ & Severity Rating       │
└─────────────────────────┘    └─────────────────────────┘    └────────────┬────────────┘
                                                                            │
┌─────────────────────────┐    ┌─────────────────────────┐                 │
│ Actionable Pest Card    │ <──│ Chemical & Organic Bio- │ <─────────────────┘
│ (PestAdvisoryScreen)    │    │ Treatment Advisories    │
└─────────────────────────┘    └─────────────────────────┘
```

---

## 🛰️ 2. Microclimate Input Parameters

The epidemiological risk engine evaluates daily meteorological telemetry against crop-specific pathogen models:

| Variable Name | Source / Provider | Code Location | Unit / Format | Agronomic Function |
|---|---|---|---|---|
| **`max_temp_c`** | Open-Meteo Satellite Feed | `app/services/weather_service.py` | °C | Daily maximum air temperature |
| **`min_temp_c`** | Open-Meteo Satellite Feed | `app/services/weather_service.py` | °C | Daily minimum air temperature |
| **`temp_mean`** | Engine Calculation | `(max_temp + min_temp) / 2` | °C | Mean daily thermal window for spore germination |
| **`humidity_percent`** | Open-Meteo Satellite Feed | `app/services/weather_service.py` | % | Relative humidity (RH) at 2m height |
| **`precipitation_mm`** | Open-Meteo Satellite Feed | `app/services/weather_service.py` | mm | Rainfall depth (amplifies fungal leaf wetness) |
| **`crop_id`** | Farm Plot Profile | PostgreSQL (`farm_plots`) | String | Target crop identifier (`paddy_rice`, `potato`, etc.) |

---

## 🔬 3. Agronomic Pathogen Rule Matrix

JalDrishti embeds verified epidemiological rules for major Indian cash and food crops within `app/engine/pest_disease_engine.py`:

| Target Crop | Pathogen / Disease Name | Category | Temp Window | Min RH | Severity | Symptoms & Diagnostics |
|---|---|---|---|---|---|---|
| 🌾 **Paddy** | **Rice Blast** (*Pyricularia oryzae*) | Fungal Disease | 18°C - 28°C | ≥ 80% | **HIGH** | Spindle-shaped brown leaf lesions with grayish centers. |
| 🌾 **Paddy** | **Sheath Blight** (*Rhizoctonia solani*) | Fungal Disease | 28°C - 35°C | ≥ 85% | **CRITICAL** | Oval greenish-gray lesions on leaf sheaths near water line. |
| 🌾 **Paddy** | **Yellow Stem Borer** (*Scirpophaga incertulas*) | Insect Pest | 25°C - 36°C | ≥ 60% | **MEDIUM** | Dead hearts in vegetative stage; empty white panicles in bloom. |
| 🥔 **Potato** | **Late Blight** (*Phytophthora infestans*) | Fungal Blight | 10°C - 22°C | ≥ 85% | **CRITICAL** | Water-soaked dark leaf lesions with white morning dew mildew. |
| 🌾 **Wheat** | **Yellow / Stripe Rust** (*Puccinia striiformis*) | Fungal Rust | 8°C - 20°C | ≥ 75% | **HIGH** | Bright yellow pustules arranged in linear stripes along leaf veins. |
| 🌻 **Mustard** | **Mustard Aphid** (*Lipaphis erysimi*) | Sucking Pest | 15°C - 26°C | ≥ 55% | **HIGH** | Green/black sap-sucking clusters on inflorescence & leaf curls. |
| 🌽 **Maize** | **Fall Armyworm** (*Spodoptera frugiperda*) | Lepidopteran Pest | 22°C - 34°C | ≥ 65% | **CRITICAL** | Ragged whorl feeding holes & heavy frass in central funnels. |

---

## 🧮 4. Epidemiological Risk Evaluation & Scoring Algorithm

The evaluation algorithm executes daily for every active crop plot:

### Step 1: Thermal Mean Calculation
$$T_{\mathrm{mean}} = \frac{T_{\mathrm{max}} + T_{\mathrm{min}}}{2} \quad [^\circ\mathrm{C}]$$

### Step 2: Microclimate Matching Rules

For each pathogen rule r associated with the active crop:

1. **Temperature Match ($M_T$)**:
   $$M_T = (T_{\mathrm{min}} \le T_{\mathrm{mean}} \le T_{\mathrm{max}})$$

2. **Humidity Match ($M_{\mathrm{RH}}$)**:
   $$M_{\mathrm{RH}} = (\mathrm{RH} \ge \mathrm{RH}_{\mathrm{min}})$$

### Step 3: Dynamic Risk Scoring & Leaf Wetness Amplification

When both $M_T$ and $M_{\mathrm{RH}}$ evaluate to **True**:

$$S_{\mathrm{base}} = 85$$

If precipitation $P > 2.0\mathrm{~mm}$ (indicating extended leaf surface wetness):

$$S_{\mathrm{risk}} = \min(S_{\mathrm{base}} + 10, \, 99) \quad [\%]$$

Otherwise:

$$S_{\mathrm{risk}} = 85 \quad [\%]$$

---

## 💊 5. Chemical & Bio-Organic Treatment Recommendations

When a pathogen risk threshold is breached, the engine supplies paired **Chemical** and **Organic Bio-Control** treatment procedures:

### 1. Rice Blast (*Pyricularia oryzae*)
- **Chemical Treatment**: Tricyclazole 75 WP @ 0.6 g/L water (120 g/acre) OR Isoprothiolane 40 EC @ 1.5 mL/L.
- **Organic Bio-Treatment**: Spray *Pseudomonas fluorescens* @ 10 g/L OR Neem Oil (10,000 ppm) @ 3 mL/L.
- **Preventive Cultural Tip**: Avoid excessive Nitrogen fertilizer applications during overcast, high-humidity weather.

### 2. Potato Late Blight (*Phytophthora infestans*)
- **Chemical Treatment**: Prophylactic: Mancozeb 75 WP @ 2.5 g/L. Curative: Cymoxanil 8% + Mancozeb 64% WP @ 3.0 g/L.
- **Organic Bio-Treatment**: Copper Oxychloride 50 WP @ 3.0 g/L OR *Trichoderma viride* foliar spray.
- **Preventive Cultural Tip**: Earthing up soil to cover exposed tubers and destroying infected plant haulms.

### 3. Wheat Yellow / Stripe Rust (*Puccinia striiformis*)
- **Chemical Treatment**: Propiconazole 25 EC @ 1.0 mL/L (200 mL/acre) OR Tebuconazole 25.9 EC @ 1.5 mL/L.
- **Organic Bio-Treatment**: Cow urine (10%) mixed with fermented sour buttermilk foliar spray.
- **Preventive Cultural Tip**: Use resistant varieties (e.g. HD-2967, DBW-187) and clear volunteer weeds.

### 4. Mustard Aphid (*Lipaphis erysimi*)
- **Chemical Treatment**: Thiamethoxam 25 WG @ 80 g/acre OR Dimethoate 30 EC @ 1.7 mL/L.
- **Organic Bio-Treatment**: Neem Seed Kernel Extract (NSKE 5%) @ 50 mL/L OR Azadirachtin 10,000 ppm @ 2 mL/L.
- **Preventive Cultural Tip**: Sowing before October 25 significantly escapes severe aphid infestation.

### 5. Maize Fall Armyworm (*Spodoptera frugiperda*)
- **Chemical Treatment**: Emamectin Benzoate 5 SG @ 0.4 g/L (80 g/acre) OR Spinetoram 11.7 SC @ 0.5 mL/L into plant whorls.
- **Organic Bio-Treatment**: *Metarhizium anisopliae* @ 5 g/L OR sand + neem cake mixture (9:1) applied in whorls.
- **Preventive Cultural Tip**: Deep summer plowing to expose overwintering pupae to predatory birds.

---

## 💻 6. Python Implementation Reference

- **Pest & Disease Science Engine**: `app/engine/pest_disease_engine.py`
- **API Endpoint Handler**: `app/api/v1/endpoints/crops.py`
- **Mobile Pest Advisory Screen**: `lib/screens/pest_advisory_screen.dart`
