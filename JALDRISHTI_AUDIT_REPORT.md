# JalDrishti Audit Report

**Audit Conducted**: March 2026  
**Audited Targets**: `jaldrishti-backend/`, `jaldrishti_mobile/`, `docs/`, `README.md`, `MASTER_PROJECT_DOCUMENTATION.md`  
**Participating Specialist Agents**: `agency-backend-architect`, `agency-mobile-app-builder`, `agency-api-tester`, `agency-performance-benchmarker`, `agency-prompt-engineer`, `agency-ai-engineer`, `agency-technical-writer`  
**Scope**: Full Engineering Rigor, Mathematical Derivation, Integration Reality Check, and Architectural Validity.

---

## 1. Executive Summary

- **Transient Soil Water Model with Total Historical Amnesia**: The daily water balance engine does not persist soil moisture state. Every invocation of `POST /api/v1/irrigation/recommendation` recalculates soil depletion across a narrow 7-day transient window (`past_days=3`, `forecast_days=3`) and forcibly initializes depletion $D_{i-3} = 0.0$ (`irrigation.py:171`). If a crop was planted 60 days ago without irrigation, the system assumes the soil was at 100% field capacity exactly 3 days ago, discarding all prior crop water depletion history.
- **RAG Semantic Vector Search is Bypassed with Dead Code**: The documented "ChromaDB + HuggingFace MiniLM embeddings" architecture does not exist in production. ChromaDB is never imported or queried anywhere in the backend codebase (`vector_search_service.py`). The retrieval method executes an early `return` on line 145 with a naive substring keyword check against raw English `.txt` files, rendering all NumPy/cosine vector math on lines 147–174 unreachable dead code. Furthermore, non-English (Bengali/Hindi) queries match zero English keywords, yielding an empty context list (`[]`) and breaking multilingual RAG.
- **Silent Type-Mismatch Bug Disables Logged Irrigation Accounting**: When a farmer logs applied irrigation water (`IrrigationLog.applied_date` stored as a SQLAlchemy `Date` object), the recommendation engine indexes the lookup map with `date` keys (`irrigation.py:167`), but queries it with string dates (`date_str`, e.g. `"2026-09-08"`) on line 187. On PostgreSQL/Supabase, `logged_irrigation_map.get("2026-09-08", 0.0)` always returns `0.0`, silently ignoring all farmer irrigation logs during water balance computation.
- **Broken Client-Server API Contracts Block Core Flows**: 
  - The Mobile Client attempts to update farmer profiles via `POST /api/v1/auth/profile` (`api_service.dart:165`), but the backend router strictly declares `PUT /api/v1/auth/profile` (`auth.py:235`), triggering HTTP 405 Method Not Allowed and blocking onboarding survey completion.
  - The Mobile Client sends `{"phone_number": ...}` for password resets (`api_service.dart:125, 135`), but FastAPI Pydantic schemas require `phone_or_username` (`user_schema.py:30, 40`), causing HTTP 422 Unprocessable Entity failures on password recovery.
- **Hardcoded Secret Key and Missing Endpoint Authentication**: The administrative secret key `ADMIN_API_KEY` is hardcoded in source code (`config.py:31` as `"jaldrishti_admin_secret_key_2026_prod"`). The pest advisory endpoint `POST /api/v1/crops/pest-advisory` (`crop_info.py:28`) and tariff inspection endpoint `GET /api/v1/admin/tariffs` (`admin_tariffs.py:20`) lack all authentication dependency injection, leaving them publicly accessible without token verification.
- **Fabricated Scientific Sensor Accuracy & Resolution Claims**: The documentation claims "$\ge 85\%$ accuracy comparable to physical sensors" (`MASTER_PROJECT_DOCUMENTATION.md:442`), yet the repository contains zero empirical ground-truth datasets, zero calibration curves, and zero sensor comparison code. Additionally, while claiming 250m ISRIC SoilGrids precision, the backend coarsens coordinates to a $0.05^\circ \approx 5.5\text{ km} \times 5.5\text{ km}$ ($30.25\text{ km}^2$) grid cell (`soilgrids_service.py:58`), assigning identical soil texture to thousands of distinct smallholder plots.
- **Complete Absence of Gemini AI and Fictitious Fallback Cascade**: Both the documentation and architectural specifications advertise a "Groq $\rightarrow$ Gemini $\rightarrow$ Local fallback chain". In reality, the Google Gemini SDK (`google-generativeai`) is not in `requirements.txt`, is never imported, and appears in zero backend files. The Groq engine iterates only through alternate Groq model names (`rag_service.py:251`).
- **Synchronous Redis and Database Calls Inside Async FastAPI Routes**: Synchronous calls (`redis.Redis` and SQLAlchemy `db.query()`) are executed directly within asynchronous route handlers (`irrigation.py:97`, `cache_service.py:44`, `soilgrids_service.py:48`), blocking the single-threaded asyncio event loop during network round-trips and severely degrading concurrency under multi-farmer load.
- **Inverted ROI Logic & Synthetic Offset Fabrications**: The documentation specifies synthetic magic offsets ($N_{\text{total}} = N_{\text{skipped}} + 4$ and $V_{\text{cum}} \propto (N_{\text{skipped}} + 3)$ in `03_smart_rain_hold_and_roi.md:90, 106`). The code implementation replaces this with an inverted formula (`irrigation.py:308`) where each *applied* irrigation log increments `session_count`, meaning logging that you ran your pump actually *increases* reported "skipped" runs and money saved.
- **Frontend Multilingual Localization is Dead Code**: Despite extensive `.arb` translation files in `lib/l10n/`, `AppLocalizations.delegate` is excluded from `MaterialApp` in `main.dart:60`, and `AppLocalizations.of(context)` is never invoked in any UI screen. All text is hardcoded English, and language selection in `SettingsScreen` explicitly marks Bengali and Hindi as "Coming Soon" (`settings_screen.dart:425, 431`).

---

## 2. Findings Table

| # | Area | File(s):Line(s) | Severity | Category | Description | Evidence |
|---|------|-----------------|----------|----------|-------------|----------|
| **F-01** | Hydrology / DB | `app/api/v1/endpoints/irrigation.py:164-188` | **Critical** | Bug | Irrigation log lookup dictionary keyed by `datetime.date` object but queried with `str` (`date_str`), returning `0.0` applied water on Postgres. | `logged_irrigation_map[log.applied_date] = ...`<br/>`applied_water = logged_irrigation_map.get(date_str, 0.0)` |
| **F-02** | Hydrology | `app/api/v1/endpoints/irrigation.py:171-198` | **Critical** | Conceptual | Water balance model resets depletion to 0.0 at Day -3, creating complete historical amnesia and invalidating crop water balance. | `current_depletion = 0.0`<br/>Loops only over 7-day Open-Meteo weather response (`past_days=3`). |
| **F-03** | Mobile / Auth | `jaldrishti_mobile/lib/core/services/api_service.dart:165`<br/>`app/api/v1/endpoints/auth.py:235` | **Critical** | Bug / Integration | Profile update sends HTTP `POST` instead of HTTP `PUT`, triggering HTTP 405 Method Not Allowed and breaking onboarding survey completion. | Dart: `_sendRequest('POST', ApiConstants.updateProfileEndpoint...)`<br/>Python: `@router.put("/profile", ...)` |
| **F-04** | Mobile / Auth | `jaldrishti_mobile/lib/core/services/api_service.dart:125, 135`<br/>`app/schemas/user_schema.py:30, 40` | **Critical** | Bug / Integration | Password reset requests pass `phone_number` instead of `phone_or_username`, triggering HTTP 422 validation failure. | Dart: `'phone_number': phoneNumber`<br/>FastAPI: `phone_or_username: str = Field(...)` |
| **F-05** | Security | `app/core/config.py:31` | **High** | Security | Administrative API key is hardcoded with a default production string in source control. | `ADMIN_API_KEY: str = "jaldrishti_admin_secret_key_2026_prod"` |
| **F-06** | Security | `app/api/v1/endpoints/crop_info.py:28` | **High** | Security | Pest advisory endpoint lacks authentication dependency injection; exposes satellite fetching publicly. | `async def get_weather_pest_advisory(payload: PestAdvisoryRequest):` without `Depends(get_current_user)` |
| **F-07** | Security | `app/api/v1/endpoints/admin_tariffs.py:20` | **Medium** | Security | Listing all state tariffs is unauthenticated, exposing economic configurations publicly. | `def list_all_regional_tariffs(db: Session = Depends(get_db)):` without admin guard |
| **F-08** | AI / RAG | `app/services/vector_search_service.py:122-174` | **Critical** | Dead Code / Missing Integration | ChromaDB is never used. Vector search early returns on line 145 with naive string matching; embedding math is unreachable dead code. | Line 145: `return [{'content': content, ...}]`<br/>Lines 147-174: unreachable NumPy cosine similarity code. |
| **F-09** | AI / RAG | `app/services/rag_service.py:198-203` | **High** | Bug / Conceptual | Multilingual queries in Bengali/Hindi fail keyword match against English docs, returning empty context (`[]`) and breaking multilingual RAG. | `matches = sum(1 for word in query_words if ... word in content_lower)` against English PoP texts. |
| **F-10** | AI / Infrastructure | `jaldrishti-backend/requirements.txt`<br/>`app/services/rag_service.py:251` | **High** | Missing Integration | Gemini AI model integration is completely absent from codebase despite explicit documentation claims. | Zero occurrences of `google.generativeai` or `gemini` in entire backend repository. |
| **F-11** | Hydrology | `app/engine/penman_monteith.py:18, 89-92`<br/>`app/services/weather_service.py:99` | **Medium** | Bug / Science | Uses daily maximum wind speed at 10m (`wind_speed_10m_max`) without converting to 2m height via FAO-56 logarithmic profile, overestimating $ET_0$. | `wind_speed_m_s = daily["wind_speed_10m_max"][idx] / 3.6`<br/>Missing $u_2 = u_{10} \frac{4.87}{\ln(678 - 5.42)}$. |
| **F-12** | Hydrology | `app/engine/water_bucket_model.py:46-51` | **Medium** | Bug / Science | Crop coefficient $K_c(t)$ late-season stage has no linear decay interpolation to harvest; stays permanently at 0.75 even years past harvest. | Code jumps to `kc = 0.75` immediately; no elapsed days check beyond total crop duration. |
| **F-13** | Hydrology | `app/engine/water_bucket_model.py:18` | **Low** | Conceptual | Future sowing date clamped to 0 elapsed days, recommending germination irrigation immediately before planting. | `elapsed_days = max(0, (today - sowing_date).days)` |
| **F-14** | ROI Engine | `app/api/v1/endpoints/irrigation.py:307-328`<br/>`docs/03_smart_rain_hold_and_roi.md:90, 106` | **High** | Conceptual / Bug | ROI formula in code increments "skipped runs" whenever irrigation is *applied*, inverting logic; docs invent arbitrary `+3` and `+4` offsets. | Code: `session_count = max(1, total_logs_count + ...)`<br/>Doc: $V_{\text{cum}} \propto (N_{\text{skipped}} + 3)$. |
| **F-15** | Performance | `app/services/cache_service.py:18-52`<br/>`app/api/v1/endpoints/irrigation.py:97` | **High** | Performance | Synchronous Redis and SQLAlchemy operations executed inside `async def` routes, blocking the asyncio main thread. | Synchronous `redis.Redis.get()` and `db.query()` called directly inside `async def` route handlers. |
| **F-16** | Infrastructure | `app/services/soilgrids_service.py:58-60`<br/>`docs/02_penman_monteith_hydrology.md:38` | **Medium** | Conceptual | SoilGrids 250m resolution claim is coarsened in code to 5.5 km ($30.25\text{ km}^2$), defeating field-level specificity. | `grid_lat = round(round(lat * 20) / 20.0, 2)` ($0.05^\circ$ binning). |
| **F-17** | Performance | `app/services/soilgrids_service.py:124`<br/>`docs/05_system_architecture_and_db.md:132` | **Low** | Documentation Drift | Soil cache TTL in code is 30 days (2,592,000s), but documentation specifies 7 days (604,800s). | `CacheService.set(cache_key, result, expire_seconds=2592000)` |
| **F-18** | Mobile | `jaldrishti_mobile/lib/screens/settings_screen.dart:81-89` | **Medium** | Dead Code / Stub | "Update Full Name" modal in Settings does not invoke any API or Provider method; closes and shows a fake success SnackBar. | `onPressed: () { Navigator.pop(ctx); ScaffoldMessenger.of(...)... }` |
| **F-19** | Mobile | `jaldrishti_mobile/lib/main.dart:60-69`<br/>`jaldrishti_mobile/lib/screens/settings_screen.dart:425, 431` | **Medium** | Missing Integration | App localization delegate is missing in `main.dart`, all UI screens are hardcoded English, and language selection displays "Coming Soon". | `AppLocalizations.delegate` omitted from `localizationsDelegates`; zero calls to `AppLocalizations.of(context)`. |
| **F-20** | Mobile / State | `jaldrishti_mobile/lib/core/services/api_service.dart:71-76`<br/>`jaldrishti_mobile/lib/providers/auth_provider.dart:79` | **High** | Bug / Architecture | No 401 interceptor or automatic token refresh on active user requests; app throws errors on token expiration until app restart. | `_sendRequest` re-throws `ApiException(401, ...)` without calling `refreshSession()`. |
| **F-21** | Architecture / DB | `docs/05_system_architecture_and_db.md:64-114`<br/>`app/models/user.py:1-40` | **Medium** | Documentation Drift | DB ERD documents `email` on `users` and `state`/`district` on `user_profiles` which do not exist in SQLAlchemy models. | Code uses `phone_number` on `User` and `location_name` on `UserProfile`. |
| **F-22** | AI / Prompt | `app/services/rag_service.py:208-228` | **Medium** | Prompt Engineering | Prompt lacks grounding instructions and citation requirements; explicitly asks for chemical dosage even when missing from retrieved context. | `"Exact chemical dosage per acre (e.g. Cartap 4G @ 10 kg/acre)"` in schema prompt without grounding constraint. |
| **F-23** | Mobile | `jaldrishti_mobile/lib/screens/analytics/smart_insights_tab.dart:40-43` | **Low** | Mock / Fallback | Smart Insights tab falls back to hardcoded numbers (45,000 L, ₹850, 29.8 kg CO2) when backend cumulative savings are null. | `(cumSavings?['total_water_saved_liters'] as num?)?.toDouble() ?? 45000.0` |

---

## 3. Detailed Findings by Phase

### Phase 1 — Backend Scientific & Logical Correctness
*(Domain: `agency-backend-architect`)*

#### 1.1 Penman-Monteith Derivation (`app/engine/penman_monteith.py`)
- **Atmospheric Pressure & Psychrometric Constant** (Lines 44–47): Follows FAO-56 Eq. 7 and 8 exactly:
  $$P = 101.3 \times \left(\frac{293 - 0.0065 z}{293}\right)^{5.26}, \quad \gamma = 0.000665 P$$
- **Saturation & Actual Vapor Pressure** (Lines 50–58): Correctly uses Tetens equation (FAO-56 Eq. 11, 12, 13) for $\Delta$, $e^0(T_{\text{max}})$, and $e^0(T_{\text{min}})$. Mean $e_s$ is properly computed as $(e(T_{\text{max}}) + e(T_{\text{min}}))/2$. $e_a$ is estimated via mean relative humidity: $e_a = \frac{\text{RH}}{100} e_s$ (FAO-56 Eq. 19).
- **Radiation Components** (Lines 60–83): 
  - Net shortwave radiation $R_{\text{ns}} = 0.77 R_s$ conforms to FAO-56 Eq. 38 for albedo $\alpha = 0.23$.
  - Extraterrestrial radiation ($R_a$, Eq. 21) and clear-sky radiation ($R_{\text{so}}$, Eq. 37) are derived through solar declination $\delta$, relative Earth-Sun distance $d_r$, and sunset hour angle $\omega_s$.
  - Net longwave radiation ($R_{\text{nl}}$, Eq. 39) implements the full Stefan-Boltzmann formulation with $\sigma = 4.903 \times 10^{-9}\text{ MJ K}^{-4}\text{ m}^{-2}\text{ day}^{-1}$, vapor pressure correction $(0.34 - 0.14\sqrt{e_a})$, and cloudiness factor $(1.35 \frac{R_s}{R_{\text{so}}} - 0.35)$.
  - *Documentation Conflict*: `docs/02_penman_monteith_hydrology.md` line 72 states a simplified approximation $R_{\text{nl}} = 0.10 R_s$. The code actually implements the rigorous Stefan-Boltzmann calculation, making the code mathematically superior to its documentation summary.
- **Wind Speed Measurement Height Error** [F-11]:
  In `app/services/weather_service.py` line 99, wind speed is extracted from Open-Meteo as `wind_speed_10m_max` and divided by 3.6 to convert km/h to m/s. FAO-56 Penman-Monteith (Eq. 6) strictly requires wind speed measured at **2 meters** height ($u_2$). Per FAO-56 Eq. 47, converting wind from 10m to 2m requires:
  $$u_2 = u_{10} \frac{4.87}{\ln(67.8 \times 10 - 5.42)} \approx 0.748 \times u_{10}$$
  The engine uses $u_{10}$ directly without the $0.748$ damping factor, and further uses peak daily gust (`max`) rather than daily mean wind speed. This compounds into a 25%–50% artificial inflation of the aerodynamic drying term $\gamma \frac{900}{T+273} u_2 (e_s - e_a)$, leading to systematic over-prediction of reference evapotranspiration ($ET_0$).
- **Soil Heat Flux ($G = 0.0$)** (Line 86):
  Setting $G = 0.0$ is scientifically valid per FAO-56 Chapter 3 (Eq. 42) for **daily operational timesteps**, because diurnal soil heat gains balance nighttime losses ($G_{\text{day}} \approx 0$). However, this assumption strictly breaks if the codebase is ever transitioned to hourly scheduling, where $G_{\text{hr}} = 0.1 R_n$ (day) and $0.5 R_n$ (night).

#### 1.2 Dynamic $K_c(t)$ Interpolation (`app/engine/water_bucket_model.py`)
- **Initial & Vegetative Stages** (Lines 28–41): Correctly applies linear interpolation between $K_{c,\text{ini}}$ and $K_{c,\text{mid}}$ based on elapsed days. Root depth expansion $Z_r(t)$ expands linearly from $0.30 Z_{r,\text{max}}$ to $Z_{r,\text{max}}$.
- **Late Season Omission** [F-12]:
  `docs/02_penman_monteith_hydrology.md` line 128 explicitly documents a linear decay formula for late-season ripening:
  $$K_c = K_{c,\text{mid}} + \text{Progress} \times (K_{c,\text{end}} - K_{c,\text{mid}})$$
  In `water_bucket_model.py` lines 46–51, this interpolation is completely missing. Once `elapsed_days > init_days + dev_days + mid_days`, the code immediately snaps to a static constant `stages.get("late_season", {}).get("Kc", 0.75)`.
- **Lack of Cycle Clamping & Post-Harvest Runaway** [F-12, F-13]:
  If a farmer registers a sowing date in the future, line 18 clamps `elapsed_days = max(0, negative_days) = 0`, immediately advising germination watering today. Conversely, if `elapsed_days` exceeds the entire crop lifecycle (e.g. Day 180 on a 120-day paddy crop), the engine permanently outputs `"Late Season (Ripening/Maturity)"` with $K_c = 0.75$ and $Z_r = Z_{r,\text{max}}$ indefinitely, never terminating or notifying the farmer of harvest.

#### 1.3 Soil Bucket Mass Balance & Transient Window Defect (`app/api/v1/endpoints/irrigation.py`)
- **Depletion Clamping** (`water_bucket_model.py:84`):
  Depletion $D_i$ is properly bounded: `current_depletion = max(0.0, min(taw_mm, current_depletion))`. It cannot grow unbounded negative or exceed $TAW$.
- **Transient Window Historical Amnesia** [F-02]:
  In `irrigation.py` line 171, prior to processing daily hydrological balance, the engine initializes `current_depletion = 0.0`. It then iterates strictly over the dates returned by `WeatherService.fetch_realtime_weather(..., past_days=3, forecast_days=3)`.
  *Agronomic Consequence*: The mass-balance equation $D_i = D_{i-1} + ET_c - P_{\text{eff}} - I$ is a cumulative state variable. By forcing $D_{t-3} = 0.0$, the engine implicitly assumes that the farmer's plot was saturated to Field Capacity ($D = 0$) exactly 72 hours ago, completely erasing the preceding weeks or months of cumulative depletion. If a crop received zero rainfall for 30 days, the model acts as if the soil dried only over the last 3 days.

#### 1.4 Silent Irrigation Log Type Mismatch (`app/api/v1/endpoints/irrigation.py`) [F-01]
- In `app/models/farm_plot.py` line 42, `IrrigationLog.applied_date` is declared as `Column(Date, nullable=False)`.
- When retrieved via SQLAlchemy on line 165, `log.applied_date` is a Python `datetime.date` object (e.g. `date(2026, 9, 8)`).
- Line 167 populates the lookup dictionary: `logged_irrigation_map[log.applied_date] = ...`. The dictionary key is of type `date`.
- Line 187 attempts to retrieve applied water using `date_str`, which is a string from Open-Meteo (e.g. `"2026-09-08"`):
  `applied_water = logged_irrigation_map.get(date_str, 0.0)`
- In Python, `date(2026, 9, 8) != "2026-09-08"`. The key lookup **always fails**, defaulting to `0.0`. Thus, logged irrigation applications never reduce soil depletion in production on PostgreSQL.

#### 1.5 Unit Consistency & Hardcoded Constants
- **Conversion Consistency**:
  - Plot area: $A_{\text{sqm}} = A_{\text{acres}} \times 4046.86$ (`irrigation.py:232`) — verified exact ($1\text{ acre} = 4046.8564\text{ m}^2$).
  - Water volume: $V_{\text{liters}} = D_{\text{gross}}(\text{mm}) \times A_{\text{sqm}}$ (`irrigation.py:236`) — verified exact ($1\text{ mm} \times 1\text{ m}^2 = 10^{-3}\text{ m} \times 1\text{ m}^2 = 10^{-3}\text{ m}^3 = 1\text{ Liter}$).
  - Pumping duration: $T_{\text{sec}} = V_{\text{liters}} / Q_{\text{lps}}$ (`irrigation.py:237`) — verified exact.
- **Hardcoded Constants**:
  - ₹80.0/hr pump tariff hardcoded on line 271 (`round(hours_saved * 80.0, 0)`), bypassing the regional state tariff engine.
  - Effective rainfall coefficient $0.80$ hardcoded in `water_bucket_model.py:81` (`min(rainfall_mm * 0.8, rainfall_mm)`).
  - Rain hold precipitation triggers hardcoded on line 265 ($24\text{h} \ge 3.0\text{ mm}$, $48\text{h} \ge 5.0\text{ mm}$, today $\ge 4.0\text{ mm}$).
  - Solar radiation fallback $21.0\text{ MJ/m}^2/\text{day}$ hardcoded in `weather_service.py:98`.
  - Default soil profile ($30\%\text{ clay}, 25\%\text{ sand}$) hardcoded in `soilgrids_service.py:14`.

---

### Phase 2 — Backend Integration & Infrastructure Reality Check
*(Domain: `agency-backend-architect` + `agency-api-tester`)*

#### 2.1 Redis Caching Layer (`app/services/cache_service.py`)
- **Wiring & Keys**: Redis is wired via `redis.Redis.from_url` with a graceful in-memory dictionary fallback (`_memory_cache`).
  - Weather cache key: `weather:{round(lat, 2)}:{round(lon, 2)}` (`weather_service.py:28`) with 3-hour TTL (`10800s`). Matches documentation.
  - Soil cache key: `soil_grid:{round(lat*20)/20}:{round(lon*20)/20}` (`soilgrids_service.py:60`) with 30-day TTL (`2592000s`). Documentation states 7 days (`05_system_architecture_and_db.md:132`), representing a documentation drift [F-17].
- **Event Loop Blockage** [F-15]: `CacheService.get()` and `CacheService.set()` use the synchronous `redis` client rather than `redis.asyncio`. When called inside async route handlers (`fetch_realtime_weather`, `fetch_soil_profile`), synchronous network I/O blocks the Uvicorn worker thread.

#### 2.2 ChromaDB & Vector Store Reality Check (`app/services/vector_search_service.py`) [F-08, F-10]
- While a 4.1MB SQLite file exists at `app/data/chroma_db/chroma.sqlite3`, `chromadb` is **not listed in `requirements.txt`**, is never imported in any Python file, and is completely unreferenced by the runtime.
- The `VectorSearchService` imports `from sentence_transformers import SentenceTransformer`, but `sentence-transformers` is omitted from `requirements.txt`.
- In `VectorSearchService.search_semantic_chunks()` (lines 122–146), line 145 executes an early return:
  ```python
  return [{'content': content, 'doc_name': doc_name, 'similarity': score} 
          for score, content, doc_name in scored[:top_k] if score > 0]
  ```
  Lines 147–174 contain unreachable dead code attempting to perform cosine similarity. Retrieval is executed purely via substring matching (`word in content_lower`) against whole in-memory `.txt` documents.
- `Google Gemini` (`google-generativeai`) is completely absent from `requirements.txt` and all backend files.

#### 2.3 Authentication & Cryptographic Standards (`app/core/security.py`)
- **Bcrypt**: Uses `bcrypt.hashpw(pwd_bytes, bcrypt.gensalt())`. In Python `bcrypt`, `gensalt()` defaults to 12 rounds. Passwords exceeding 72 bytes are safely truncated to 72 bytes to prevent bcrypt DoS attacks (Line 39).
- **JWT Secrets**: `SECRET_KEY` is read from `settings.JWT_SECRET_KEY` or `os.getenv("JWT_SECRET_KEY")`. If empty, startup raises `ValueError` (Line 17).
- **Administrative Key Flaw** [F-05]: In `app/core/config.py:31`, `ADMIN_API_KEY: str = "jaldrishti_admin_secret_key_2026_prod"` is hardcoded as default. Anyone reading source code can invoke `PUT /api/v1/admin/tariffs/{state}` or trigger batch advisory jobs.
- **Unprotected Endpoints** [F-06, F-07]:
  - `POST /api/v1/crops/pest-advisory` (`crop_info.py:28`) has no auth dependency. Anyone can trigger arbitrary Open-Meteo satellite fetches.
  - `GET /api/v1/admin/tariffs` (`admin_tariffs.py:20`) has no auth dependency.

#### 2.4 SQLAlchemy Schema Drift vs Documentation ERD [F-21]
- `docs/05_system_architecture_and_db.md` (lines 69–76) specifies an `email` field on the `USERS` table. The model (`app/models/user.py:6-17`) does not define `email`; it strictly uses `phone_number`.
- The doc ERD specifies table `FARMER_PROFILES` with `state` and `district`. The model (`app/models/user.py:22-38`) names the table `user_profiles`, omits `state` and `district`, and adds `latitude`, `longitude`, `farming_experience`, and `preferred_language`.
- Four active database tables are omitted from documentation ERD: `password_resets`, `regional_tariffs`, `chat_conversations`, and `chat_messages`.

---

### Phase 3 — RAG/AI Correctness
*(Domain: `agency-ai-engineer` + `agency-prompt-engineer`)*

#### 3.1 Prompt Analysis & Guardrail Audit (`app/services/rag_service.py`) [F-22]
- The system prompt (lines 208–228) defines a JSON schema containing `chemical_treatment`, `organic_alternative`, and `preventative_cultural_tip`.
- *Hallucination Vulnerability*: The prompt instructs: `"chemical_treatment": "Exact chemical dosage per acre (e.g. Cartap 4G @ 10 kg/acre)"`. It contains **no grounding directive** (e.g., *"Only recommend chemicals present in the provided Package of Practices. If dosage is unknown, state that consulting a local agronomist is required"*). Because the system prompt strongly commands an "exact chemical dosage", the LLM hallucinates dosages when context is missing.

#### 3.2 Multilingual Retrieval Breakdown [F-09]
- When a farmer sends a query in Bengali (e.g. `"আলু গাছে নাবি ধসা লাগলে কি করব?"` — What to do for potato late blight?), `search_semantic_chunks` splits the Bengali string into words.
- The knowledge base files in `app/data/pop_docs/` (`potato_guide.txt`, `paddy_rice_guide.txt`) are written entirely in English.
- The substring condition `word in content_lower` evaluates to `False` for every Bengali/Hindi word. The match count is 0, score is 0, and the function returns `[]`.
- `rag_service.py:202` injects: `"No localized Package of Practices document context matched."` The LLM is left completely ungrounded for all non-English vernacular queries.

#### 3.3 Audio / STT / TTS Infrastructure
- There is zero backend handling for audio, Speech-To-Text, or Text-To-Speech. The backend exposes only text JSON endpoints (`/api/v1/chatbot/query`). Speech-to-text and speech synthesis are offloaded entirely to Flutter client plugins (`speech_to_text`, `flutter_tts`).

---

### Phase 4 — Flutter Functional Completeness
*(Domain: `agency-mobile-app-builder`)*

#### 4.1 Broken API Endpoint Mappings [F-03, F-04]
- **Profile Update Failure**:
  - `jaldrishti_mobile/lib/core/services/api_service.dart:165` calls:
    `_sendRequest('POST', ApiConstants.updateProfileEndpoint, ...)` where `updateProfileEndpoint` is `/auth/profile`.
  - Backend route (`app/api/v1/endpoints/auth.py:235`) declares:
    `@router.put("/profile", response_model=UserProfileSchema)`
  - Executing `auth.updateProfile()` from `OnboardingSurveyScreen:104` or `ProfileScreen` triggers HTTP 405 Method Not Allowed. New users cannot submit the onboarding survey.
- **Password Reset Failure**:
  - `api_service.dart:125, 135` sends `{'phone_number': phoneNumber}`.
  - Backend `user_schema.py:30, 40` strictly requires `phone_or_username`.
  - Requesting OTP or submitting new password returns HTTP 422 Unprocessable Entity.

#### 4.2 Tab Data Wiring & Mock Inspection (`lib/screens/analytics/`)
- `WeatherStatsTab` (`weather_stats_tab.dart`): Consumes real `daily_breakdown` from `/irrigation/recommendation`.
- `DailyTrendsTab` (`daily_trends_tab.dart`): Draws custom charts using real `daily_breakdown`.
- `WaterBalanceTab` (`water_balance_tab.dart`): Sums real 7-day applied, rainfall, and ETc numbers.
- `HistoryLogsTab` (`history_logs_tab.dart`): Fetches real records from `/irrigation/history/{plot_id}`.
- `SmartInsightsTab` (`smart_insights_tab.dart:40-43`) [F-23]: Uses live `cumulative_savings` payload from backend, but implements hardcoded fallback mock defaults (`45000.0 L`, `₹850.0`, `29.8 kg CO2`) if backend data is null.

#### 4.3 Provider State Management & Session Lifecycle [F-20]
- **Silent Token Expiration**: `AuthProvider` stores access and refresh tokens. `refreshSession()` is implemented, but `ApiService._sendRequest()` contains no HTTP 401 interceptor. When the 60-minute access token expires during app usage, subsequent requests fail with `ApiException(401)`, breaking screens until user manually relaunches the app.
- **Log Water Run Modal**: Modal correctly calls `irrigation.logIrrigationEvent()`, which posts to `/irrigation/log` and triggers `loadIrrigationData()`. (However, as shown in F-01, backend type mismatch ignores it on PostgreSQL).

#### 4.4 Incomplete Features & Dead References [F-18, F-19]
- `settings_screen.dart:81–89`: `_showUpdateNameModal` simply calls `Navigator.pop()` and displays a fake SnackBar; no network call or provider update is performed.
- `settings_screen.dart:425, 431`: Tapping Bengali or Hindi displays "Coming Soon" and closes the dialog.
- `main.dart:60–69`: `AppLocalizations.delegate` is omitted from `localizationsDelegates`. The 7 localization files in `lib/l10n/` are completely unused.

---

### Phase 5 — Performance & Scalability
*(Domain: `agency-performance-benchmarker`)*

#### 5.1 Async Event Loop Blockers [F-15]
- `CacheService.get()` and `CacheService.set()` call synchronous `redis.Redis` network methods directly on the asyncio event loop thread inside `async def` routes (`fetch_realtime_weather`, `fetch_soil_profile`).
- `get_irrigation_recommendation` in `irrigation.py:97` is declared `async def`, yet performs multiple blocking synchronous database queries (`db.query(FarmPlot)`, `db.query(IrrigationLog)`). Under a load of 50 concurrent farmers, the single event loop thread freezes waiting for database socket responses.

#### 5.2 Redundant DB Queries
- In `irrigation.py`, line 165 queries `db.query(IrrigationLog).filter(IrrigationLog.farm_plot_id == payload.plot_id).all()`. Line 303 repeats the exact same query: `db.query(IrrigationLog).filter(IrrigationLog.farm_plot_id == payload.plot_id).all()`.

#### 5.3 Batch Scheduler Scalability (`app/services/automated_advisory_cron.py`)
- The automated advisory cron runs every 12 hours. It clusters plots by coordinates, but loops through cluster plots synchronously. For every plot, it invokes `FirebaseService.send_push_notification` one-by-one via `asyncio.to_thread`. With 5,000 farmers, this sequential loop takes several minutes to complete.

---

### Phase 6 — Conceptual / Product-Level Validity
*(Domain: Synthesis & Reality Check)*

#### 6.1 The "$\ge 85\%$ Sensor Accuracy" Claim
There is no code, benchmark suite, or empirical calibration validating the claim of "$\ge 85\%$ accuracy comparable to physical sensors" (`MASTER_PROJECT_DOCUMENTATION.md:442`). Physical capacitance probes measure in-situ root zone moisture continuously; JalDrishti relies on uncalibrated empirical pedotransfer equations ($\theta_{\text{FC}} = 0.10 + 0.0025\times\text{clay} + 0.0005\times(100-\text{sand})$) and a transient 7-day water balance model that resets depletion to zero every 72 hours. The accuracy claim is an unsubstantiated marketing figure.

#### 6.2 SoilGrids 250m Spatial Resolution Reality [F-16]
ISRIC SoilGrids provides static 250m-resolution raster data. However, `soilgrids_service.py` line 58 rounds coordinates:
```python
grid_lat = round(round(lat * 20) / 20.0, 2)
grid_lon = round(round(lon * 20) / 20.0, 2)
```
$0.05^\circ$ corresponds to roughly $5.5\text{ km} \times 5.5\text{ km}$ ($30.25\text{ km}^2$). In India, where marginal plots average $0.5$ to $2.0$ acres ($0.002\text{ to }0.008\text{ km}^2$), a single $5.5\text{ km}$ cell encompasses thousands of farms across varied topography. Marketing this as "exact farm plot soil telemetry" obscures severe spatial over-generalization.

#### 6.3 Degraded Mode under Satellite API Outage
- **Open-Meteo Outage**: If Open-Meteo returns 429 or fails, the service falls back to `_generate_fallback_telemetry` (`weather_service.py:166`), which hardcodes a static sunny day: $32.5^\circ\text{C}$ max temp, $75\%$ humidity, and **$0.0\text{ mm}$ rain**. If torrential monsoon rain is currently falling, the system reports $0.0\text{ mm}$ rain, misses the Smart Rain Hold, and prompts the farmer to irrigate.
- **ISRIC Outage**: If ISRIC SoilGrids fails, it returns `DEFAULT_SOIL_PROFILE` ($30\%$ clay, $25\%$ sand — West Bengal Gangetic Alluvium) regardless of whether the farm is in arid Rajasthan or volcanic Maharashtra.

#### 6.4 Oversimplification of the Smart Rain Hold
The Smart Rain Hold evaluates a static threshold ($P_{\text{upcoming}} \ge 5.0\text{ mm}$ or $P_{\text{today}} \ge 4.0\text{ mm}$). 5mm is a light shower. For a clay loam with $TAW = 120\text{ mm}$ and crop $ET_c = 6\text{ mm/day}$, 5mm satisfies less than 20 hours of evapotranspiration. Forcibly canceling irrigation during critical flowering stages because of a 5mm satellite forecast risk yield penalty. True agronomic hold requires dynamic balance: $\text{Hold if } (TAW - D_i) < P_{\text{forecast}}$.

---

## 4. Scientific/Formula Verification Table

| Formula / Parameter | Doc-Stated Formula | Code-Implemented Formula | Match? | Discrepancy Analysis & Citations |
|---|---|---|---|---|
| **Atmospheric Pressure ($P$)** | $101.3 \times \left(\frac{293 - 0.0065 z}{293}\right)^{5.26}$ | `101.3 * ((293.0 - 0.0065 * elevation_m) / 293.0) ** 5.26` | **YES** | Exact match with FAO-56 Eq. 7 (`penman_monteith.py:44`). |
| **Psychrometric Const ($\gamma$)** | $0.000665 \times P$ | `0.000665 * P` | **YES** | Exact match with FAO-56 Eq. 8 (`penman_monteith.py:47`). |
| **Saturation Vapor Pressure ($e_s$)** | $e_s = \frac{e^0(T_{\text{max}}) + e^0(T_{\text{min}})}{2}$ | `(e_temp_max + e_temp_min) / 2.0` | **YES** | Exact match with FAO-56 Eq. 12 (`penman_monteith.py:55`). |
| **Net Longwave Radiation ($R_{\text{nl}}$)** | $R_{\text{nl}} = 0.10 \times R_s$ (simplified) | Full Stefan-Boltzmann formulation with $\sigma, T_{\text{max}}^4, T_{\text{min}}^4, \sqrt{e_a}, \frac{R_s}{R_{\text{so}}}$ | **NO (Code Better)** | Doc (`02_penman_monteith_hydrology.md:72`) documents $0.10 R_s$, but code (`penman_monteith.py:80`) implements full FAO-56 Eq. 39. |
| **Wind Speed Height ($u_2$)** | $2\text{m}$ wind speed $u_2$ | `wind_speed_10m_max / 3.6` | **NO** | Code (`weather_service.py:99`) uses 10m peak wind speed without applying FAO-56 logarithmic reduction $u_2 = 0.748 u_{10}$. |
| **Late Season $K_c$ Stage** | Linear decay from $K_{c,\text{mid}}$ to $K_{c,\text{end}}$ | Static jump to $K_{c} = 0.75$ | **NO** | Doc specifies linear decay (`02_penman_monteith_hydrology.md:128`); code jumps to fixed 0.75 without decay (`water_bucket_model.py:49`). |
| **Soil Capacity ($\theta_{\text{FC}}$)** | $0.10 + 0.0025\times\text{Clay} + 0.0005\times(100-\text{Sand})$ | `0.10 + 0.0025 * clay + 0.0005 * (100.0 - sand)` | **YES** | Linear pedotransfer fit matches (`water_bucket_model.py:61`). |
| **Total Available Water ($TAW$)** | $1000 \times (\theta_{\text{FC}} - \theta_{\text{WP}}) \times Z_r$ | `1000.0 * (theta_fc - theta_wp) * root_depth_m` | **YES** | Exact dimensional conversion matches (`water_bucket_model.py:63`). |
| **Effective Rainfall ($P_{\text{eff}}$)** | $\min(P \times 0.80, P)$ | `min(rainfall_mm * 0.8, rainfall_mm)` | **YES** | Matches USDA/FAO simplified fraction (`water_bucket_model.py:81`). |
| **Single-Run Cost Saved** | $C_{\text{run}} = \text{round}(T_{\text{saved}} \times 80)$ | `round(hours_saved * 80.0, 0)` | **YES** | Matches doc (`03_smart_rain_hold_and_roi.md:75`), but hardcoded to ₹80 bypassing regional state tariff engine (`irrigation.py:271`). |
| **Cumulative Water Saved ($V_{\text{cum}}$)** | $V_{\text{cum}} = \text{round}(D_{\text{eff}} \times A_{\text{sqm}} \times (N_{\text{skipped}} + 3))$ | `cum_water_liters = round(saved_water_per_session_mm * area_sqm * session_count, 0)` | **NO** | Code (`irrigation.py:311`) does not use the doc's $+3$ offset, but sets `session_count = total_logs + rain_hold`, inverting logic. |
| **Total Skipped Runs ($N_{\text{total}}$)** | $N_{\text{total}} = N_{\text{skipped}} + 4$ | `skipped_runs_count = session_count` | **NO** | Doc (`03_smart_rain_hold_and_roi.md:106`) specifies synthetic $+4$ offset; code uses total logs count (`irrigation.py:328`). |

---

## 5. Endpoint ↔ Flutter Coverage Matrix

| FastAPI Endpoint Path | HTTP | Called by Flutter? | Caller Location (Screen/Widget/Service) | Uses Real Data or Mock? | Status & Notes |
|---|---|---|---|---|---|
| `/api/v1/auth/register` | `POST` | **YES** | `lib/screens/register_screen.dart` via `ApiService.register()` | **Real** | Working. Issues JWT pair. |
| `/api/v1/auth/login` | `POST` | **YES** | `lib/screens/login_screen.dart` via `ApiService.login()` | **Real** | Working. Validates username or phone. |
| `/api/v1/auth/refresh` | `POST` | **YES** | `lib/providers/auth_provider.dart:84` via `ApiService.refreshToken()` | **Real** | Called only during app boot; no 401 interceptor during runtime. |
| `/api/v1/auth/logout` | `POST` | **YES** | `lib/providers/auth_provider.dart:334` via `ApiService.logout()` | **Real** | Working. Blacklists JTI in Redis. |
| `/api/v1/auth/forgot-password/request-otp` | `POST` | **YES** | `lib/screens/forgot_password_screen.dart:38` via `ApiService.requestPasswordResetOtp()` | **Broken** | **Fails HTTP 422**: Flutter passes `phone_number`; schema requires `phone_or_username`. |
| `/api/v1/auth/forgot-password/reset-password` | `POST` | **YES** | `lib/screens/forgot_password_screen.dart:72` via `ApiService.resetPassword()` | **Broken** | **Fails HTTP 422**: Flutter passes `phone_number`; schema requires `phone_or_username`. |
| `/api/v1/auth/me` | `GET` | **YES** | `lib/providers/auth_provider.dart:233` via `ApiService.fetchProfile()` | **Real** | Working. Fetches profile on boot. |
| `/api/v1/auth/profile` | `PUT` | **YES** | `lib/screens/onboarding_survey_screen.dart:104` via `ApiService.updateProfile()` | **Broken** | **Fails HTTP 405**: Flutter sends `POST`, backend accepts only `PUT`. |
| `/api/v1/auth/request-phone-update-otp` | `POST` | **YES** | `lib/screens/settings_screen.dart:237` via `ApiService.requestPhoneUpdateOtp()` | **Real** | Working. Sends SMS OTP. |
| `/api/v1/auth/verify-phone-update-otp` | `POST` | **YES** | `lib/screens/settings_screen.dart:326` via `ApiService.verifyPhoneUpdateOtp()` | **Real** | Working. Updates phone in DB. |
| `/api/v1/auth/update-fcm-token` | `POST` | **YES** | `lib/core/services/fcm_service.dart:67` via `ApiService.updateFcmToken()` | **Real** | Working. Updates device push token. |
| `/api/v1/plots/` | `GET` | **YES** | `lib/providers/farm_plot_provider.dart:44` via `ApiService.fetchPlots()` | **Real** | Working. Fetches farmer plots. |
| `/api/v1/plots/` | `POST` | **YES** | `lib/screens/add_edit_farm_plot_screen.dart` via `ApiService.createPlot()` | **Real** | Working. Persists plot to DB. |
| `/api/v1/plots/{plot_id}` | `PUT` | **YES** | `lib/screens/add_edit_farm_plot_screen.dart` via `ApiService.updatePlot()` | **Real** | Working. Supports 409 conflict detection. |
| `/api/v1/plots/{plot_id}` | `DELETE`| **YES** | `lib/screens/add_edit_farm_plot_screen.dart` via `ApiService.deletePlot()` | **Real** | Working. Deletes plot. |
| `/api/v1/plots/{plot_id}/set-primary` | `PUT` | **YES** | `lib/screens/profile_screen.dart:294` via `ApiService.setPrimaryPlot()` | **Real** | Working. Updates primary plot. |
| `/api/v1/crops/all` | `GET` | **YES** | `lib/providers/irrigation_provider.dart:42` via `ApiService.fetchCrops()` | **Real** | Working. Reads crop catalog. |
| `/api/v1/crops/pest-advisory` | `POST` | **YES** | `lib/screens/pest_advisory_screen.dart:56` via `ApiService.fetchPestAdvisory()` | **Real** | Working, but endpoint lacks auth. |
| `/api/v1/crops/trigger-batch-advisories`| `POST` | **NO** | None (Admin endpoint) | N/A | **Orphaned**. Uncalled by mobile app. |
| `/api/v1/irrigation/recommendation` | `POST` | **YES** | `lib/providers/irrigation_provider.dart:65` via `ApiService.fetchIrrigationRecommendation()` | **Real** | Core engine endpoint. |
| `/api/v1/irrigation/log` | `POST` | **YES** | `lib/widgets/log_irrigation_modal.dart:369` via `ApiService.logIrrigationEvent()` | **Real** | Working persistence. |
| `/api/v1/irrigation/history/{plot_id}` | `GET` | **YES** | `lib/screens/analytics_screen.dart:61` via `ApiService.fetchIrrigationHistory()` | **Real** | Working pagination. |
| `/api/v1/chatbot/query` | `POST` | **YES** | `lib/providers/chat_provider.dart:195` via `ApiService.askChatbot()` | **Real** | Working Groq integration. |
| `/api/v1/admin/tariffs` | `GET` | **NO** | None (Admin endpoint) | N/A | **Orphaned**. Uncalled by mobile app. |
| `/api/v1/admin/tariffs/{state_code}` | `PUT` | **NO** | None (Admin endpoint) | N/A | **Orphaned**. Uncalled by mobile app. |
| `/api/v1/jalsathi/chat` | `POST` | **NO** | Documented in `05_system_architecture_and_db.md:165` | **Fictitious** | Endpoint does not exist in backend. |
| `/api/v1/irrigation/log-run` | `POST` | **NO** | Documented in `05_system_architecture_and_db.md:163` | **Fictitious** | Endpoint does not exist in backend. |

---

## 6. Tech Stack Utilization Verdict

| Component | Doc-Claimed Role | Actual Implementation Status | File & Line Evidence | Final Verdict |
|---|---|---|---|---|
| **Redis Cloud** | Distributed cache for weather (3h) and soil (7d). | Wired via `CacheService`. Caches weather (3h) and soil (30d). Uses synchronous client inside async endpoints. | `app/services/cache_service.py:16`<br/>`app/services/weather_service.py:112` | **PARTIALLY USED (WITH DEFECTS)** |
| **ChromaDB** | Local vector database storing PoP document embeddings. | File `chroma.sqlite3` sits idle on disk. Never imported or queried by any code. | `app/services/vector_search_service.py`<br/>`requirements.txt` (omitted) | **COMPLETELY UNUSED (DEAD ARTIFACT)** |
| **HuggingFace MiniLM** | Sentence-transformers embeddings for RAG retrieval. | `sentence-transformers` omitted from `requirements.txt`. Keyword match early returns on line 145; embeddings unused. | `app/services/vector_search_service.py:145`<br/>`requirements.txt:25-28` | **COMPLETELY UNUSED (BYPASSED)** |
| **Google Gemini** | Secondary fallback LLM in fallback cascade. | Not in `requirements.txt`. Zero imports, zero configuration, zero calls across entire repo. | `requirements.txt`<br/>`app/services/rag_service.py:251` | **FABRICATED / NON-EXISTENT** |
| **Groq Llama-3** | Primary RAG LLM engine with structured output. | Fully wired via `AsyncGroq` client. Generates JSON formatted responses with multi-model fallback chain. | `app/services/rag_service.py:56, 270` | **FULLY USED & FUNCTIONAL** |
| **Supabase PostgreSQL** | Cloud persistence with connection pooling. | Fully wired via SQLAlchemy with `pool_size=10, max_overflow=20, pool_pre_ping=True`. | `app/db/database.py:17-25` | **FULLY USED & FUNCTIONAL** |
| **Open-Meteo API** | Real-time weather, solar radiation, and rain forecasting. | Fully wired with circuit breaker, rate limit backoff, and caching. | `app/services/weather_service.py:51-115` | **FULLY USED & FUNCTIONAL** |
| **ISRIC SoilGrids** | Satellite topsoil texture extraction (clay/sand %). | Wired via REST API with 5.5km spatial binning, retries, and fallback presets. | `app/services/soilgrids_service.py:48-126` | **FULLY USED (COARSENED RESOLUTION)** |
| **Firebase Cloud Messaging** | Background push alerts for pest & weather warnings. | Fully wired on backend (`FirebaseService`) and mobile client (`FcmService`). | `app/services/firebase_service.py:48`<br/>`lib/core/services/fcm_service.dart:16` | **FULLY USED & FUNCTIONAL** |
| **Hive Local Storage** | Mobile offline caching and queue management. | Initialized and used for offline plot queue and recommendation caching. | `lib/main.dart:24-26`<br/>`lib/core/services/offline_cache_service.dart:13` | **FULLY USED & FUNCTIONAL** |
| **Flutter L10n** | Multilingual English, Bengali, and Hindi client UI. | ARB files exist, but delegate is omitted in `main.dart` and UI strings are hardcoded English. | `lib/main.dart:60-65`<br/>`lib/screens/settings_screen.dart:425` | **UNINTEGRATED / DEAD CODE** |

---

## 7. Open Questions for the Developer

1. **Intended Depletion History Window**: Was the 7-day weather window (`past_days=3`) intended as an ephemeral demo mode, or was there an intended persistence table (e.g. `daily_soil_depletion_state`) meant to record and carry forward yesterday's end-of-day depletion ($D_{i-1}$) across the full growing season?
2. **True Source of the "+3" and "+4" ROI Constants**: In `docs/03_smart_rain_hold_and_roi.md` lines 90 and 106, formulas include $(N_{\text{skipped}} + 3)$ and $N_{\text{skipped}} + 4$. Are these mathematical remnants of an empirical calibration curve from ICAR agronomy papers, or were they placeholder offsets added to guarantee non-zero savings on first launch?
3. **ChromaDB vs In-Memory Keyword Search Roadmap**: A 4.1MB SQLite ChromaDB database exists in `app/data/chroma_db/`, but `vector_search_service.py` was implemented with naive string matching. Was ChromaDB discarded due to deployment memory constraints on Render's 512MB free tier, and is there a plan to restore dense embeddings via a hosted vector store (e.g., Supabase `pgvector`)?
4. **Planned Handling for Non-English RAG Queries**: Since the Package of Practices documents are written in English, non-English farmer queries fail keyword matching. Was an automated translation step (e.g., translating farmer query to English prior to retrieval) planned, or should vernacular Package of Practices text files be ingested directly into the knowledge base?
5. **Crop Lifecycle Termination Behavior**: How should the system respond when `elapsed_days` exceeds the maximum duration specified in `crop_coefficients.json`? Should the plot transition to an explicit `"HARVESTED"` state, disabling active pump recommendations?
