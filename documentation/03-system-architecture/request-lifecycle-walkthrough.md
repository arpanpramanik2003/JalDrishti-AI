# Request Lifecycle: Irrigation Recommendation Endpoint

> **Audience**: Backend engineers and integration testers. For a farmer-facing narrative of this workflow, see [End-to-End Farmer Journey](../01-concepts-and-workflows/end-to-end-farmer-journey.md).  
> **Route Inspected**: `POST /api/v1/irrigation/recommendation`  
> **Primary File**: [`app/api/v1/endpoints/irrigation.py:100-580`](file:///d:/jaldrishti/jaldrishti-backend/app/api/v1/endpoints/irrigation.py#L100-L580)

---

## 1. End-to-End Sequence Diagram

The following sequence diagram traces the complete execution flow of an incoming irrigation advisory request through the remediated Phase 1–5 backend:

```mermaid
sequenceDiagram
    autonumber
    actor Farmer as Mobile App (Flutter)
    participant Gateway as FastAPI Router (/irrigation/recommendation)
    participant Auth as Security Dependency (get_current_user)
    participant Threadpool as Starlette Threadpool (run_in_threadpool)
    participant DB as Supabase PostgreSQL
    participant Redis as Async CacheService (redis.asyncio)
    participant SoilAPI as ISRIC SoilGrids API
    participant MeteoAPI as Open-Meteo API
    participant Engine as Hydrology Engine (FAO-56 PM & Bucket)

    Farmer->>Gateway: POST /api/v1/irrigation/recommendation (Bearer JWT, PlotPayload)
    
    %% Authentication & Authorization Step (Phase 2 Fix)
    Gateway->>Auth: Depends(get_current_user)
    Auth->>Auth: Verify JWT signature & decode user_id
    Auth-->>Gateway: Authenticated User Object
    
    %% Plot Verification & Ownership Check
    Gateway->>Threadpool: Read FarmPlot record (db.query(FarmPlot))
    Threadpool->>DB: SELECT * FROM farm_plots WHERE id = plot_id
    DB-->>Threadpool: FarmPlot instance
    Threadpool-->>Gateway: Verified Plot Details
    
    %% Dynamic Crop Phenology Evaluation
    Gateway->>Engine: calculate_dynamic_crop_stage(sowing_date, crop_config)
    Engine-->>Gateway: {elapsed_days, current_stage, dynamic_kc, effective_root_depth}
    
    %% Async Soil Profiling (Phase 4 Cache)
    Gateway->>Redis: CacheService.get("soil_grid:lat:lon")
    alt Soil Cache Miss
        Redis-->>Gateway: null
        Gateway->>SoilAPI: HTTPX GET SoilGrids v2.0 REST API
        SoilAPI-->>Gateway: Clay %, Sand %, Bulk Density
        Gateway->>Redis: CacheService.set("soil_grid:lat:lon", data, TTL=30d)
    else Soil Cache Hit
        Redis-->>Gateway: Cached Soil Profile
    end
    
    %% Async Weather Telemetry Fetch (Phase 4 Cache)
    Gateway->>Redis: CacheService.get("weather:lat:lon")
    alt Weather Cache Miss
        Redis-->>Gateway: null
        Gateway->>MeteoAPI: HTTPX GET Open-Meteo API (Daily Forecast + Past Days)
        MeteoAPI-->>Gateway: Weather Telemetry (T_max, T_min, RH, Rs, Wind, Rain)
        Gateway->>Redis: CacheService.set("weather:lat:lon", data, TTL=3h)
    else Weather Cache Hit
        Redis-->>Gateway: Cached Weather Telemetry
    end
    
    %% Threadpool-Offloaded DB Reads (Phase 1 & Phase 4 Fixes)
    Gateway->>Threadpool: Fetch logged irrigations & SoilDepletionState
    Threadpool->>DB: SELECT * FROM irrigation_logs WHERE farm_plot_id = plot_id
    Threadpool->>DB: SELECT * FROM soil_depletion_state WHERE farm_plot_id = plot_id
    DB-->>Threadpool: Irrigation Logs & Depletion Record
    Threadpool-->>Gateway: Depletion Record (D_{i-1}, last_rain_hold_date, skipped_runs)
    
    %% Hydrological Engine Execution
    Gateway->>Engine: PenmanMonteithEngine.calculate_daily_eto(...)
    Engine-->>Gateway: Reference ETo (mm/day)
    Gateway->>Engine: SoilWaterBucketModel.run_daily_water_balance(D_{i-1}, ETc, Rain, LoggedIrrigation)
    Engine-->>Gateway: {current_depletion_mm, raw_threshold_mm, needs_irrigation}
    
    %% Rain Hold & ROI Calculation
    Gateway->>Threadpool: RegionalTariffService.get_tariff_for_plot(location)
    Threadpool->>DB: SELECT * FROM regional_tariffs WHERE state_code = ...
    DB-->>Threadpool: Regional Energy & Carbon Benchmark
    Threadpool-->>Gateway: Tariff Profile
    
    Gateway->>Gateway: Evaluate 24h (>=3mm), 48h (>=5mm), and Today (>=4mm) Rain Hold
    alt Rain Hold Overrides Irrigation
        Gateway->>Threadpool: Increment skipped_runs_count & update last_rain_hold_date
        Threadpool->>DB: UPDATE soil_depletion_state SET skipped_runs_count += 1, ...
        DB-->>Threadpool: OK
        Threadpool-->>Gateway: Updated Counter
    end
    
    %% Persist Today's Depletion State
    Gateway->>Threadpool: Update current_depletion_mm & last_updated_date
    Threadpool->>DB: UPDATE soil_depletion_state SET current_depletion_mm = D_i, ...
    DB-->>Threadpool: OK
    Threadpool-->>Gateway: Commit Successful
    
    %% Return Final Advisory Response
    Gateway-->>Farmer: 200 OK (IrrigationResponse JSON with Multi-Day Forecast & ROI)
```

---

## 2. Step-by-Step Execution Trace with Code Pointers

### Step 1: Authentication & Authorization (Phase 2)
- **Code Pointer**: [`app/api/v1/endpoints/irrigation.py:107`](file:///d:/jaldrishti/jaldrishti-backend/app/api/v1/endpoints/irrigation.py#L107)
- **Action**: Injected dependency `current_user: User = Depends(get_current_user)` parses the `Authorization: Bearer <token>` header, decodes the HS256 JWT signature using `settings.JWT_SECRET_KEY`, and verifies that the account is active. Requests missing or with expired tokens return HTTP `401 Unauthorized` before any hydrological calculation executes.

### Step 2: Ownership Verification & Threadpool Offloading (Phase 4)
- **Code Pointer**: [`app/api/v1/endpoints/irrigation.py:113-125`](file:///d:/jaldrishti/jaldrishti-backend/app/api/v1/endpoints/irrigation.py#L113-L125)
- **Action**: Verifies that the requested `plot_id` belongs to `current_user.id`. To prevent blocking the async event loop during database I/O, the synchronous SQLAlchemy query is wrapped in:
  ```python
  plot = await run_in_threadpool(
      lambda: db.query(FarmPlot).filter(
          FarmPlot.id == payload.plot_id,
          FarmPlot.user_id == current_user.id
      ).first()
  )
  ```

### Step 3: Phenological Stage Calculation
- **Code Pointer**: [`app/engine/water_bucket_model.py:19-132`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/water_bucket_model.py#L19-L132)
- **Action**: Evaluates sowing date versus today's date. If the crop is within active lifecycle, interpolates $K_c(t)$ and root depth $Z_r(t)$. If $t < 0$, early-returns with `crop_lifecycle_status = "NOT_YET_SOWN"`. If $t > L_{\text{total}} + 15$, early-returns with `crop_lifecycle_status = "HARVEST_OVERDUE"`.

### Step 4: Asynchronous Cache-First Data Fetching (Phase 4)
- **SoilGrids Profiling**: [`app/services/soilgrids_service.py:54-138`](file:///d:/jaldrishti/jaldrishti-backend/app/services/soilgrids_service.py#L54-L138) queries Redis with key `soil_grid:{lat}:{lon}` ($0.05^\circ$ grid). On miss, queries ISRIC SoilGrids REST API with circuit-breaker protection and sets a 30-day TTL ($2,592,000\text{ s}$).
- **Open-Meteo Weather**: [`app/services/weather_service.py:23-138`](file:///d:/jaldrishti/jaldrishti-backend/app/services/weather_service.py#L23-L138) queries Redis with key `weather:{lat}:{lon}` ($0.01^\circ$ grid). On miss, queries Open-Meteo daily forecast and sets a 3-hour TTL ($10,800\text{ s}$).

### Step 5: Persistent State Retrieval & Mass Balance (Phase 1)
- **Code Pointer**: [`app/api/v1/endpoints/irrigation.py:262-375`](file:///d:/jaldrishti/jaldrishti-backend/app/api/v1/endpoints/irrigation.py#L262-L375)
- **Action**: Reads `SoilDepletionState` for the plot. If `last_updated_date < today`, uses `current_depletion_mm` as baseline $D_{i-1}$. Executes:
  $$D_i = D_{i-1} - P_{\text{eff}} - I_{\text{applied}} + ET_c$$
  Clamps $D_i \in [0, TAW]$. If $D_i \ge RAW$, flags `needs_irrigation = True`.

### Step 6: Rain Hold Override & ROI Tracking (Phase 1)
- **Code Pointer**: [`app/api/v1/endpoints/irrigation.py:460-555`](file:///d:/jaldrishti/jaldrishti-backend/app/api/v1/endpoints/irrigation.py#L460-L555)
- **Action**: Inspects weather forecast. If $P_{24\text{h}} \ge 3\text{ mm}$ or $P_{48\text{h}} \ge 5\text{ mm}$ or $P_{\text{today}} \ge 4\text{ mm}$:
  - Activates Smart Rain Hold.
  - If irrigation was needed, suppresses `needs_irrigation_today` to `False`.
  - Increments `skipped_runs_count` once per calendar day (gated by `last_rain_hold_date`).
  - Calculates avoided pumping hours, monetary cost savings, and avoided $CO_2$ emissions.

### Step 7: Persistence Commit & JSON Response
- **Code Pointer**: [`app/api/v1/endpoints/irrigation.py:363-375`](file:///d:/jaldrishti/jaldrishti-backend/app/api/v1/endpoints/irrigation.py#L363-L375)
- **Action**: Commits updated $D_i$ and `last_updated_date` to the database via `run_in_threadpool`. Returns the serialized Pydantic `IrrigationResponse` with a 7-day visualization forecast to the client.
