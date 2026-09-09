# Phase 7B Build Notes & Architectural Verification

> **Document Type**: Internal Engineering Build Notes & Documentation Provenance  
> **Date**: September 9, 2026  
> **Status**: COMPLETE  
> **Author**: Technical Writing Specialist (`agency-technical-writer`) in consultation with Backend Architect (`agency-backend-architect`)  
> **Scope**: `documentation/02-scientific-reference/`, `documentation/03-system-architecture/`, `documentation/04-database-reference/`

---

## 1. Summary of Files Created in Phase 7B

Phase 7B constructed the complete, audited deep-technical reference layer for JalDrishti across three new directories:

### `documentation/02-scientific-reference/`
1. [`README.md`](../02-scientific-reference/README.md): Index, technical audience notice, and cross-links to conceptual equivalents.
2. [`evapotranspiration-and-eto.md`](../02-scientific-reference/evapotranspiration-and-eto.md): Full FAO-56 Penman-Monteith derivation with Stefan-Boltzmann net radiation, psychrometric constants, and the Phase 1 logarithmic wind profile reduction (Eq. 47).
3. [`crop-coefficient-and-growth-stages.md`](../02-scientific-reference/crop-coefficient-and-growth-stages.md): Dynamic $K_c(t)$ curve interpolation, late-season linear decay fix, root expansion $Z_r(t)$, and boundary conditions (`NOT_YET_SOWN`, `HARVEST_OVERDUE`).
4. [`soil-water-balance-model.md`](../02-scientific-reference/soil-water-balance-model.md): Root-zone depletion mass balance ($D_i$), Saxton-Rawls pedotransfer functions ($\theta_{FC}, \theta_{WP}, TAW, RAW$), `SoilDepletionState` database persistence, and ~5.5 km coordinate binning transparency.
5. [`rain-hold-and-roi-formulas.md`](../02-scientific-reference/rain-hold-and-roi-formulas.md): Rain Hold threshold triggers ($3\text{ mm}/24\text{h}$, $5\text{ mm}/48\text{h}$, $4\text{ mm}$ today), date-gated skipped runs counter, and regional economic ROI derivations (water, pump runtime, energy cost, carbon).
6. [`known-scientific-limitations.md`](../02-scientific-reference/known-scientific-limitations.md): Honest consolidation of grid coarsening, lack of in-situ sensor ground-truthing, static rain hold thresholds, and satellite outage fallback risks.

### `documentation/03-system-architecture/`
1. [`README.md`](README.md): Index, technical audience notice, and cross-links to conceptual equivalents.
2. [`high-level-architecture.md`](high-level-architecture.md): High-level system architecture diagram (Mermaid) with real stack (FastAPI, Flutter, Supabase Postgres, Redis, ChromaDB, Groq) with zero Gemini mentions.
3. [`request-lifecycle-walkthrough.md`](request-lifecycle-walkthrough.md): End-to-end trace of `POST /api/v1/irrigation/recommendation` via Mermaid sequence diagram with file and line citations.
4. [`caching-and-async-design.md`](caching-and-async-design.md): Asynchronous Redis design (`redis.asyncio`), `run_in_threadpool` DB execution rationale, verified cache TTLs (3h weather, 30d soil), and bounded concurrency batching (`asyncio.Semaphore(20)`).
5. [`deployment-and-infrastructure.md`](deployment-and-infrastructure.md): Verified deployment target analysis (Render/Railway), ~160 MB RAG memory footprint analysis, and required environment variables.
6. [`PHASE7B_NOTES.md`](PHASE7B_NOTES.md): This build provenance and verification document.

### `documentation/04-database-reference/`
1. [`README.md`](../04-database-reference/README.md): Index and schema architecture introduction.
2. [`entity-relationship-diagram.md`](../04-database-reference/entity-relationship-diagram.md): Corrected Mermaid ERD capturing all 9 active models (including `password_resets`, `regional_tariffs`, `chat_conversations`, `chat_messages`, and `soil_depletion_state`).
3. [`table-by-table-reference.md`](../04-database-reference/table-by-table-reference.md): Audited field-by-field reference for every table with constraints, data types, nullability, and business rules.

---

## 2. Integrity Confirmation: Legacy `docs/` Untouched

As required by the critical constraint, the existing `docs/` directory and its `workflows/` subfolder were left completely untouched.

Verification check (`git status -s docs/`):
```powershell
$ git status -s docs/
# Output: (empty — 0 files modified, added, or deleted)
```

---

## 3. Explicit Editorial Decisions & Open Questions Flagged

Where claims could not be verified directly against repository code, or where technical trade-offs required honest framing, explicit editorial judgments were made rather than asserting speculative assumptions:

| Topic | Legacy / Speculative Claim | Verified Code Reality & Editorial Decision | Documented In |
|:------|:---------------------------|:-------------------------------------------|:--------------|
| **SoilGrids Resolution** | Claimed "250m hyper-resolution native sub-plot accuracy". | Code explicitly coarsens coordinates to $0.05^\circ$ ($\approx 5.5\text{ km} \times 5.5\text{ km}$) for caching. Documented as a ~5.5 km grid cell, explaining the performance and API rate-limit rationale. | [`soil-water-balance-model.md`](../02-scientific-reference/soil-water-balance-model.md) & [`known-scientific-limitations.md`](../02-scientific-reference/known-scientific-limitations.md) |
| **Physical Sensor Accuracy** | Claimed "$\ge 85\%$ accuracy compared to IoT soil probes". | No physical sensor ground-truthing data exists in the repository. Stated plainly that the system has **not** been benchmarked against in-situ physical capacitive/TDR sensors. | [`known-scientific-limitations.md`](../02-scientific-reference/known-scientific-limitations.md) |
| **Soil Cache TTL** | Old docs claimed 7-day soil cache. | Code in `soilgrids_service.py:130` explicitly sets `expire_seconds=2592000` (30 days). Documented as 30 days. | [`caching-and-async-design.md`](caching-and-async-design.md) |
| **Longwave Radiation Formula** | Old docs claimed $R_{nl} = 0.10 \times R_s$ shortcut. | Code in `penman_monteith.py:122-126` implements full Stefan-Boltzmann net longwave equation (FAO-56 Eq. 39). Flagged as documentation drift where code was superior to old docs. | [`evapotranspiration-and-eto.md`](../02-scientific-reference/evapotranspiration-and-eto.md) |
| **Production Containerization** | Speculative Docker or Kubernetes specs. | No Dockerfile or compose file exists in repo. Flagged explicitly as an **Open Question** for DevOps in the infrastructure guide. | [`deployment-and-infrastructure.md`](deployment-and-infrastructure.md) |
| **Automated Cron Trigger** | Speculative cloud cron scheduler. | Background batch routine is implemented in Python, but the trigger mechanism (external webhook vs internal worker daemon) is uncommitted. Flagged as an **Open Question**. | [`deployment-and-infrastructure.md`](deployment-and-infrastructure.md) |
