# API Reference: Administrative & Internal Infrastructure Endpoints

> **Audience**: DevOps engineers, system administrators, and infrastructure monitoring systems.  
> **Source Controllers**:  
> - [`app/api/v1/endpoints/admin_tariffs.py`](file:///d:/jaldrishti/jaldrishti-backend/app/api/v1/endpoints/admin_tariffs.py)  
> - [`app/api/v1/endpoints/crop_info.py`](file:///d:/jaldrishti/jaldrishti-backend/app/api/v1/endpoints/crop_info.py)  
> - [`app/main.py`](file:///d:/jaldrishti/jaldrishti-backend/app/main.py)  
> **Authorization Header**: `X-Admin-API-Key: <ADMIN_API_KEY>`

---

## 1. Administrative Endpoints (Internal Only)

> [!IMPORTANT]
> **Mobile App Exemption Confirmation**:
> Following Phase 2 security hardening and Phase 6 contract audits, all administrative endpoints require `X-Admin-API-Key`. These endpoints are **intentionally not called by the farmer mobile application** (`jaldrishti_mobile/`). They are reserved for administrative operators and automated cron runners.

### `GET /api/v1/admin/tariffs`
Lists all state-level agricultural power tariffs, diesel costs, and CEA grid carbon emission benchmarks.

- **Authentication**: `X-Admin-API-Key` (`require_admin_api_key`)
- **Response** (`200 OK` - `List[RegionalTariffResponse]`):
  ```json
  [
    {
      "id": 1,
      "state_code": "WB",
      "state_name": "West Bengal",
      "diesel_tariff_inr_hr": 80.0,
      "electric_tariff_inr_hr": 25.0,
      "diesel_co2_kg_hr": 2.68,
      "electric_co2_kg_hr": 0.72,
      "attribution_notice": "Calculated using state agricultural tariff benchmarks & CEA India Grid emission factor.",
      "updated_at": "2026-09-09T08:00:00Z"
    },
    {
      "id": 2,
      "state_code": "DEFAULT",
      "state_name": "National Benchmark",
      "diesel_tariff_inr_hr": 145.0,
      "electric_tariff_inr_hr": 80.0,
      "diesel_co2_kg_hr": 3.42,
      "electric_co2_kg_hr": 2.68,
      "attribution_notice": "National average agricultural power benchmark.",
      "updated_at": "2026-09-09T08:00:00Z"
    }
  ]
  ```

---

### `PUT /api/v1/admin/tariffs/{state_code}`
Updates economic cost tariffs or carbon emission factors for a given Indian state.

- **Authentication**: `X-Admin-API-Key` (`require_admin_api_key`)
- **Path Parameters**: `state_code` (e.g. `"WB"`, `"UP"`, `"PB"`)
- **Request Body** (`RegionalTariffUpdate`):
  ```json
  {
    "electric_tariff_inr_hr": 28.0,
    "diesel_tariff_inr_hr": 95.0
  }
  ```
- **Response** (`200 OK` - `RegionalTariffResponse`): Returns the updated state tariff entry.

---

### `POST /api/v1/crops/trigger-batch-advisories`
Manually triggers the background batch cron job across all registered farm plots in the database. Evaluates weather risks and pushes Firebase FCM notifications using bounded concurrency (`asyncio.Semaphore(20)`).

- **Authentication**: `X-Admin-API-Key` (`require_admin_api_key`)
- **Request Body**: None
- **Response** (`200 OK`):
  ```json
  {
    "status": "success",
    "total_plots_scanned": 142,
    "notifications_dispatched": 118,
    "execution_time_seconds": 3.42
  }
  ```

---

## 2. Infrastructure Health & Liveness Probes

The backend exposes standardized, unauthenticated health check endpoints used by Docker health checks, Render/Railway orchestrators, and uptime monitors:

| Method | Endpoint Path | Authentication | Response Schema | Purpose |
|:-------|:--------------|:---------------|:----------------|:--------|
| `GET` | `/` | None (Public) | `{"status": "online", "service": "JalDrishti AI Engine"}` | Root service index & ping. |
| `GET` | `/health`, `/healthy` | None (Public) | `{"status": "healthy", "timestamp": "..."}` | Root-level orchestrator liveness probe. |
| `GET` | `/api/v1/health`, `/api/v1/healthy` | None (Public) | `{"status": "healthy", "api_version": "v1"}` | API router level liveness probe. |
