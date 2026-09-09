# API Reference: Chatbot & Pest Advisory Endpoints

> **Audience**: Mobile developers, AI engineers, and QA automation engineers. For deep retrieval mechanics and prompt safety, see [JalSathi AI Pipeline](../07-ai-rag-pipeline/README.md).  
> **Source Controllers**:  
> - [`app/api/v1/endpoints/chatbot.py`](file:///d:/jaldrishti/jaldrishti-backend/app/api/v1/endpoints/chatbot.py)  
> - [`app/api/v1/endpoints/crop_info.py`](file:///d:/jaldrishti/jaldrishti-backend/app/api/v1/endpoints/crop_info.py)  
> **Schemas**: [`app/schemas/chat_schema.py`](file:///d:/jaldrishti/jaldrishti-backend/app/schemas/chat_schema.py)

---

## 1. `POST /api/v1/chatbot/query`
Executes an interactive multi-turn agronomy chat turn with **JalSathi AI**. Translates non-English queries, searches dense ChromaDB ICAR Package of Practices vectors, injects localized weather if relevant, invokes the Groq LLM cascade, and applies post-generation chemical guardrails.

- **Authentication**: `Bearer <access_token>` (`get_current_user`)
- **Request Body** (`ChatbotRequest`):
  ```json
  {
    "query": "ধান গাছে বাদামী শোষক পোকা (BPH) হলে কী ওষুধ দেব?",
    "session_id": "sess_8f9a2b1c4d5e",
    "language": "Bengali",
    "farmer_name": "Ramesh",
    "location_name": "Burdwan, West Bengal",
    "current_crop": "paddy_rice",
    "farm_area_acres": 2.5
  }
  ```
- **Response** (`200 OK` - `ChatbotResponse`):
  ```json
  {
    "session_id": "sess_8f9a2b1c4d5e",
    "response": "নমস্কার রমেশবাবু! ধান গাছে বাদামী শোষক পোকা (BPH) দমনের জন্য ট্রাইফ্লুমেজোপাইরিম ১০% এসসি প্রতি একরে ৯৪ মিলি অথবা পাইমেট্রোজিন ৫০% ডব্লিউজি ১২০ গ্রাম হারে স্প্রে করুন। জমিতে অতিরিক্ত ইউরিয়া ব্যবহার বন্ধ রাখুন এবং জল নিকাশের ব্যবস্থা করুন।",
    "structured_analysis": {
      "reply_text": "নমস্কার রমেশবাবু! ধান গাছে বাদামী শোষক পোকা (BPH) দমনের জন্য...",
      "weather_alert": null,
      "solution": {
        "chemical_treatment": "Triflumezopyrim 10% SC @ 94 ml/acre or Pymetrozine 50% WG @ 120 g/acre",
        "organic_alternative": "Neem oil 10,000 ppm @ 2 ml/L water",
        "preventative_cultural_tip": "Drain standing water for 3-4 days to break insect lifecycle; avoid excessive nitrogen."
      }
    }
  }
  ```

---

## 2. `POST /api/v1/crops/pest-advisory`
Fetches live weather telemetry for the requested coordinates and evaluates rule-based pest and disease vulnerability models based on temperature, relative humidity, and rainfall.

> [!IMPORTANT]
> **Authentication Hardening (Phase 2 Fix [F-06])**: In legacy code, this endpoint was unauthenticated, allowing unauthorized clients to trigger external satellite API calls. Phase 2 added mandatory `Depends(get_current_user)` protection.

- **Authentication**: `Bearer <access_token>` (`get_current_user`)
- **Request Body** (`PestAdvisoryRequest`):
  ```json
  {
    "crop_id": "paddy_rice",
    "latitude": 23.2324,
    "longitude": 87.8615,
    "sowing_date": "2026-07-01"
  }
  ```
- **Response** (`200 OK` - `PestAdvisoryResponse`):
  ```json
  {
    "crop_name": "Paddy Rice",
    "evaluated_at": "2026-09-09T14:30:00Z",
    "weather_conditions": {
      "temp_max_c": 33.5,
      "temp_min_c": 26.0,
      "humidity_percent": 84.0,
      "precipitation_mm": 2.5
    },
    "alerts": [
      {
        "pest_name": "Bacterial Leaf Blight (BLB)",
        "scientific_name": "Xanthomonas oryzae",
        "risk_level": "HIGH",
        "risk_score": 85,
        "trigger_reasons": [
          "High relative humidity (84% >= 80% threshold)",
          "Warm night temperatures (> 25°C favor bacterial proliferation)"
        ],
        "symptoms": "Water-soaked lesions on leaf margins turning straw-yellow and wavy.",
        "management_tips": [
          "Avoid excess nitrogenous fertilizer top-dressing",
          "Apply Copper Oxychloride 50% WP @ 500 g/acre + Streptomycin sulphate 9% @ 30 g/acre"
        ]
      }
    ]
  }
  ```
