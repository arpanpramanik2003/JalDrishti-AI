# JalDrishti Engineering & Systems Documentation

Welcome to the definitive documentation set for **JalDrishti**, an AI-powered precision irrigation and agronomy advisory system designed for Indian smallholder farmers.

---

> [!NOTE]
> **Documentation Version & Authority Notice**  
> This documentation set (`documentation/`) was written from scratch following the completion of **Phases 1 through 6 of system remediation** (September 2026). It documents the **actual, operational architecture and behavior** of the system today.  
> The legacy `docs/` directory is retained in this repository strictly for historical and provenance reference, but is superseded in technical accuracy by this directory wherever discrepancy exists.

---

## 📚 Documentation Structure

The documentation is organized into numbered tiers, progressing from accessible conceptual overviews to deep scientific and operational references:

| Directory | Name & Purpose | Target Audience |
|---|---|---|
| [`00-start-here/`](./00-start-here/what-is-jaldrishti.md) | **Start Here**: Plain-language introduction, problem framing, honest trade-offs, and reading guides. | Investors, agronomy partners, new hires, non-technical stakeholders. |
| [`01-concepts-and-workflows/`](./01-concepts-and-workflows/the-irrigation-problem.md) | **Concepts & Workflows**: End-to-end user journeys, hydrology water bucket analogies, Smart Rain Hold mechanics, and JalSathi AI RAG architecture. | Agronomists, product managers, engineers, field officers. |
| [`02-scientific-reference/`](./02-scientific-reference/README.md) | **Scientific Reference**: FAO-56 Penman-Monteith formulas, dynamic $K_c(t)$ phenology, root-zone depletion balance, Rain Hold thresholds, and known limitations. | Hydrologists, agricultural scientists, backend engineers. |
| [`03-system-architecture/`](./03-system-architecture/README.md) | **System Architecture**: High-level topology, end-to-end request walkthrough, async Redis caching, threadpool offloading, and deployment environment. | Software engineers, cloud architects, DevOps engineers. |
| [`04-database-reference/`](./04-database-reference/README.md) | **Database Reference**: Corrected 9-table Entity-Relationship Diagram (ERD) and field-by-field schema specifications. | Database administrators, backend developers, data engineers. |
| `05-api-reference/` *(Future Phase)* | **REST API Contracts**: Endpoint specifications, schemas, authentication flows, error handling, and rate limits. | Mobile developers, API consumers, frontend engineers. |
| `06-jalsathi-ai-deep-dive/` *(Future Phase)* | **JalSathi AI Pipeline**: Vector search embeddings, ChromaDB schema, Groq multi-tier fallback, and safety guardrails. | AI/ML engineers, prompt engineers. |
| `07-operations-and-deployment/` *(Future Phase)* | **DevOps & Operations**: Local development setup, Docker, environment configuration, database migrations, and monitoring. | DevOps, SREs, system administrators. |

---

## 🗂️ Document Index

### 00 — Start Here
- [**What is JalDrishti?**](./00-start-here/what-is-jaldrishti.md): The core mission, smallholder farming realities, how the platform works without physical sensors, and our honest engineering philosophy.
- [**How to Navigate this Documentation**](./00-start-here/how-to-navigate-this-documentation.md): Reading paths customized for non-technical readers, agronomy specialists, and software engineers.
- [**Phase 7A Build Notes**](./00-start-here/PHASE7A_NOTES.md): Internal build notes, editorial framing decisions, and changelog verification.

### 01 — Concepts and Workflows
- [**The Irrigation Problem**](./01-concepts-and-workflows/the-irrigation-problem.md): The realities of flood irrigation, fixed pump schedules, groundwater depletion, and electricity tariffs in rural India.
- [**How JalDrishti Decides When to Water**](./01-concepts-and-workflows/how-jaldrishti-decides-when-to-water.md): The persistent "Soil Bucket" mental model, depletion balance triggers, seasonal growth stages, and pointers to backend implementation.
- [**End-to-End Farmer Journey**](./01-concepts-and-workflows/end-to-end-farmer-journey.md): A step-by-step walkthrough from account creation and plot onboarding to real-time irrigation advisories, pump logging, and voice chat.
- [**Smart Rain Hold and Savings Explained**](./01-concepts-and-workflows/rain-hold-and-savings-explained.md): How forecast-driven pump hold-offs save diesel/power, how precision ROI is calculated post-fix, and our current 5mm/48h heuristic.
- [**JalSathi AI Explained**](./01-concepts-and-workflows/jalsathi-ai-explained.md): The conversational agronomy voice assistant, preliminary query translation, grounded ICAR PoP retrieval, 3-tier Groq fallback, and strict anti-hallucination guardrails.

### 02 — Scientific Reference
- [**Scientific Reference Index**](./02-scientific-reference/README.md): Engineering overview and technical/conceptual cross-links.
- [**Evapotranspiration and ETo**](./02-scientific-reference/evapotranspiration-and-eto.md): Full FAO-56 Penman-Monteith derivation, psychrometrics, Stefan-Boltzmann radiation, and logarithmic wind height reduction.
- [**Crop Coefficients and Growth Stages**](./02-scientific-reference/crop-coefficient-and-growth-stages.md): Dynamic $K_c(t)$ curve interpolation, late-season decay, root expansion $Z_r(t)$, and boundary state mechanics.
- [**Soil Water Balance Model**](./02-scientific-reference/soil-water-balance-model.md): Persistent root-zone depletion ($D_i$), Saxton-Rawls pedotransfer functions, database persistence, and ~5.5 km grid coarsening.
- [**Rain Hold and ROI Formulas**](./02-scientific-reference/rain-hold-and-roi-formulas.md): Rain Hold threshold triggers, date-gated skipped runs counter, and regional economic ROI derivations.
- [**Known Scientific Limitations**](./02-scientific-reference/known-scientific-limitations.md): Consolidated audit of grid coarsening, lack of physical sensor ground-truthing, static rain thresholds, and satellite outage fallback risks.

### 03 — System Architecture
- [**System Architecture Index**](./03-system-architecture/README.md): Architecture overview and audience guide.
- [**High-Level Architecture**](./03-system-architecture/high-level-architecture.md): Real component topology diagram (Mermaid) with verified stack and zero Gemini mentions.
- [**Request Lifecycle Walkthrough**](./03-system-architecture/request-lifecycle-walkthrough.md): Sequence diagram and file/line trace for `POST /api/v1/irrigation/recommendation`.
- [**Caching and Asynchronous Design**](./03-system-architecture/caching-and-async-design.md): `redis.asyncio` caching layer, TTL strategy, `run_in_threadpool` DB execution, and `asyncio.Semaphore` batching.
- [**Deployment and Infrastructure**](./03-system-architecture/deployment-and-infrastructure.md): Verified hosting configuration (Render/Railway), ~160 MB RAG RAM footprint, environment variables, and open questions.
- [**Phase 7B Build Notes**](./03-system-architecture/PHASE7B_NOTES.md): Build provenance, git verification, and open questions flagged for DevOps.

### 04 — Database Reference
- [**Database Reference Index**](./04-database-reference/README.md): Schema architecture and operational tables overview.
- [**Entity-Relationship Diagram**](./04-database-reference/entity-relationship-diagram.md): Corrected 9-table Mermaid ERD with relationships, cardinalities, and cascade behaviors.
- [**Table-by-Table Reference**](./04-database-reference/table-by-table-reference.md): Field-by-field reference for every model including types, nullability, defaults, foreign keys, and indexes.
