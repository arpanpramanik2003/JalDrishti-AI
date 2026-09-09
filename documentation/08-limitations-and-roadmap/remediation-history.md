# Engineering Remediation History & Audit Traceability Matrix

> **Audience**: Engineering leadership, technical auditors, and system architects.  
> **Purpose**: The definitive single-source-of-truth matrix tracing every finding from the original engineering audit report (`JALDRISHTI_AUDIT_REPORT.md`) through the remediation phases to its verified operational status today.

---

## 1. Remediation Phases Timeline

```
[Phase 1: Hydrology Engine & State Persistence] ──────► Corrected FAO-56 PM, SoilDepletionState, ROI logic
                         │
[Phase 2: Security & Endpoint Hardening] ─────────────► Removed hardcoded keys, added JWT/Admin auth
                         │
[Phase 3: Client-Server Contract Synchronization] ────► Fixed PUT /profile, reset fields, 401 interceptor
                         │
[Phase 4: Async I/O & Performance Architecture] ──────► redis.asyncio, run_in_threadpool, cron batching
                         │
[Phase 5: JalSathi AI RAG Rebuild] ───────────────────► Dense ChromaDB, Groq cascade, zero Gemini
                         │
[Phase 6: Mobile Functional Completeness] ────────────► Name modal wired, AppLocalizations, honest ROI
                         │
[Phase 7A: Concepts & Workflow Documentation] ────────► 00-start-here/ and 01-concepts-and-workflows/
                         │
[Phase 7B: Deep Technical Reference Layer] ───────────► 02-scientific, 03-architecture, 04-database
                         │
[Phase 7C: API, Mobile & RAG Technical Layer] ────────► 05-api, 06-mobile, 07-ai-rag-pipeline
                         │
[Phase 7D: Close-out & Limitations Consolidation] ────► 08-limitations-and-roadmap/ & master README
```

---

## 2. Complete Finding-by-Finding Traceability Matrix

| Finding ID | Domain / Module | Original Audit Finding Description | Target File(s) | Remediation Action Taken | Current Operational Status |
|:-----------|:----------------|:-----------------------------------|:---------------|:-------------------------|:---------------------------|
| **F-01** | Hydrology Engine | Date key type mismatch in `logged_irrigation_map` (`datetime.date` vs `string`). | `app/api/v1/endpoints/irrigation.py` | Normalized both dictionary sides to ISO date strings (`YYYY-MM-DD`). | 🟢 **Fixed (Phase 1)** |
| **F-02** | Hydrology Engine | 3-day transient depletion reset amnesia wiping past moisture deficit. | `app/engine/water_bucket_model.py`, `app/models/farm_plot.py` | Created `SoilDepletionState` database model; persists cumulative depletion across season. | 🟢 **Fixed (Phase 1)** |
| **F-03** | API Contract | Profile update HTTP method mismatch: mobile called `POST`, backend required `PUT`. | `jaldrishti_mobile/lib/core/services/api_service.dart` | Updated mobile client `ApiService.updateProfile` to send HTTP `PUT`. | 🟢 **Fixed (Phase 3)** |
| **F-04** | API Contract | Password reset field mismatch: mobile sent `phone_number`, backend required `phone_or_username`. | `jaldrishti_mobile/lib/core/services/api_service.dart` | Updated mobile client to send required key `'phone_or_username'`. | 🟢 **Fixed (Phase 3)** |
| **F-05** | Security / Auth | Hardcoded administrative secret key `ADMIN_API_KEY` in source code. | `app/core/config.py`, `app/core/security.py` | Removed hardcoded default; enforced fail-fast startup check if unset. | 🟢 **Fixed (Phase 2)** |
| **F-06** | Security / Auth | Unauthenticated `POST /api/v1/crops/pest-advisory` triggering external weather calls. | `app/api/v1/endpoints/crop_info.py` | Injected `Depends(get_current_user)` authentication dependency. | 🟢 **Fixed (Phase 2)** |
| **F-07** | Security / Auth | Unauthenticated `GET /api/v1/admin/tariffs` exposing state economic models. | `app/api/v1/endpoints/admin_tariffs.py` | Injected `Depends(require_admin_api_key)` authorization dependency. | 🟢 **Fixed (Phase 2)** |
| **F-08** | AI / RAG | Dead vector search early-returning naive substring matching on PoP guides. | `app/services/vector_search_service.py` | Rebuilt vector search with ChromaDB 1.5.9 and `all-MiniLM-L6-v2` embeddings. | 🟢 **Fixed (Phase 5)** |
| **F-09** | AI / RAG | Vernacular language search gap: Indic queries failed against English PoP docs. | `app/services/rag_service.py` | Added preliminary Groq translation step (`_translate_query_to_english`). | 🟢 **Fixed (Phase 5)** |
| **F-10** | AI / RAG | Fictitious Google Gemini fallback tier in code and diagrams (no SDK or key). | `app/services/rag_service.py`, `README.md` | Purged all Gemini code; implemented true 3-tier cascade with local deterministic fallback. | 🟢 **Fixed (Phase 5)** |
| **F-11** | Hydrology Engine | FAO-56 wind speed height discrepancy: 10m satellite wind used directly instead of 2m. | `app/engine/penman_monteith.py` | Implemented logarithmic wind profile conversion (FAO-56 Eq. 47). | 🟢 **Fixed (Phase 1)** |
| **F-12** | Hydrology Engine | Late-season $K_c$ curve static snap to hardcoded 0.75 regardless of crop. | `app/engine/water_bucket_model.py` | Implemented continuous linear decay from $K_{c,\text{mid}}$ to $K_{c,\text{end}}$. | 🟢 **Fixed (Phase 1)** |
| **F-13** | Hydrology Engine | Missing crop boundary states: runaway loops on future sowing or post-harvest. | `app/engine/water_bucket_model.py` | Added explicit `NOT_YET_SOWN` and `HARVEST_OVERDUE` boundary handlers. | 🟢 **Fixed (Phase 1)** |
| **F-14** | ROI Engine | Arbitrary $+3$ and $+4$ skipped runs offsets inflating reported farmer savings. | `app/api/v1/endpoints/irrigation.py` | Removed artificial offsets; increment `skipped_runs_count` strictly on real Rain Hold overrides. | 🟢 **Fixed (Phase 1)** |
| **F-15** | Async / Performance | Synchronous Redis and SQLAlchemy calls blocking the single asyncio event loop. | `app/services/cache_service.py`, `app/api/v1/endpoints/irrigation.py` | Upgraded to `redis.asyncio` and offloaded DB calls via `run_in_threadpool`. | 🟢 **Fixed (Phase 4)** |
| **F-16** | Documentation Drift | Stale soil cache TTL documentation claiming 7 days instead of 30 days. | `docs/05_system_architecture_and_db.md` | Aligned documentation and verified 30-day ($2,592,000\text{ s}$) Redis TTL. | 🟢 **Fixed (Phase 4 / 7B)** |
| **F-17** | Documentation Drift | SoilGrids coordinate binning documentation claiming 250m precision. | `docs/02_hydrology_engine.md` | Documented actual $0.05^\circ$ (~5.5 km) coordinate binning in `documentation/`. | 🟢 **Fixed (Phase 7B)** |
| **F-18** | Mobile Client | Dead "Update Name" modal in `settings_screen.dart` showing fake success SnackBar. | `jaldrishti_mobile/lib/screens/settings_screen.dart` | Wired modal to `AuthProvider.updateProfile()` sending `PUT /api/v1/auth/profile`. | 🟢 **Fixed (Phase 6)** |
| **F-19** | Mobile Client | Dead localization architecture (`AppLocalizations.delegate` omitted from `MaterialApp`). | `jaldrishti_mobile/lib/main.dart`, `theme_provider.dart` | Wired delegates, connected `ThemeProvider.setLocale()`, audited ARB keys. | 🟡 **Partially Mitigated (Phase 6 / 7C)** |
| **F-20** | Mobile Client | Missing centralized 401 interceptor causing unhandled session expiration drops. | `jaldrishti_mobile/lib/core/services/api_service.dart` | Added centralized 401 interceptor with silent refresh and forced logout. | 🟢 **Fixed (Phase 3)** |
| **F-21** | Documentation Drift | Legacy ERD diagram missing 4 tables (`password_resets`, `regional_tariffs`, chat tables). | `docs/05_system_architecture_and_db.md` | Built comprehensive 9-table Mermaid ERD in `documentation/04-database-reference/`. | 🟢 **Fixed (Phase 7B)** |
| **F-22** | AI / RAG | Hallucination risk: LLM generating ungrounded chemical names and dosages. | `app/services/rag_service.py` | Rewrote grounding prompt; added `_verify_and_guard_chemicals` active ingredient check. | 🟡 **Partially Mitigated (Phase 5 / 7C)** |
| **F-23** | Mobile Client | Fabricated mock statistics (`?? 45000.0`) displayed in `SmartInsightsTab`. | `jaldrishti_mobile/lib/screens/analytics/smart_insights_tab.dart` | Replaced mock values with honest loading and calm zero-state (`0 kL saved (₹0)`). | 🟢 **Fixed (Phase 6)** |
| **5.2** | Performance | Redundant database queries for `IrrigationLog` inside recommendation handler. | `app/api/v1/endpoints/irrigation.py` | Consolidated into a single query mapped to memory and reused throughout route. | 🟢 **Fixed (Phase 4)** |
| **5.3** | Scalability | Sequential per-plot notification loop in `automated_advisory_cron.py`. | `app/services/automated_advisory_cron.py` | Converted to bounded concurrency batch using `asyncio.Semaphore(20)`. | 🟢 **Fixed (Phase 4)** |
| **6.3** | Ground Truth | No physical empirical ground-truthing of hydrology engine against field sensors. | `app/engine/penman_monteith.py` | Documented transparently as a known limitation; retracted false sensor claims. | 🔴 **Documented Limitation / Open** |
| **6.4** | Hydrology Model | Static 5mm/48h Rain Hold threshold not dynamically weighted by soil water deficit. | `app/core/constants.py` | Documented transparently as a fixed heuristic; proposed dynamic formula in roadmap. | 🔴 **Documented Limitation / Open** |
| **FLAG-P4-01** | Mobile Sync | Offline sync queue serializes ISO-8601 timestamp rather than calendar date. | `jaldrishti_mobile/lib/core/services/offline_sync_manager.dart` | Coerced by FastAPI Pydantic parser, but flagged for explicit date string formatting. | 🟡 **Partially Mitigated / Open** |
| **Outage-01** | Resilience / Safety | Satellite API outage fallback generates `precipitation_mm = 0.0` during active rain. | `app/services/weather_service.py` | Untouched across all code phases. Flagged as the primary safety-critical open risk. | 🔴 **UNRESOLVED / Open Safety Risk** |
