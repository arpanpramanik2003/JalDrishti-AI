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
| [`05-api-reference/`](./05-api-reference/README.md) | **REST API Reference**: Complete endpoint contracts, schemas, authentication rules, and error codes across all 24 application routes. | Mobile developers, backend integrators, QA automation. |
| [`06-mobile-app-reference/`](./06-mobile-app-reference/README.md) | **Mobile Application Reference**: Flutter screen-by-screen breakdown, state management (6 Providers), Hive offline sync, and localization status. | Flutter mobile developers, UI/UX engineers. |
| [`07-ai-rag-pipeline/`](./07-ai-rag-pipeline/README.md) | **JalSathi AI Pipeline**: Dense vector search (ChromaDB + all-MiniLM-L6-v2), fast Groq translation, 3-tier cascade, and chemical safety guardrails. | AI/ML engineers, prompt engineers, NLP specialists. |
| [`08-limitations-and-roadmap/`](./08-limitations-and-roadmap/README.md) | **Limitations & Roadmap**: Master consolidated limitations catalog, de-duplicated open developer questions, and remediation history matrix. | Engineering leadership, auditors, product managers. |

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

### 05 — API Reference
- [**REST API Reference Index**](./05-api-reference/README.md): API catalog, global JWT & Admin authentication standards, base URLs.
- [**Authentication & Security**](./05-api-reference/authentication-and-security.md): 11 auth endpoints, profile PUT fix [F-03], password reset field fix [F-04].
- [**Farm Plots & Crops**](./05-api-reference/farm-plots-and-crops.md): 6 endpoints covering CRUD plot lifecycle, primary plot toggles, and public crop catalog.
- [**Irrigation & Recommendations**](./05-api-reference/irrigation-and-recommendations.md): 3 endpoints covering recommendation generation, manual logging, and history.
- [**Chatbot & Advisory**](./05-api-reference/chatbot-and-advisory.md): 2 endpoints covering JalSathi AI RAG queries and authenticated pest advisory evaluations.
- [**Admin & Internal Endpoints**](./05-api-reference/admin-and-internal-endpoints.md): 7 endpoints covering admin tariffs, manual batch cron triggers, and health check probes.

### 06 — Mobile Application Reference
- [**Mobile Application Index**](./06-mobile-app-reference/README.md): Flutter client architecture overview and cross-links.
- [**Screen-by-Screen Reference**](./06-mobile-app-reference/screen-by-screen-reference.md): Detailed reference for 10 major screens + 5 analytics tabs with APIs, providers, and Phase 6 status.
- [**State Management & Providers**](./06-mobile-app-reference/state-management-and-providers.md): 6 Providers (Auth, FarmPlot, Irrigation, Chat, Notification, Theme) & centralized 401 interceptor integration.
- [**Offline & Sync Behavior**](./06-mobile-app-reference/offline-and-sync-behavior.md): Hive boxes (`jaldrishti_cache`, `jaldrishti_sync_queue`), sync replay engine, offline matrix, and `FLAG-P4-01` date serialization finding.
- [**Localization Status**](./06-mobile-app-reference/localization-status.md): ARB key coverage analysis (14/14 keys translated in `en`, `bn`, `hi`), screen-by-screen hardcoded audit (53 files), and contributor guide.

### 07 — AI & RAG Pipeline
- [**AI / RAG Pipeline Index**](./07-ai-rag-pipeline/README.md): Overview of the 100% Groq-native RAG pipeline.
- [**Retrieval Pipeline Explained**](./07-ai-rag-pipeline/retrieval-pipeline-explained.md): Ingestion script, section-aware chunking, `all-MiniLM-L6-v2` dense vectors, ChromaDB 1.5.9 SQLite store, and cosine similarity filtering.
- [**Multilingual Translation Step**](./07-ai-rag-pipeline/multilingual-translation-step.md): Fast preliminary Groq translation hop for Indic queries, unicode detection logic, and latency trade-offs.
- [**Fallback Cascade & Groq Models**](./07-ai-rag-pipeline/fallback-cascade-and-groq-models.md): Genuine 3-tier cascade (Tier 1 Groq $\to$ Tier 2 Fast Groq $\to$ Tier 3 Local Deterministic Fallback) and confirmation of zero Gemini references.
- [**Prompt & Grounding Safeguards**](./07-ai-rag-pipeline/prompt-and-grounding-safeguards.md): Grounded system prompt rewrite, Pydantic structured output schemas, and post-generation active ingredient guardrail.
- [**Phase 7C Build Notes**](./07-ai-rag-pipeline/PHASE7C_NOTES.md): Build provenance, git verification, and open questions.

### 08 — Limitations & Engineering Roadmap
- [**Limitations & Roadmap Index**](./08-limitations-and-roadmap/README.md): Plain-language summary and roadmap overview.
- [**Consolidated Known Limitations**](./08-limitations-and-roadmap/known-limitations-consolidated.md): Master catalog of all scientific, mobile, and infrastructure limitations, classified as RESOLVED, PARTIALLY MITIGATED, or UNRESOLVED.
- [**Open Questions for Developers**](./08-limitations-and-roadmap/open-questions-for-the-developer.md): De-duplicated backlog of open architectural questions across hydrology, DevOps, mobile localization, and RAG.
- [**Remediation History Matrix**](./08-limitations-and-roadmap/remediation-history.md): Definitive timeline and finding-by-finding status matrix from original audit through all 6 code phases and 4 documentation phases.
- [**Phase 7D Close-out Notes**](./08-limitations-and-roadmap/PHASE7D_NOTES.md): Final build provenance and explicit safety assessment of satellite outage fallback behavior.

---

> [!TIP]
> **Looking for what still needs work?**  
> If you want the short, honest summary of current platform limitations, safety risks, and open developer questions without reading the entire documentation set, jump straight to [**08 — Limitations and Roadmap**](./08-limitations-and-roadmap/README.md).
