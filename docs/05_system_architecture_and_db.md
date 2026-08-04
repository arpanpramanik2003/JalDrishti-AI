# ⚡ System Architecture, Database Schema & Caching Pipeline

## 📖 1. System Overview & Technical Blueprint

**JalDrishti** is engineered as a decoupled, microservice-ready platform designed for high performance, fault tolerance, and minimal latency under intermittent agricultural connectivity. 

The architecture bridges a cross-platform **Flutter Mobile Client** with an asynchronous **FastAPI Backend**, backed by **Supabase PostgreSQL (Transaction Pooler)**, **Redis Cloud Distributed Caching**, and **ChromaDB Vector Embeddings**.

```mermaid
graph TD
    subgraph "Flutter Mobile Client Layer"
        UI["Main Navigation & Dashboards"]
        State["Provider State Managers"]
        LocalCache["SharedPreferences & Offline Cache"]
    end

    subgraph "FastAPI Microservices API Gateway"
        Router["v1 API Routers"]
        HydroEngine["FAO-56 Hydrological Engine"]
        SoilEngine["Soil Water Bucket Model"]
        PestEngine["Pest & Disease Risk Engine"]
        RAGEngine["JalSathi RAG Vector Engine"]
    end

    subgraph "Persistence & Cloud Services"
        DB["Supabase PostgreSQL Cluster (Port 6543)"]
        Cache["Redis Cloud In-Memory Cache"]
        Chroma["ChromaDB Local Vector Store"]
        LLM["Groq Llama-3 / Gemini AI Models"]
        WeatherAPI["Open-Meteo Satellite Feed"]
        SoilAPI["ISRIC SoilGrids 250m API"]
    end

    UI --> State
    State --> LocalCache
    State -->|HTTPS REST API| Router

    Router --> HydroEngine
    Router --> SoilEngine
    Router --> PestEngine
    Router --> RAGEngine

    HydroEngine --> WeatherAPI
    SoilEngine --> SoilAPI
    RAGEngine --> Chroma
    RAGEngine --> LLM
    Router --> DB
    Router --> Cache
```

---

## 🗄️ 2. Database Architecture (Supabase PostgreSQL)

JalDrishti uses **Supabase PostgreSQL** for cloud relational persistence. The backend connects via SQLAlchemy ORM over Supabase's high-performance **Transaction Pooler** (Port `6543`) using IPv4/IPv6 pooled TCP connections:

```text
postgresql://postgres.[REF]:[PASS]@aws-1-ap-northeast-2.pooler.supabase.com:6543/postgres
```

### Entity Relationship Diagram (ERD)

```mermaid
erDiagram
    USERS ||--o{ FARM_PLOTS : "owns"
    USERS ||--o{ FARMER_PROFILES : "has"
    FARM_PLOTS ||--o{ IRRIGATION_LOGS : "records"

    USERS {
        int id PK
        string email
        string username
        string hashed_password
        boolean is_active
        datetime created_at
    }

    FARMER_PROFILES {
        int id PK
        int user_id FK
        string first_name
        string last_name
        string phone_number
        string state
        string district
        string location_name
        float farm_area_acres
        string interested_crop
    }

    FARM_PLOTS {
        int id PK
        int user_id FK
        string name
        float latitude
        float longitude
        string crop_id
        string sowing_date
        float area_acres
        float pump_hp
        float pump_flow_lps
        string irrigation_method
        string soil_type
        datetime created_at
    }

    IRRIGATION_LOGS {
        int id PK
        int farm_plot_id FK
        float applied_mm
        string applied_date
        string notes
        datetime created_at
    }
```

---

## ⚡ 3. High-Speed Caching Layer (Redis Cloud)

To guarantee sub-100ms response times and prevent rate-limiting from external weather and satellite APIs, JalDrishti uses **Redis Cloud**:

```text
redis://default:[TOKEN]@redis-15508.crce276.ap-south-1-3.ec2.cloud.redislabs.com:15508
```

### Cache Key Design & Time-To-Live (TTL) Policy

| Cache Target | Key Pattern | TTL Duration | Purpose & Data Payload |
|---|---|---|---|
| **Weather Forecast** | `weather:{lat_2dec}:{lon_2dec}` | `10800 sec` ($3\text{ Hours}$) | Cached 6-day Open-Meteo hourly & daily weather forecast JSON array. |
| **Soil Physical Content** | `soil:{lat_2dec}:{lon_2dec}` | `604800 sec` ($7\text{ Days}$) | Satellite clay/sand composition percentages from ISRIC SoilGrids. |
| **RAG Embedding Cache** | `rag:query:{hash}` | `86400 sec` ($24\text{ Hours}$) | Pre-computed vector search results for frequent agronomy queries. |

#### Redis Cache Lookup Implementation Pattern:

```python
# Cache Lookup Strategy in WeatherService
cache_key = f"weather:{round(latitude, 2)}:{round(longitude, 2)}"
cached_json = CacheService.get(cache_key)

if cached_json:
    return json.loads(cached_json)

# Fetch from Open-Meteo API on cache miss...
weather_data = await fetch_open_meteo(latitude, longitude)
CacheService.set(cache_key, json.dumps(weather_data), expire_seconds=10800)
return weather_data
```

---

## 🌐 4. FastAPI Router Architecture & API Endpoint Catalog

The backend is structured into async modular v1 endpoint routers in [`app/api/v1/endpoints/`](file:///d:/jaldrishti/jaldrishti-backend/app/api/v1/endpoints/):

| Endpoint Path | HTTP Method | Router Handler | Functionality Description |
|---|---|---|---|
| `/api/v1/auth/register` | `POST` | `auth.py` | Registers user account and generates hashed password |
| `/api/v1/auth/login` | `POST` | `auth.py` | Authenticates farmer credentials and issues JWT Access Token |
| `/api/v1/plots/` | `GET / POST` | `farm_plots.py` | Multi-plot CRUD management for farmer fields |
| `/api/v1/irrigation/recommendation` | `POST` | `irrigation.py` | Executes Penman-Monteith, Rain Hold & ROI calculations |
| `/api/v1/irrigation/log-run` | `POST` | `irrigation.py` | Logs actual pump operation event to database |
| `/api/v1/crops/pest-advisory` | `POST` | `crops.py` | Evaluates microclimate rules for disease advisories |
| `/api/v1/jalsathi/chat` | `POST` | `jalsathi.py` | Executes RAG vector retrieval & LLM chat response |

---

## 📱 5. Mobile Client State Management (Flutter Providers)

JalDrishti Mobile utilizes the `provider` package for clean reactive state handling across screens:

```mermaid
graph TD
    App["JalDrishti App Root"] --> AuthProvider["AuthProvider (JWT Session & User Profile)"]
    App --> PlotProvider["FarmPlotProvider (Multi-Plot CRUD State)"]
    App --> IrrigProvider["IrrigationProvider (Hydrology & Pump Telemetry)"]
    App --> ChatProvider["ChatProvider (RAG Voice STT/TTS State)"]
    App --> NotifProvider["NotificationProvider (Local Push Alerts)"]

    PlotProvider -->|Triggers Active Plot Change| IrrigProvider
    IrrigProvider -->|Pushes Rain Hold Warning| NotifProvider
```

1. **`AuthProvider`**: Manages user authentication, profile persistence, and JWT tokens in `SharedPreferences`.
2. **`FarmPlotProvider`**: Manages multi-plot creation, active plot selection, and plot updates.
3. **`IrrigationProvider`**: Handles recommendation API calls, offline caching, and optimistic `todayLoggedMm` state updates.
4. **`ChatProvider`**: Manages voice Speech-to-Text (`speech_to_text`), Text-to-Speech (`flutter_tts`), decibel sound level streaming, and multi-lingual UI translation.
5. **`NotificationProvider`**: Stores in-app alerts for rain warnings and pump runtime schedules.

---

## ⚙️ 6. Dynamic Server Connection Switcher

To support seamless switching between local development, Android Emulators, and physical mobile phones connected via USB ADB or Wi-Fi LAN, JalDrishti Mobile includes a built-in **Server Config Switcher**:

```text
┌─────────────────────────┐    ┌───────────────────────────────────────────────────┐
│ Connection Mode         │    │ Base URL Target                                   │
├─────────────────────────┼────┼───────────────────────────────────────────────────┤
│ Android Emulator        │ ──>│ http://10.0.2.2:8000                              │
│ Physical USB (ADB Mode) │ ──>│ http://127.0.0.1:8000 (adb reverse tcp:8000 8000) │
│ Wi-Fi LAN IP Testing    │ ──>│ http://10.249.147.69:8000                         │
└─────────────────────────┴────┴───────────────────────────────────────────────────┘
```

Farmers and developers can access the host switcher by tapping the ⚙️ icon on the Login Screen or App Drawer.

---

## 💻 7. Code Implementation Reference

- **Database Session Manager**: [`app/db/database.py`](file:///d:/jaldrishti/jaldrishti-backend/app/db/database.py)
- **Redis Cache Service**: [`app/services/cache_service.py`](file:///d:/jaldrishti/jaldrishti-backend/app/services/cache_service.py)
- **Database Models**: [`app/models/farm_plot.py`](file:///d:/jaldrishti/jaldrishti-backend/app/models/farm_plot.py), [`app/models/user.py`](file:///d:/jaldrishti/jaldrishti-backend/app/models/user.py)
- **Mobile Providers**: [`lib/providers/irrigation_provider.dart`](file:///d:/jaldrishti/jaldrishti_mobile/lib/providers/irrigation_provider.dart), [`lib/providers/chat_provider.dart`](file:///d:/jaldrishti/jaldrishti_mobile/lib/providers/chat_provider.dart)
