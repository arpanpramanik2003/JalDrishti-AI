# JalDrishti Phase 4 Changelog: Asynchronous I/O & Performance Optimization

**Phase**: Phase 4 (Async/Performance Architecture & Concurrency Scaling)  
**Date**: September 9, 2026  
**Status**: COMPLETE  
**Specialist Roles**: Backend Architect (`agency-backend-architect`) & Performance Benchmarker (`agency-performance-benchmarker`)  
**Testing Framework**: Pytest 9.1.1 + AnyIO + FastAPI TestClient (44 backend tests passing)  

---

## 1. Executive Summary

Phase 4 eliminated critical event-loop blocking I/O and query bottlenecks across the JalDrishti backend without altering calculation formulas, database schemas, or API contracts. Specifically:
1. **[F-15] Synchronous Redis in Async Routes Refactored to `redis.asyncio`**: Upgraded `CacheService` to use `redis.asyncio.Redis` with true coroutine methods (`async def get()`, `async def set()`, `async def delete()`). Updated callers (`weather_service.py`, `soilgrids_service.py`) to `await` them, while maintaining in-memory fallback.
2. **[F-15] Synchronous DB Calls in Async Routes Offloaded to Worker Threadpool**: Wrapped all blocking SQLAlchemy calls in `irrigation.py`'s `get_irrigation_recommendation` (`FarmPlot`, `IrrigationLog`, `SoilDepletionState` reads/inserts/commits, and `RegionalTariffService`) using `await run_in_threadpool(...)`.
3. **[5.2] Redundant Query Consolidation**: Audited and confirmed single-query execution for `IrrigationLog` with ISO date-string mapped caching, passed seamlessly to depletion balance and ROI accounting.
4. **[F-17] Cache TTL Documentation Drift Corrected**: Aligned `docs/05_system_architecture_and_db.md` to reflect the defensible 30-day (2,592,000s) satellite soil cache TTL and `soil_grid:{lat}:{lon}` key pattern.
5. **[5.3] Batch Scheduler Scalability (Bounded Concurrency)**: Converted the sequential per-plot push notification loop in `automated_advisory_cron.py` into a bounded-concurrency batch using `asyncio.Semaphore(20)` and `asyncio.gather`.

---

## 2. Architectural Design Decisions & Technical Reasoning

### Decision: Pragmatic `run_in_threadpool` vs Async SQLAlchemy Migration
- **Context**: The backend uses synchronous SQLAlchemy (`create_engine`, `sessionmaker`, `SessionLocal`, `get_db`) across all models and endpoints.
- **Analysis**: Migrating to `AsyncSession` with `asyncpg` or `aiosqlite` would require altering `database.py`, models, relationships, and all 15+ route handlers across Phases 1–3, introducing major regression risks.
- **Resolution**: Utilized Starlette/FastAPI's built-in `await run_in_threadpool(func, *args)`. This executes blocking synchronous SQLAlchemy queries inside AnyIO's threadpool worker pool, releasing the asyncio event loop immediately to handle concurrent HTTP requests without blocking.
- **Security Dependency Compatibility**: Retained synchronous `CacheService._get_redis()` for legacy sync dependencies (e.g. `get_current_user` in `security.py` checking token revocation blacklist).

---

## 3. Detailed Code Modifications by File

### 1. `app/services/cache_service.py`
- Added `_async_redis_client = None` and `_get_async_redis(cls)` returning an instance of `redis.asyncio.Redis.from_url`.
- Refactored `get(cls, key: str)`, `set(cls, key: str, value: Any, expire_seconds: int = 10800)`, and `delete(cls, key: str)` to `async def`.
- Modernized Redis command in `set()`: replaced deprecated `r.setex` with `await r.set(key, serialized, ex=expire_seconds)`.
- Maintained in-memory dictionary fallback with TTL expiration for offline/unreachable Redis environments.
- Added `get_sync` and `set_sync` helper methods for synchronous service routines.

```python
# app/services/cache_service.py
@classmethod
async def get(cls, key: str) -> Optional[Any]:
    r = await cls._get_async_redis()
    if r:
        try:
            val = await r.get(key)
            if val:
                return json.loads(val)
        except Exception as e:
            logger.warning(f"[CacheService] Async Redis GET error for '{key}' ({e}). Resetting pool.")
            cls._async_redis_client = None
    ...
```

### 2. `app/services/weather_service.py`
- Updated `fetch_realtime_weather`:
  - `cached_data = await CacheService.get(cache_key)`
  - `await CacheService.delete(cache_key)` (on legacy WeatherAPI busting)
  - `await CacheService.set(cache_key, result, expire_seconds=10800)`

### 3. `app/services/soilgrids_service.py`
- Updated `fetch_soil_profile`:
  - `cached_data = await CacheService.get(cache_key)`
  - `await CacheService.set(cache_key, result, expire_seconds=2592000)`

### 4. `app/api/v1/endpoints/irrigation.py`
- Imported `from starlette.concurrency import run_in_threadpool`.
- Wrapped all database operations in `get_irrigation_recommendation`:
  - `plot = await run_in_threadpool(lambda: db.query(FarmPlot).filter(...).first())`
  - `logs = await run_in_threadpool(lambda: db.query(IrrigationLog).filter(...).all())`
  - `depletion_record = await run_in_threadpool(lambda: db.query(SoilDepletionState).filter(...).first())`
  - Initial `SoilDepletionState` insertion: `await run_in_threadpool(_save_initial_depletion, depletion_record)`
  - Today's depletion update: `await run_in_threadpool(_save_today_depletion, depletion_record, today_decision["current_depletion_mm"], today_obj)`
  - Regional tariff lookup: `regional_profile = await run_in_threadpool(RegionalTariffService.get_tariff_for_plot, ...)`
  - Rain hold skipped runs commit: `await run_in_threadpool(_update_rain_hold_skipped, depletion_record, today_obj)`

### 5. `app/services/automated_advisory_cron.py`
- Replaced sequential loop with bounded concurrency:
  - Created `asyncio.Semaphore(20)`.
  - Defined `_send_bounded_notification` helper wrapping `asyncio.to_thread(FirebaseService.send_push_notification, ...)`.
  - Accumulated advisory alerts into `notification_tasks` and executed concurrently via `await asyncio.gather(*notification_tasks, return_exceptions=True)`.

### 6. `docs/05_system_architecture_and_db.md`
- Updated Soil Cache TTL table entry on line 132:
  - Pattern: `soil_grid:{lat_2dec}:{lon_2dec}`
  - TTL Duration: `2592000 sec` ($30\text{ Days}$)
  - Preserved weather cache at `10800 sec` (3 Hours) and RAG cache at `86400 sec` (24 Hours).

---

## 4. Performance & Latency Benchmark Analysis

### Qualitative & Quantitative Event-Loop Latency Analysis
| Hotspot / Operation | Pre-Optimization (Blocking) | Post-Optimization (Non-Blocking) | Theoretical / Measured Throughput Impact |
| :--- | :--- | :--- | :--- |
| **Redis Cache Calls** in `WeatherService` / `SoilGridsService` | Synchronous socket I/O (blocked event loop for ~15–50ms per request, or 3,000ms on timeout). | `redis.asyncio` with coroutine `await` (yields loop immediately during socket I/O). | Event loop concurrency unlocked; 0ms main thread blocking on cache hits/misses. |
| **Database Operations** in `/irrigation/recommendation` | 6 synchronous SQLite/PostgreSQL blocking queries & commits in `async def` handler (~10–30ms total blocking). | Offloaded to AnyIO threadpool via `await run_in_threadpool(...)`. | Event loop never halts for disk/database I/O; concurrent requests process in parallel. |
| **Push Notification Dispatch** in `automated_advisory_cron` | Sequential blocking calls: $O(N)$ execution time. 1,000 notifications @ ~150ms = **150 seconds**. | Bounded concurrency with `asyncio.Semaphore(20)` + `asyncio.gather`. | 1,000 notifications @ ~150ms with 20 parallel workers = **~7.5 seconds** (**~20x speedup**). |

---

## 5. Automated Verification Evidence

### Phase 4 Performance Test Suite (`tests/test_async_performance.py`)
```bash
$ pytest tests/test_async_performance.py -v
tests/test_async_performance.py::test_async_cache_service_contract[asyncio] PASSED [ 50%]
tests/test_async_performance.py::test_automated_advisory_batch_bounded_concurrency[asyncio] PASSED [100%]
======================== 2 passed in 4.64s =========================
```

### Phase 3 API Contract Regression (`tests/test_contract_integration.py`)
```bash
$ pytest tests/test_contract_integration.py -v
tests/test_contract_integration.py::test_profile_update_contract_f03 PASSED [ 33%]
tests/test_contract_integration.py::test_password_reset_contract_f04 PASSED [ 66%]
tests/test_contract_integration.py::test_token_expiry_and_refresh_flow_f20 PASSED [100%]
======================= 3 passed in 52.65s =======================
```

### Full Backend Regression Suite (All Phases 1–4)
```bash
$ pytest -q
............................................                             [100%]
======================= 44 passed in 218.05s (0:03:38) =======================
```

**Conclusion**: All Phase 4 async and performance refactoring goals have been achieved. The entire test suite (44 tests) passes cleanly with 0 regressions, preserving all hydrology formulas, ROI accounting, and security contracts.
