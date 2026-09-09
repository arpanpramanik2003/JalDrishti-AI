# 🌾 JalDrishti (जलदृष्टि) – AI-Powered Precision Agronomy & Hydrological Irrigation Engine

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.24-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"></a>
  <a href="https://fastapi.tiangolo.com"><img src="https://img.shields.io/badge/FastAPI-0.109-009688?style=for-the-badge&logo=fastapi&logoColor=white" alt="FastAPI"></a>
  <a href="https://python.org"><img src="https://img.shields.io/badge/Python-3.11-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python"></a>
  <a href="https://supabase.com"><img src="https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" alt="Supabase"></a>
  <a href="https://redis.io"><img src="https://img.shields.io/badge/Redis-AsyncIO-DC382D?style=for-the-badge&logo=redis&logoColor=white" alt="Redis"></a>
  <a href="https://trychroma.com"><img src="https://img.shields.io/badge/ChromaDB-VectorDB-FF6F00?style=for-the-badge&logo=python&logoColor=white" alt="ChromaDB"></a>
  <a href="https://groq.com"><img src="https://img.shields.io/badge/Groq-LPU%20Inference-F55036?style=for-the-badge&logo=fastly&logoColor=white" alt="Groq"></a>
</p>

---

## 📌 Executive Summary

**JalDrishti (जलदृष्टि)** is a climate-smart agronomy and precision irrigation advisory platform engineered specifically for Indian smallholder agriculture. It combines **FAO-56 Penman-Monteith Evapotranspiration modeling**, **persistent daily root-zone water balance tracking**, **ISRIC SoilGrids pedotransfer physics**, real-time **Open-Meteo satellite meteorology**, and a **100% Groq-native multilingual AI assistant (JalSathi AI)**.

JalDrishti operates **without physical in-situ soil moisture sensors**, providing smallholders with scientific decision support to optimize water usage, eliminate diesel and electricity pump waste, mitigate microclimate disease outbreaks, and track verified cumulative financial savings (ROI).

> [!NOTE]
> **Definitive Documentation Set**:  
> Following a comprehensive engineering audit and six remediation phases (September 2026), a brand-new, audited documentation set is available in [`documentation/`](./documentation/README.md). The legacy `docs/` folder is retained strictly for historical reference.

---

## 🔥 Key System Capabilities

### 💧 1. Rigorous FAO-56 Penman-Monteith Hydrology Engine
- **Reference Evapotranspiration ($ET_o$)**: Daily calculation utilizing Stefan-Boltzmann net longwave radiation (FAO-56 Eq. 39), psychrometrics, and a logarithmic wind-speed reduction from 10m satellite measurement to standard 2m surface height (FAO-56 Eq. 47).
- **Dynamic Crop Phenology ($K_c(t)$)**: Continuous 4-stage crop growth curve scaling across Initial, Crop Development, Mid-Season peak, and Late-Season linear decay to harvest.
- **Persistent Root-Zone Mass Balance**: Tracks cumulative daily depletion ($D_i = D_{i-1} - P_{\text{eff}} - I_{\text{applied}} + ET_c$) backed by persistent database state (`SoilDepletionState`), eliminating transient memory loss across the season.
- **Lifecycle Boundary Protection**: Handles pre-sowing (`NOT_YET_SOWN`) and post-harvest overdue (`HARVEST_OVERDUE`) states, halting unneeded pumping advisories.
- **Pump Duration Translation**: Converts gross water required (accounting for Drip, Sprinkler, or Flood efficiencies) into exact pump runtime in hours and minutes based on plot acreage, pump HP, and discharge flow ($L/\text{sec}$).

### 🌧️ 2. Smart Rain Hold Warning & Cost Protection
- Evaluates multi-temporal forecast precipitation: **$\ge 3.0\text{ mm}$ in 24h**, **$\ge 5.0\text{ mm}$ in 48h**, or **$\ge 4.0\text{ mm}$ today**.
- Automatically activates **RAIN HOLD** when soil is dry but rain is imminent, suppressing unnecessary irrigation.
- Prevents soil waterlogging and nutrient leaching, saving **₹150–₹500 in diesel/electricity per avoided run**.

### 📊 3. Cumulative Farmer Financial & Environmental ROI Tracker
- Real-time telemetry tracking total **Liters of Water Saved**, **Pump Hours Avoided**, **Money Saved (₹ INR)**, and **$\text{CO}_2$ Emissions Avoided (kg)**.
- **Idempotent Accounting**: Increments skipped runs strictly when Rain Hold overrides a necessary irrigation event, gated by calendar date with zero arbitrary inflation offsets. Renders an honest zero-state (`0 kL saved (₹0)`) for fresh accounts.

### 🐛 4. Weather-Driven Pest & Disease Early Warning System
- Evaluates daily temperature, relative humidity, and rainfall duration against microclimate pathogen proliferation models.
- Provides early-warning alerts for high-risk Indian crop diseases:
  - 🌾 **Paddy**: Bacterial Leaf Blight (*Xanthomonas oryzae*), Blast (*Magnaporthe oryzae*), Brown Planthopper (*Nilaparvata lugens*)
  - 🥔 **Potato**: Late Blight (*Phytophthora infestans*)
  - 🌾 **Wheat**: Yellow Rust (*Puccinia striiformis*)
  - 🌻 **Mustard**: Aphid Infestation (*Lipaphis erysimi*)
  - 🌽 **Maize**: Fall Armyworm (*Spodoptera frugiperda*)
- Delivers actionable Integrated Pest Management (IPM) guidelines with grounded chemical treatments and organic bio-alternatives (e.g., Neem oil, *Pseudomonas fluorescens*).

### 🤖 5. JalSathi AI – 100% Groq-Native Multilingual RAG Voice Assistant
- **Dense Vector Search**: Powered by embedded **ChromaDB 1.5.9** and **`all-MiniLM-L6-v2`** dense 384-d embeddings over ICAR & State Agricultural University Package of Practices (PoP) guides.
- **Fast Preliminary Translation**: Translates Bengali and Hindi queries into concise English agronomic search terms in sub-150ms via Groq, ensuring high-accuracy semantic retrieval without adding external third-party translation APIs.
- **Three-Tier Fallback Cascade**: Primary Groq (`openai/gpt-oss-20b`) $\rightarrow$ Fast Groq (`groq/compound-mini`) $\rightarrow$ Zero-LLM Local Deterministic Fallback (formatting ICAR chunks directly during network outages).
- **Anti-Hallucination Chemical Guardrails**: Enforces strict prompt grounding and post-generation scanning across 45+ agrochemical active ingredients, replacing ungrounded recommendations with a Krishi Vigyan Kendra (KVK) advisory.
- **Bilingual Voice Interaction**: Speech-to-Text (STT) and native Text-to-Speech (TTS) audio playback in Bengali (`bn-IN`), Hindi (`hi-IN`), and English (`en-US`).

---

## 🏗️ System Architecture

```mermaid
graph TD
    subgraph ClientLayer ["Mobile Client (Flutter 3.24)"]
        UI["Main Navigation Shell"]
        DASH["Home Dashboard & Advisory Card"]
        ANALYTICS["5-Tab Analytics & Water Gauge"]
        CHAT["JalSathi AI Voice & Chat Screen"]
        INTERCEPTOR["Centralized 401 Interceptor<br/>(Silent Token Refresh)"]
        HIVE["Hive Local NoSQL DB<br/>(Cache & Offline Queue)"]
        
        UI --> DASH
        UI --> ANALYTICS
        UI --> CHAT
        DASH <--> HIVE
        DASH --> INTERCEPTOR
    end

    subgraph BackendGateway ["Application Backend (FastAPI / ASGI)"]
        AUTH["Security Dependencies<br/>(JWT Bearer / get_current_user)"]
        ROUTERS["API v1 Route Controllers"]
        THREADPOOL["Worker Threadpool<br/>(run_in_threadpool)"]
        
        INTERCEPTOR -->|HTTPS / REST| AUTH
        AUTH --> ROUTERS
        ROUTERS <-->|Non-blocking SQL| THREADPOOL
    end

    subgraph ComputeEngines ["Hydrology & Agronomy Engines"]
        PM["FAO-56 Penman-Monteith<br/>(Eq. 39 R_nl + Eq. 47 Wind)"]
        BUCKET["Soil Water Bucket Engine<br/>(Persistent Depletion Mass Balance)"]
        ROI["Regional Tariff & Savings Engine<br/>(State Electricity/Diesel Tariffs)"]
        
        ROUTERS --> PM
        ROUTERS --> BUCKET
        ROUTERS --> ROI
    end

    subgraph AIEngine ["JalSathi AI Pipeline (100% Groq-Native)"]
        TRANS["Fast Indic Query Translator<br/>(Sub-150ms Groq Hop)"]
        CHROMA["ChromaDB Vector Store<br/>(all-MiniLM-L6-v2 Embeddings)"]
        CASCADE["3-Tier Groq Fallback Cascade<br/>(Primary -> Fast -> Local PoP)"]
        GUARD["Active Ingredient Safety Guardrail"]
        
        ROUTERS --> TRANS
        TRANS --> CHROMA
        CHROMA --> CASCADE
        CASCADE --> GUARD
    end

    subgraph DataStorage ["Data, Cache & Satellite Providers"]
        REDIS["Async Redis Cache<br/>(weather: 3h, soil: 30d TTL)"]
        DB[(Supabase PostgreSQL)]
        METEO["Open-Meteo Weather API"]
        SOIL["ISRIC SoilGrids v2.0 API<br/>(0.05° Grid Coarsening)"]
        FCM["Firebase Cloud Messaging<br/>(Bounded Concurrency Cron)"]
        
        ROUTERS <-->|redis.asyncio| REDIS
        THREADPOOL <-->|SQLAlchemy ORM| DB
        ROUTERS <-->|HTTPX Async| METEO
        ROUTERS <-->|HTTPX Async| SOIL
        ROUTERS -->|asyncio.Semaphore(20)| FCM
    end
```

---

## 🛠️ Technology Stack

| Layer | Technology | Version / Specification | Role in System |
|:------|:-----------|:------------------------|:---------------|
| **Mobile Client** | Flutter / Dart | Flutter 3.24+, Dart 3.x | Cross-platform mobile app with Provider state management and Hive offline sync |
| **Backend API** | FastAPI / Uvicorn | FastAPI 0.109+, Python 3.11 | High-throughput asynchronous REST API engine |
| **Relational Database**| Supabase PostgreSQL | PostgreSQL 15+ via SQLAlchemy ORM | Relational persistence for users, farm plots, logs, and `SoilDepletionState` |
| **Caching Layer** | Redis Cloud (`redis.asyncio`)| Redis 7.x (Async Client) | 3h weather cache, 30d soil cache, and JWT revocation blacklist |
| **Vector Database** | ChromaDB | Version 1.5.9 (Persistent SQLite) | Embedded vector store for ICAR Package of Practices guidelines |
| **Embedding Model** | Sentence-Transformers | `all-MiniLM-L6-v2` (384-dimensional) | Local CPU embedding inference (~120 MB peak RAM) |
| **LLM Inference** | Groq Cloud API | LPU Inference (`openai/gpt-oss-20b`) | High-speed multilingual agronomy generation with sub-second response |
| **Meteorological Feed**| Open-Meteo API | High-Resolution NWP API | Real-time solar radiation, temperature, relative humidity, wind, and rain |
| **Soil Intelligence**| ISRIC SoilGrids v2.0 | REST API ($0.05^\circ$ Grid Binning) | Volumetric clay and sand fractions for pedotransfer calculation |
| **Push Notifications**| Firebase Admin SDK | FCM v1 (HTTP/2) | Morning weather and pest advisories via bounded concurrency batching |
| **Test Framework** | Pytest / TestClient | Pytest 9.1.1 (44/44 passing) | Automated regression, hydrology validation, security, and contract test suite |

---

## 📁 Repository Directory Structure

```text
jaldrishti/
├── documentation/                      # 📖 Definite, Audited Documentation Set (Phases 7A-7D)
│   ├── README.md                       # Master index & reading paths across all numbered folders
│   ├── 00-start-here/                  # Plain-language mission, reading paths & build notes
│   ├── 01-concepts-and-workflows/      # Water bucket analogy, farmer journey, rain hold, AI chat
│   ├── 02-scientific-reference/        # FAO-56 math, Kc decay, root depth, depletion formulas
│   ├── 03-system-architecture/         # Real stack topology, request trace, async Redis caching
│   ├── 04-database-reference/          # Corrected 9-table ERD & table-by-table schema reference
│   ├── 05-api-reference/               # Complete REST API reference across all 24 endpoints
│   ├── 06-mobile-app-reference/        # Screen-by-screen breakdown, 6 Providers, Hive offline sync
│   ├── 07-ai-rag-pipeline/             # ChromaDB vector search, Groq translation, 3-tier cascade
│   └── 08-limitations-and-roadmap/     # Consolidated limitations, open developer questions, history
│
├── docs/                               # 🏛️ Historical Reference Documentation (Preserved untouched)
│
├── jaldrishti-backend/                 # ⚙️ Python FastAPI Backend
│   ├── app/
│   │   ├── api/v1/endpoints/           # Route controllers (auth, plots, irrigation, crops, chat)
│   │   ├── core/                       # App config, security dependencies, centralized constants
│   │   ├── data/                       # ICAR PoP guides, crop coefficients JSON, ChromaDB SQLite
│   │   ├── db/                         # SQLAlchemy database session & engine setup
│   │   ├── engine/                     # Penman-Monteith, Soil Water Bucket & Pest Risk engines
│   │   ├── models/                     # SQLAlchemy ORM models (User, FarmPlot, SoilDepletionState)
│   │   ├── schemas/                    # Pydantic v2 validation schemas
│   │   └── services/                   # CacheService, WeatherService, SoilGridsService, RAGService
│   ├── tests/                          # Automated Pytest suite (44 tests passing)
│   ├── requirements.txt                # Pinned backend dependencies
│   └── main.py                         # FastAPI ASGI entrypoint
│
└── jaldrishti_mobile/                  # 📱 Flutter Mobile Client
    ├── lib/
    │   ├── core/                       # ApiService (401 interceptor), OfflineCache, Theme
    │   ├── l10n/                       # Localization ARB files (app_en.arb, app_bn.arb, app_hi.arb)
    │   ├── models/                     # Client data models (User, FarmPlot, IrrigationResponse)
    │   ├── providers/                  # ChangeNotifiers (Auth, FarmPlot, Irrigation, Chat, Theme)
    │   ├── screens/                    # Dashboard, Analytics (5 tabs), Pest Advisory, JalSathi AI
    │   └── widgets/                    # Reusable UI cards, gauges, pump dials, timeline tiles
    └── pubspec.yaml                    # Pinned Flutter dependencies
```

---

## 🚀 Quick Start & Installation

### 1. Backend Setup (FastAPI)

```bash
# 1. Navigate to backend directory
cd jaldrishti-backend

# 2. Create and activate virtual environment
python -m venv venv
venv\Scripts\activate          # On Windows
# source venv/bin/activate     # On Linux/macOS

# 3. Install dependencies
pip install -r requirements.txt

# 4. Configure environment variables (copy example)
cp .env.example .env
# Edit .env and supply:
# JWT_SECRET_KEY, ADMIN_API_KEY, GROQ_API_KEY, REDIS_URL, DATABASE_URL

# 5. Run test suite to verify installation
pytest -v

# 6. Start the development server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```
> Server runs at `http://localhost:8000` | Interactive OpenAPI Swagger docs at `http://localhost:8000/docs`

### 2. Mobile Client Setup (Flutter)

```bash
# 1. Navigate to mobile directory
cd jaldrishti_mobile

# 2. Fetch Flutter packages
flutter pub get

# 3. Verify code health
flutter analyze

# 4. Launch on connected device / emulator
flutter run
```

---

## 👥 Core Contributors & Maintainers

<table align="center">
  <tr>
    <td align="center" width="50%">
      <a href="https://github.com/arpanpramanik2003/">
        <img src="https://github.com/arpanpramanik2003.png?size=120" width="120px;" style="border-radius:50%;" alt="Arpan Pramanik"/><br />
        <sub><b>Arpan Pramanik</b></sub>
      </a>
      <br />
      <a href="mailto:pramanikarpan089@gmail.com"><code>pramanikarpan089@gmail.com</code></a>
      <br />
      <a href="https://github.com/arpanpramanik2003/">
        <img src="https://img.shields.io/badge/GitHub-arpanpramanik2003-181717?style=flat&logo=github" alt="GitHub Profile" />
      </a>
      <br />
      <sub>Lead Backend Architect & Hydrological Modeling</sub>
    </td>
    <td align="center" width="50%">
      <a href="https://github.com/chandadiya2004/">
        <img src="https://github.com/chandadiya2004.png?size=120" width="120px;" style="border-radius:50%;" alt="Diya Chanda"/><br />
        <sub><b>Diya Chanda</b></sub>
      </a>
      <br />
      <a href="mailto:chandasujata01@gmail.com"><code>chandasujata01@gmail.com</code></a>
      <br />
      <a href="https://github.com/chandadiya2004/">
        <img src="https://img.shields.io/badge/GitHub-chandadiya2004-181717?style=flat&logo=github" alt="GitHub Profile" />
      </a>
      <br />
      <sub>Mobile Application Engineer & UX Design</sub>
    </td>
  </tr>
</table>

---

## ⚖️ License & Ethical Agronomy Statement

JalDrishti is released under the **MIT License**.

> **Ethical Agronomy Notice**:  
> JalDrishti is a digital decision-support tool providing model-based guidance from satellite telemetry and peer-reviewed FAO equations. It is **not a replacement for local field inspection** or agricultural extension officers. Farmers should visually confirm soil moisture and weather conditions before operating high-voltage machinery or applying agrochemicals.

<p align="center">
  <b>Developed for Smallholder Farmers | Powered by Science & AI 🌾💧</b>
</p>
