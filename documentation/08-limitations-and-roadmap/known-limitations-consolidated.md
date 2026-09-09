# Master Consolidated Limitations Catalog

> **Audience**: Agronomists, system architects, software developers, and safety auditors.  
> **Purpose**: A single, comprehensive, and unvarnished accounting of every known constraint, approximation, unvalidated assumption, and open risk in the current JalDrishti system.  
> **Classification Key**:
> - 🟢 **RESOLVED**: Remediated and verified in code during Phases 1–6.
> - 🟡 **PARTIALLY MITIGATED**: Guardrails, fallbacks, or partial architecture added, but residual edge cases or manual work remain.
> - 🔴 **UNRESOLVED**: Open technical gap or safety risk that has **not** been modified or fixed in code across Phases 1–6.

---

## 1. Safety-Critical Hydrological & Meteorological Limitations

### 🔴 1. Satellite Outage During Active Rain Fallback
- **Plain-Language Summary**: If satellite weather APIs go down during heavy monsoon rain, the system assumes 0 mm rainfall and may tell the farmer to irrigate an already flooded field.
- **Technical Detail**: In [`app/services/weather_service.py:194-213`](file:///d:/jaldrishti/jaldrishti-backend/app/services/weather_service.py#L194-L213), when Open-Meteo and WeatherAPI fail or rate limit, and no stale cache exists, `_generate_fallback_telemetry()` generates synthetic daily weather with `"precipitation_mm": 0.0`. If a severe convective storm or monsoon downpour is occurring in reality during an external API outage, the system registers zero water infiltration. The mass balance model continues calculating daily evapotranspiration depletion, which can trigger an erroneous "Irrigate Now" recommendation, leading to severe root waterlogging and crop loss.
- **Remediation Status Across Phases 1–6**: **UNRESOLVED**. None of the remediation phases modified `_generate_fallback_telemetry()`. This is the single most safety-critical open risk in the entire platform.
- **Detailed Reference**: [`02-scientific-reference/known-scientific-limitations.md`](../02-scientific-reference/known-scientific-limitations.md#4-satellite-outage--circuit-breaker-fallback-behavior)

---

### 🔴 2. Lack of In-Situ Physical Sensor Benchmarking
- **Plain-Language Summary**: The irrigation advice has never been checked against real physical soil sensors buried in a real field.
- **Technical Detail**: JalDrishti relies on the FAO-56 Penman-Monteith equation and Saxton-Rawls pedotransfer approximations. While these formulas are globally respected in academic literature, the platform has **zero empirical ground-truthing data** against calibrated Time-Domain Reflectometry (TDR), capacitance probes, or gravimetric core samples across varied Indian agro-climatic zones.
- **Remediation Status Across Phases 1–6**: **UNRESOLVED** (Audit Finding 6.3). The system's actual field accuracy variance relative to physical instrumentation is unquantified. Legacy claims of "$\ge 85\%$ IoT-equivalent accuracy" were ungrounded and have been purged from documentation.
- **Detailed Reference**: [`02-scientific-reference/known-scientific-limitations.md`](../02-scientific-reference/known-scientific-limitations.md#2-in-situ-physical-sensor-benchmarking-unvalidated-accuracy)

---

### 🔴 3. Static, Non-Soil-Aware Rain Hold Thresholds
- **Plain-Language Summary**: The decision to pause pumping before rain uses the exact same rainfall number for light sandy soil as for heavy clay.
- **Technical Detail**: The Smart Rain Hold engine evaluates static thresholds ($P_{24\text{h}} \ge 3.0\text{ mm}$, $P_{48\text{h}} \ge 5.0\text{ mm}$, $P_{\text{today}} \ge 4.0\text{ mm}$, [`constants.py:86-98`](file:///d:/jaldrishti/jaldrishti-backend/app/core/constants.py#L86-L98)). It does not dynamically compare forecast precipitation depth against current soil storage capacity ($TAW - D_i$). In low-capacity sandy soils, $5\text{ mm}$ replenishes over $12\%$ of root storage, justifying a hold; in depleted heavy clays, $5\text{ mm}$ barely moistens the crust, leaving deep roots in moisture stress despite the hold.
- **Remediation Status Across Phases 1–6**: **UNRESOLVED** (Audit Finding 6.4). The formula remains a fixed heuristic.
- **Detailed Reference**: [`02-scientific-reference/known-scientific-limitations.md`](../02-scientific-reference/known-scientific-limitations.md#3-static-rain-hold-heuristics-audit-finding-64)

---

### 🟡 4. Soil Texture Spatial Resolution Coarsening (~5.5 km Grid)
- **Plain-Language Summary**: The app lumps together farms within a 5.5 km square into the same soil type, which can be wrong in areas with mixed soils.
- **Technical Detail**: While ISRIC SoilGrids v2.0 natively provides $250\text{ m}$ raster pixels, [`app/services/soilgrids_service.py:64-65`](file:///d:/jaldrishti/jaldrishti-backend/app/services/soilgrids_service.py#L64-L65) rounds coordinates to $0.05^\circ$ ($\approx 5.5\text{ km} \times 5.5\text{ km}$ at Indo-Gangetic latitudes) to optimize caching and rate limits. Micro-topographical soil variance (e.g. river levee sand next to back-swamp clay within 500 meters) is obscured.
- **Remediation Status Across Phases 1–6**: **PARTIALLY MITIGATED**. Mitigated by providing manual soil texture override presets (`sandy_loam`, `loam`, `clay_loam`, `silty_clay`, `heavy_clay`) in plot settings. Documentation was corrected in Phase 7B to retract false 250m claims.
- **Detailed Reference**: [`02-scientific-reference/soil-water-balance-model.md`](../02-scientific-reference/soil-water-balance-model.md#5-soilgrids-data-ingestion--honest-resolution-notes)

---

## 2. Artificial Intelligence & RAG Safeguards

### 🟡 5. RAG Chemical Guardrail is Presence-Check Only
- **Plain-Language Summary**: The AI checks if a pesticide name is in the official book, but cannot tell if the dosage number is crazy.
- **Technical Detail**: The anti-hallucination guardrail (`_verify_and_guard_chemicals` in [`app/services/rag_service.py:191-231`](file:///d:/jaldrishti/jaldrishti-backend/app/services/rag_service.py#L191-L231)) scans the generated solution text for 45+ chemical active ingredient strings and verifies their presence in retrieved ICAR context chunks. However, it is an active ingredient presence check, not a semantic Natural Language Inference (NLI) parser. If the LLM extracts an authentic chemical name from context but hallucinates an extreme numerical dosage (e.g. *50 kg/acre* instead of *50 g/acre*), the keyword check passes.
- **Remediation Status Across Phases 1–6**: **PARTIALLY MITIGATED** (Phase 5 [F-22]). Replaces ungrounded chemicals with a KVK consultation notice, and system prompt mandates exact context extraction, but numerical dosage parsing remains open.
- **Detailed Reference**: [`07-ai-rag-pipeline/prompt-and-grounding-safeguards.md`](../07-ai-rag-pipeline/prompt-and-grounding-safeguards.md#4-honest-technical-caveats--limitations)

---

### 🟡 6. Multilingual Translation Latency Hop
- **Plain-Language Summary**: Non-English questions take an extra 150 ms to answer because the system translates them to English before searching its books.
- **Technical Detail**: Because the ICAR Package of Practices documents are stored in English, queries in Bengali or Hindi require a preliminary Groq LLM translation call before querying ChromaDB. While fast (< 150 ms), it adds an extra network round-trip.
- **Remediation Status Across Phases 1–6**: **PARTIALLY MITIGATED** (Phase 5 [F-09]). Fully functional, but native vernacular document ingestion remains on the roadmap.
- **Detailed Reference**: [`07-ai-rag-pipeline/multilingual-translation-step.md`](../07-ai-rag-pipeline/multilingual-translation-step.md)

---

## 3. Mobile Application & User Experience

### 🔴 7. Mobile UI Localization Deficit (~53 Screens Hardcoded English)
- **Plain-Language Summary**: The AI talks and listens in Bengali and Hindi, but 85% of the buttons and screens in the mobile app are still in English.
- **Technical Detail**: While 100% of defined ARB translation keys (14 of 14) are translated in `app_en.arb`, `app_bn.arb`, and `app_hi.arb`, approximately 53 Dart UI files in `jaldrishti_mobile/` still contain hundreds of hardcoded English strings. Switching the app locale translates the navigation bar, but leaves forms, dialogs, and error messages in English.
- **Remediation Status Across Phases 1–6**: **UNRESOLVED** (Phase 6 [F-19]). Infrastructure connected in `main.dart`, but UI string extraction into `.arb` files is pending. Settings dialog honestly retains the "Coming Soon" label.
- **Detailed Reference**: [`06-mobile-app-reference/localization-status.md`](../06-mobile-app-reference/localization-status.md)

---

### 🟡 8. Offline Sync Queue Date Serialization Risk (`FLAG-P4-01`)
- **Plain-Language Summary**: Pumping logged while offline might get recorded with a slightly off timestamp if synced right around midnight.
- **Technical Detail**: In [`offline_sync_manager.dart:66`](file:///d:/jaldrishti/jaldrishti-backend/app/services/weather_service.py), queued offline events serialize dates as full ISO-8601 timestamps (`"YYYY-MM-DDTHH:MM:SSZ"`). While FastAPI's Pydantic parser coerces this to `datetime.date`, midnight synchronizations across timezones could experience off-by-one day categorization.
- **Remediation Status Across Phases 1–6**: **PARTIALLY MITIGATED**. Functional via Pydantic parsing, but client payload formatting should be explicitly locked to `"YYYY-MM-DD"`.
- **Detailed Reference**: [`06-mobile-app-reference/offline-and-sync-behavior.md`](../06-mobile-app-reference/offline-and-sync-behavior.md#5-known-open-risk-date-serialization-format-flag-p4-01)

---

## 4. DevOps & Cloud Infrastructure

### 🔴 9. Uncommitted Production Containerization (No Dockerfile)
- **Plain-Language Summary**: There is no Docker file in the repository to guarantee that the app runs the exact same way on every server.
- **Technical Detail**: The repository contains no `Dockerfile`, `docker-compose.yml`, or `render.yaml`. The exact base Python image, OS build dependencies for compiling native C libraries (ChromaDB SQLite, sentence-transformers), and container entrypoint flags are uncommitted.
- **Remediation Status Across Phases 1–6**: **UNRESOLVED**. Relies on implicit cloud platform buildpacks.
- **Detailed Reference**: [`03-system-architecture/deployment-and-infrastructure.md`](../03-system-architecture/deployment-and-infrastructure.md#4-open-questions--unverified-infrastructure-claims)

---

### 🔴 10. Uncommitted Automated Cron Trigger Mechanism
- **Plain-Language Summary**: The code to send morning weather and pest alerts exists, but there is no schedule file saying what triggers it every morning.
- **Technical Detail**: [`automated_advisory_cron.py`](file:///d:/jaldrishti/jaldrishti-backend/app/services/automated_advisory_cron.py) implements the batch scanning and push notification logic, and `POST /api/v1/crops/trigger-batch-advisories` exposes it via admin API key. However, the external scheduler (e.g. Render Cron Job, GitHub Actions workflow, or Celery beat daemon) is uncommitted in the repo.
- **Remediation Status Across Phases 1–6**: **UNRESOLVED**. Trigger must be configured externally by DevOps.
- **Detailed Reference**: [`03-system-architecture/deployment-and-infrastructure.md`](../03-system-architecture/deployment-and-infrastructure.md#4-open-questions--unverified-infrastructure-claims)
