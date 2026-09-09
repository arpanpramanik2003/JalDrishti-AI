# Caching Architecture and Asynchronous I/O Design

> **Audience**: Backend performance engineers, DevOps architects, and site reliability engineers.  
> **Source Modules**:  
> - [`app/services/cache_service.py`](file:///d:/jaldrishti/jaldrishti-backend/app/services/cache_service.py)  
> - [`app/services/weather_service.py`](file:///d:/jaldrishti/jaldrishti-backend/app/services/weather_service.py)  
> - [`app/services/soilgrids_service.py`](file:///d:/jaldrishti/jaldrishti-backend/app/services/soilgrids_service.py)  
> - [`app/services/automated_advisory_cron.py`](file:///d:/jaldrishti/jaldrishti-backend/app/services/automated_advisory_cron.py)  
> **Remediation Provenance**: Phase 4 Optimization ([`PHASE4_CHANGELOG.md`](file:///d:/jaldrishti/PHASE4_CHANGELOG.md)).

---

## 1. Asynchronous Redis Client (`redis.asyncio`)

Prior to Phase 4, the backend executed synchronous `redis.Redis` network calls inside asynchronous FastAPI routes (`async def`). Under high concurrent load, synchronous Redis operations blocked the single Python `asyncio` event loop, degrading throughput.

Phase 4 refactored `CacheService` to utilize `redis.asyncio`:

```python
# app/services/cache_service.py:15-29
@classmethod
async def _get_async_redis(cls):
    """Asynchronous Redis client for non-blocking I/O in async routes."""
    if cls._async_redis_client is None:
        if settings.REDIS_URL:
            try:
                import redis.asyncio as aioredis
                client = aioredis.from_url(
                    settings.REDIS_URL,
                    decode_responses=True,
                    socket_connect_timeout=3,
                    socket_timeout=3
                )
                await client.ping()
                cls._async_redis_client = client
            except Exception as e:
                cls._async_redis_client = False
    return cls._async_redis_client if cls._async_redis_client else None
```

### In-Memory TTL Fallback
To ensure smooth developer onboarding and zero crash risk when Redis Cloud is unreachable or `REDIS_URL` is empty, `CacheService` implements an automatic in-memory dictionary fallback with timestamp expiration:
- Stored as `_memory_cache[key] = (serialized_json, expire_at_epoch)`
- Lookups verify `time.time() < expire_at_epoch`; expired keys are lazily purged on read.

---

## 2. Pragmatic `run_in_threadpool` vs. Full Async-SQLAlchemy Migration

A critical architectural decision documented during the Phase 4 audit was how to handle synchronous database transactions inside asynchronous FastAPI route handlers.

### The Trade-off Analysis
1. **Full Async-SQLAlchemy Migration (`AsyncSession` + `asyncpg`)**:
   - *Pros*: Pure async coroutines throughout the entire call stack.
   - *Cons*: High regression risk across 15+ existing endpoints, models, relationship lazy-loaders, test suites, and Alembic migrations.
2. **FastAPI / Starlette `run_in_threadpool`**:
   - *Pros*: Offloads synchronous SQLAlchemy blocking calls to worker threads via AnyIO's threadpool. The main `asyncio` event loop is immediately liberated to process incoming HTTP requests and external coroutines.
   - *Cons*: Minor thread-context switching overhead, but negligible for typical I/O bound database latencies (< 5 ms).

### Implementation Pattern
All database interactions in `irrigation.py` are wrapped using `await run_in_threadpool`:

```python
# app/api/v1/endpoints/irrigation.py:191-193
logs = await run_in_threadpool(
    lambda: db.query(IrrigationLog).filter(IrrigationLog.farm_plot_id == payload.plot_id).all()
)
```

---

## 3. Cache Keys, TTL Strategy & Spatial Binning

| Telemetry Type | Cache Key Pattern | TTL Duration | Spatial Coordinate Binning | Justification |
|:---------------|:------------------|:-------------|:---------------------------|:--------------|
| **Weather Telemetry** | `weather:{lat}:{lon}` | **3 hours** ($10,800\text{ s}$) | Round to $0.01^\circ$ ($\approx 1.1\text{ km}$) | Captures diurnal temperature and midday convective cloud shifts while shielding Open-Meteo from redundant polling. |
| **Soil Texture Profile** | `soil_grid:{lat}:{lon}` | **30 days** ($2,592,000\text{ s}$) | Round to $0.05^\circ$ ($\approx 5.5\text{ km}$) | Mineral soil composition (clay, sand, silt) does not fluctuate over weeks. Minimizes SoilGrids REST queries across contiguous plots. |

> [!NOTE]
> **Documentation Correction**: Legacy documentation in `docs/05_system_architecture_and_db.md` claimed soil data was cached for only 7 days. Phase 4 corrected the code and docs to 30 days ($2,592,000\text{ s}$), reflecting real agronomic soil stability.

---

## 4. Bounded Concurrency Batching in Background Cron

The morning advisory scheduler ([`app/services/automated_advisory_cron.py`](file:///d:/jaldrishti/jaldrishti-backend/app/services/automated_advisory_cron.py)) scans all registered farm plots, computes disease risks, and sends Firebase push notifications. In earlier versions, this loop ran sequentially per plot, leading to $O(N)$ execution times and socket exhaustion risks.

### Phase 4 Scalability Architecture

1. **Spatial Clustering**:
   Plots are clustered by geographic grid `(round(lat, 2), round(lon, 2))` ([`automated_advisory_cron.py:35-40`](file:///d:/jaldrishti/jaldrishti-backend/app/services/automated_advisory_cron.py#L35-L40)). Plots within the same 1.1 km grid cell share a single cached weather API fetch instead of triggering $N$ external requests.

2. **Bounded Concurrency Semaphore**:
   Push notifications are dispatched concurrently using `asyncio.Semaphore(MAX_CONCURRENT_PUSH)` where `MAX_CONCURRENT_PUSH = 20` ([`automated_advisory_cron.py:42-54`](file:///d:/jaldrishti/jaldrishti-backend/app/services/automated_advisory_cron.py#L42-L54)):
   ```python
   MAX_CONCURRENT_PUSH = 20
   push_semaphore = asyncio.Semaphore(MAX_CONCURRENT_PUSH)

   async def _send_bounded_notification(token: str, title: str, body: str, payload: dict) -> bool:
       async with push_semaphore:
           return await asyncio.to_thread(
               FirebaseService.send_push_notification,
               fcm_token=token,
               title=title,
               body=body,
               data_payload=payload
           )
   ```
   All notifications are gathered concurrently via `await asyncio.gather(*notification_tasks)`, allowing hundreds of farmer notifications to dispatch in seconds without overwhelming network buffers or Firebase rate limits.
