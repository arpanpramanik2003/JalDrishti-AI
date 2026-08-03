# ⚡ System Architecture, Database Schema & Caching Pipeline

## 📖 Overview
**JalDrishti** employs a modern microservice-ready backend architecture built with **FastAPI**, **Supabase PostgreSQL (Transaction Pooler)**, **Redis Cloud Caching**, and a reactive **Flutter Mobile Client**.

---

## 🗄️ Database Architecture (Supabase PostgreSQL)

The backend connects to Supabase PostgreSQL using SQLAlchemy ORM over a high-performance **Transaction Pooler** (Port `6543`).

```text
postgresql://postgres.oqxebkmoqmmmdtkqfngz:arpanpramanik@aws-1-ap-northeast-2.pooler.supabase.com:6543/postgres
```

### Entity Relationship Diagram (ERD)

```mermaid
erDiagram
    USERS ||--o{ FARM_PLOTS : owns
    FARM_PLOTS ||--o{ IRRIGATION_LOGS : records

    USERS {
        int id PK
        string email
        string username
        string hashed_password
        boolean is_active
        datetime created_at
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

## ⚡ High-Speed Caching Layer (Redis Cloud)

To prevent rate-limiting and minimize latency from external meteorology APIs, JalDrishti uses **Redis Cloud**:

```text
redis://default:IodqrCvkBwMMCXaAg4jXayMaBbtWW3VO@redis-15508.crce276.ap-south-1-3.ec2.cloud.redislabs.com:15508
```

### Key Caching Strategy
- **Weather Grid Key**: `weather:{lat_2dec}:{lon_2dec}`
  - Example: `weather:22.57:88.36`
  - **TTL (Time to Live)**: $10,800\text{ seconds}$ ($3\text{ Hours}$)
  - **Data Payload**: Complete 6-day Open-Meteo JSON weather forecast array.

```python
# Cache Lookup Pattern in WeatherService
cached_data = CacheService.get(cache_key)
if cached_data:
    return cached_data

# Fetch from Open-Meteo API if cache miss...
CacheService.set(cache_key, result, expire_seconds=10800)
```

---

## 📱 Mobile State Management (Flutter Providers)

JalDrishti Mobile utilizes the `provider` package for clean reactive state handling across screens:

```mermaid
graph TD
    App[JalDrishti App Entry] --> AuthProvider[AuthProvider - User Session & JWT]
    App --> PlotProvider[FarmPlotProvider - Multi-Plot CRUD]
    App --> IrrigProvider[IrrigationProvider - Recommendation & Hydrology]
    App --> NotifProvider[NotificationProvider - Local Alerts]

    PlotProvider -->|Triggers Auto-Reload| IrrigProvider
    IrrigProvider -->|Pushes High Demand Alert| NotifProvider
```

1. **`AuthProvider`**: Handles authentication JWT tokens and user profile persistence.
2. **`FarmPlotProvider`**: Manages multi-plot creation, active plot selection, and plot updates.
3. **`IrrigationProvider`**: Manages recommendation API calls, offline caching, and optimistic `todayLoggedMm` state.
4. **`NotificationProvider`**: Stores in-app alerts for rain warnings and pumping schedules.

---

## 🌐 Server Connection Switcher (Dynamic Host Switch)

The mobile client includes a built-in **Server Config Switcher** accessible via the top-right ⚙️ icon on the Login Screen or App Drawer:
- **Default Production Server**: `http://10.0.2.2:8000` (Android Emulator)
- **Localhost / USB ADB Forwarding**: `http://127.0.0.1:8000` (Physical phone via `adb reverse tcp:8000 tcp:8000`)
- **Custom Local Wi-Fi IP**: `http://10.249.147.69:8000` (Wi-Fi LAN testing)

---

## 💻 Code Reference

- **Database Connection**: [`app/db/database.py`](file:///d:/jaldrishti/jaldrishti-backend/app/db/database.py)
- **Redis Cache Service**: [`app/services/cache_service.py`](file:///d:/jaldrishti/jaldrishti-backend/app/services/cache_service.py)
- **Database Models**: [`app/models/farm_plot.py`](file:///d:/jaldrishti/jaldrishti-backend/app/models/farm_plot.py), [`app/models/user.py`](file:///d:/jaldrishti/jaldrishti-backend/app/models/user.py)
- **Mobile Providers**: [`lib/providers/irrigation_provider.dart`](file:///d:/jaldrishti/jaldrishti_mobile/lib/providers/irrigation_provider.dart), [`lib/providers/farm_plot_provider.dart`](file:///d:/jaldrishti/jaldrishti_mobile/lib/providers/farm_plot_provider.dart)
