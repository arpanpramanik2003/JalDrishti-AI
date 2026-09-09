# Deployment Target & Infrastructure Analysis

> **Audience**: DevOps engineers, cloud architects, and infrastructure leads.  
> **Source Verification**: Grounded in [`app/core/config.py`](file:///d:/jaldrishti/jaldrishti-backend/app/core/config.py), [`requirements.txt`](file:///d:/jaldrishti/jaldrishti-backend/requirements.txt), and [`PHASE5_CHANGELOG.md`](file:///d:/jaldrishti/PHASE5_CHANGELOG.md).

---

## 1. Verified Infrastructure Configuration

### Cloud Target & Networking
- **Host Target**: Configured to serve requests originating from `https://jaldrishti-ai.onrender.com` ([`config.py:16`](file:///d:/jaldrishti/jaldrishti-backend/app/core/config.py#L16)), indicating a Render web service target.
- **ASGI Process Manager**: Uvicorn running FastAPI with ASGI async workers.
- **CORS Allowlist**:
  - `http://localhost:3000`, `http://localhost:5000`, `http://localhost:8080`, `http://127.0.0.1:3000`
  - `https://jaldrishti-ai.onrender.com`
  - `app://jaldrishti` (custom mobile app scheme)

### Managed Database & Caching Services
- **Relational Database**: Supabase PostgreSQL in production, accessed through SQLAlchemy pooled connections via connection string variable `DATABASE_URL`. Defaults to local SQLite (`sqlite:///./jaldrishti.db`) for development.
- **Cache Layer**: Redis Cloud accessed via `REDIS_URL`. Falls back automatically to local process memory if empty or disconnected.

---

## 2. Memory Footprint & Free-Tier Suitability (Phase 5 Audit)

During Phase 5, the memory overhead of the JalSathi AI RAG rebuild was systematically benchmarked to ensure compatibility with memory-constrained environments (e.g., Render Free Tier or Railway Starter with 512 MB RAM caps):

| Subsystem Component | Disk Footprint | Peak RAM Utilization | Operational Behavior |
|:--------------------|:---------------|:---------------------|:---------------------|
| **Embedding Model** (`all-MiniLM-L6-v2`) | $\approx 80\text{ MB}$ | $\approx 120\text{ MB}$ (CPU inference) | Loaded into process memory on first RAG query. |
| **Vector Store** (ChromaDB 1.5.9) | $\approx 15\text{ MB}$ | $< 40\text{ MB}$ | Embedded SQLite persistence mode (`PersistentClient`). No separate server process. |
| **FastAPI Core & Hydrology Engines** | Negligible | $\approx 85\text{ MB}$ | Pure mathematical Python calculations and database query mapping. |
| **Total Baseline Working Set** | **$\approx 95\text{ MB}$** | **$\approx 245\text{ MB}$** | **Well within 512 MB memory boundary.** |

> [!TIP]
> **Offline Ingestion Decoupling**: Vector generation and document chunking are executed offline using [`app/scripts/ingest_pop_docs.py`](file:///d:/jaldrishti/jaldrishti-backend/app/scripts/ingest_pop_docs.py). Pre-embedded ChromaDB SQLite collections are committed to disk, preventing runtime memory spikes from document chunking during user requests.

---

## 3. Required Environment Variables Reference

| Variable Name | Type | Production Setting | Default Development Behavior | Startup Enforced? |
|:--------------|:-----|:-------------------|:-----------------------------|:------------------|
| `JWT_SECRET_KEY` | `string` | 64+ char cryptographic key | Refuses to start if empty | **YES** (Phase 2) |
| `ADMIN_API_KEY` | `string` | High-entropy admin secret | Refuses to start if empty | **YES** (Phase 2) |
| `DATABASE_URL` | `string` | Supabase Postgres URI | `sqlite:///./jaldrishti.db` | No (falls back) |
| `REDIS_URL` | `string` | Redis Cloud connection URI | In-memory TTL cache | No (falls back) |
| `GROQ_API_KEY` | `string` | Groq Cloud production key | AI endpoints throw fallback | No (falls back) |
| `GROQ_MODEL_NAME` | `string` | `"openai/gpt-oss-20b"` | `"openai/gpt-oss-20b"` | No |
| `WEATHER_API_KEY` | `string` | WeatherAPI key (optional) | Uses Open-Meteo as primary | No |
| `ENVIRONMENT` | `string` | `"production"` | `"development"` | No |
| `ENABLE_DEV_OTP_LOGS` | `boolean` | `false` | `true` (logs OTP to stdout) | No |
| `FAST2SMS_API_KEY` | `string` | Fast2SMS production gateway | Dev OTP console logging | No |

---

## 4. Open Questions & Unverified Infrastructure Claims

To adhere strictly to engineering accuracy standards, the following aspects of production infrastructure cannot be definitively verified from the repository source code alone and are cataloged here as open questions for DevOps teams:

1. **Docker / Containerization Strategy**: No `Dockerfile`, `docker-compose.yml`, or `render.yaml` is currently committed in the repository. The exact container buildpack, base Python image (e.g. `python:3.11-slim`), and OS-level shared libraries used in CI/CD are unspecified in source control.
2. **Uvicorn Worker Concurrency**: The production entrypoint command (`uvicorn app.main:app --workers N`) is managed externally in the cloud dashboard. Given the 120 MB RAM footprint of `sentence-transformers`, running multiple worker processes on a 512 MB container will cause Out-Of-Memory (OOM) kills. DevOps must confirm single-worker mode or scale RAM accordingly.
3. **Automated Cron Scheduler Trigger**: While [`automated_advisory_cron.py`](file:///d:/jaldrishti/jaldrishti-backend/app/services/automated_advisory_cron.py) is implemented and testable, the exact cron trigger mechanism (e.g. Render Cron Job hitting an HTTP endpoint vs. external GitHub Action vs. Celery/APScheduler daemon) is not defined in repo configuration.
