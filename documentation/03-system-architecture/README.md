# System Architecture & Technical Infrastructure

> **Notice for Readers**: This section is written for software architects, backend engineers, and DevOps specialists. For a non-technical explanation of how these systems support the farmer's daily workflow, see [`01-concepts-and-workflows/`](../01-concepts-and-workflows/).

---

## Overview

JalDrishti is designed as a cloud-native, asynchronous decision-support platform engineered to deliver near-instantaneous hydrological advisories and RAG agronomy chat without hardware lock-in or high server overhead.

This folder documents the system architecture as verified and remediated across Phases 1 through 6:
- True asynchronous I/O and worker threadpool offloading (Phase 4)
- 100% Groq-native RAG pipeline with dense vector indexing and zero Gemini dependencies (Phase 5)
- Normalized client-server REST contracts and authentication interceptors (Phases 2 & 3)
- Scalable background advisory cron jobs with bounded concurrency (Phase 4)

---

## Documents in this Section & Conceptual Equivalents

| Architectural Document | Primary Focus | Plain-Language Equivalent |
|:-----------------------|:--------------|:--------------------------|
| [`high-level-architecture.md`](high-level-architecture.md) | Component topology, data boundaries, third-party integrations, and verified tech stack. | [`00-start-here/what-is-jaldrishti.md`](../00-start-here/what-is-jaldrishti.md) |
| [`request-lifecycle-walkthrough.md`](request-lifecycle-walkthrough.md) | End-to-end trace of `POST /api/v1/irrigation/recommendation` via Mermaid sequence diagram, citing actual source functions. | [`01-concepts-and-workflows/end-to-end-farmer-journey.md`](../01-concepts-and-workflows/end-to-end-farmer-journey.md) |
| [`caching-and-async-design.md`](caching-and-async-design.md) | `redis.asyncio` caching layer, TTL strategy (weather 3h, soil 30d), `run_in_threadpool` DB execution, and `asyncio.Semaphore` batching. | [`01-concepts-and-workflows/how-jaldrishti-decides-when-to-water.md`](../01-concepts-and-workflows/how-jaldrishti-decides-when-to-water.md) |
| [`deployment-and-infrastructure.md`](deployment-and-infrastructure.md) | Production hosting environment (Render/Railway), ~160 MB RAG RAM footprint, environment configurations, and open questions. | [`00-start-here/what-is-jaldrishti.md`](../00-start-here/what-is-jaldrishti.md) |
| [`PHASE7B_NOTES.md`](PHASE7B_NOTES.md) | Build notes for documentation Phase 7B: verified file inventory, git provenance, and unverified architectural claims flagged as open questions. | N/A (Engineering internal) |

---

## Primary Codebase Locations

- **FastAPI Core & Endpoints**: [`jaldrishti-backend/app/api/v1/endpoints/`](file:///d:/jaldrishti/jaldrishti-backend/app/api/v1/endpoints/)
- **Hydrology & Science Engines**: [`jaldrishti-backend/app/engine/`](file:///d:/jaldrishti/jaldrishti-backend/app/engine/)
- **Data Access & SQLAlchemy Models**: [`jaldrishti-backend/app/models/`](file:///d:/jaldrishti/jaldrishti-backend/app/models/)
- **Async Caching & External Gateways**: [`jaldrishti-backend/app/services/`](file:///d:/jaldrishti/jaldrishti-backend/app/services/)
- **Flutter Mobile Client**: [`jaldrishti_mobile/lib/`](file:///d:/jaldrishti/jaldrishti_mobile/lib/)
