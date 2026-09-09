# Open Questions for Developers & Engineering Roadmap

> **Audience**: Backend architects, mobile developers, DevOps engineers, and agronomic researchers.  
> **Purpose**: A centralized, de-duplicated backlog of open architectural decisions and unanswered engineering questions identified during the audit and Phases 1–7 documentation rebuild.

---

## 1. Hydrology, Soil & Meteorological Modeling

### Q1: Hardening the Zero-Precipitation Fallback during Satellite Outages
- **Original Citation**: `JALDRISHTI_AUDIT_REPORT.md` (Audit Finding 4.1), [`PHASE7B_NOTES.md`](../03-system-architecture/PHASE7B_NOTES.md), [`known-limitations-consolidated.md`](known-limitations-consolidated.md#1-satellite-outage-during-active-rain-fallback).
- **The Question**: When Open-Meteo and WeatherAPI fail or rate limit, `_generate_fallback_telemetry()` returns `precipitation_mm = 0.0`. During an actual heavy monsoon storm, this causes the mass balance engine to assume zero rain fell, creating a severe over-irrigation risk.
- **Proposed Developer Action**:
  1. When satellite telemetry fails, check if recent historical days had active rain or if regional humidity is $> 90\%$.
  2. Rather than issuing a standard recommendation with $0\text{ mm}$ rain, return a prominent advisory warning: `"Satellite weather data temporarily unavailable. Please visually confirm field moisture before running your pump."`
  3. Suppress automated pump runtime recommendations until verified weather telemetry resumes.

### Q2: Transitioning from Static to Dynamic Soil-Aware Rain Hold Thresholds
- **Original Citation**: `JALDRISHTI_AUDIT_REPORT.md` (Audit Finding 6.4), [`PHASE1_CHANGELOG.md`](file:///d:/jaldrishti/PHASE1_CHANGELOG.md).
- **The Question**: Should the static $3.0\text{ mm}/24\text{h}$ and $5.0\text{ mm}/48\text{h}$ Rain Hold thresholds be replaced with a dynamic calculation based on current soil water deficit?
- **Proposed Developer Action**: Update the trigger condition to evaluate whether forecast precipitation covers at least $50\%$ of the current root-zone deficit:
  $$\text{RainHoldTrigger} = \text{True} \quad \iff \quad P_{\text{forecast}} \ge (RAW - D_i) \times 0.50$$

### Q3: Establishing an Empirical Physical Sensor Calibration Testbed
- **Original Citation**: `JALDRISHTI_AUDIT_REPORT.md` (Audit Finding 6.3), [`PHASE7B_NOTES.md`](../03-system-architecture/PHASE7B_NOTES.md).
- **The Question**: What empirical testbed protocol should be established with local agricultural universities (e.g. BCKV, PAU) to benchmark JalDrishti's calculated depletion against in-situ TDR/capacitance soil moisture probes?
- **Proposed Developer Action**: Deploy 5 test plots instrumented with low-cost LoRaWAN or manual gravimetric soil moisture sampling across alluvial clay-loam and red sandy-loam soils over one full paddy/wheat cycle to establish real RMSE error bounds.

---

## 2. Infrastructure, Deployment & DevOps

### Q4: Containerization & Dockerfile Standardization
- **Original Citation**: `PHASE4_CHANGELOG.md`, `PHASE5_CHANGELOG.md`, [`PHASE7B_NOTES.md`](../03-system-architecture/PHASE7B_NOTES.md).
- **The Question**: The repository lacks a `Dockerfile` or `render.yaml`. What is the production base image and memory boundary?
- **Proposed Developer Action**: Commit a multi-stage `Dockerfile` using `python:3.11-slim` with pinned compiler packages for ChromaDB/SQLite. Explicitly configure Uvicorn worker counts (`--workers 1` for 512 MB instances) to prevent Out-Of-Memory (OOM) crashes from `sentence-transformers`.

### Q5: Automated Morning Advisory Cron Scheduler Trigger
- **Original Citation**: `PHASE4_CHANGELOG.md`, [`PHASE7B_NOTES.md`](../03-system-architecture/PHASE7B_NOTES.md).
- **The Question**: How should `automated_advisory_cron.py` be triggered in production at 06:00 AM IST daily?
- **Proposed Developer Action**: Establish a Render Cron Job or external GitHub Actions workflow that executes a secure HTTP request to `POST /api/v1/crops/trigger-batch-advisories` passing the required `X-Admin-API-Key` header.

---

## 3. Mobile Application & Localization

### Q6: Multi-Screen ARB Key Extraction for Full Bengali & Hindi Support
- **Original Citation**: `PHASE6_CHANGELOG.md`, [`PHASE7C_NOTES.md`](../07-ai-rag-pipeline/PHASE7C_NOTES.md).
- **The Question**: All 14 ARB keys are translated, but ~53 UI files still feature hardcoded English strings. How should the remaining strings be extracted?
- **Proposed Developer Action**: Execute an automated string extraction script over `jaldrishti_mobile/lib/screens/` to extract all user-facing strings into `app_en.arb`, generate Bengali and Hindi equivalents, and remove the "Coming Soon" label from the settings language dialog.

### Q7: Offline Sync Queue Date Formatting (`FLAG-P4-01`)
- **Original Citation**: `PHASE3_CHANGELOG.md` (line 155), [`PHASE7C_NOTES.md`](../07-ai-rag-pipeline/PHASE7C_NOTES.md).
- **The Question**: In `offline_sync_manager.dart:66`, offline queue items record timestamps as ISO-8601 datetime strings (`DateTime.now().toIso8601String()`).
- **Proposed Developer Action**: Explicitly format the `applied_date` field using `DateFormat('yyyy-MM-dd').format(date)` prior to enqueuing in Hive, guaranteeing timezone-safe ISO calendar date strings for FastAPI's `datetime.date` parser.

---

## 4. Artificial Intelligence & RAG Pipeline Roadmap

### Q8: Numerical Dosage NLI Parsing in Chemical Guardrails
- **Original Citation**: `PHASE5_CHANGELOG.md`, [`PHASE7C_NOTES.md`](../07-ai-rag-pipeline/PHASE7C_NOTES.md).
- **The Question**: The current guardrail (`_verify_and_guard_chemicals`) verifies chemical active ingredient names, but cannot detect if an LLM hallucinates an unsafe numerical dosage (e.g. 50 kg/acre instead of 50 g/acre).
- **Proposed Developer Action**: Implement a regex-based dosage extractor or a lightweight Natural Language Inference (NLI) check that compares extracted numbers against a structured dosage table in `crop_coefficients.json`.

### Q9: Direct Vernacular Document Ingestion in ChromaDB
- **Original Citation**: `PHASE5_CHANGELOG.md`, [`PHASE7C_NOTES.md`](../07-ai-rag-pipeline/PHASE7C_NOTES.md).
- **The Question**: Should the ICAR Package of Practices documents be translated once into Bengali and Hindi and stored in native ChromaDB collections (`jaldrishti_pop_docs_bn`, `jaldrishti_pop_docs_hi`)?
- **Proposed Developer Action**: Translating and indexing native collections would eliminate the preliminary Groq translation step, shaving 120–180ms off query latency for rural farmers.
