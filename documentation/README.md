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
| `02-architecture/` *(Future Phase)* | **System Architecture**: High-level block diagrams, data flows, FastAPI backend structure, Flutter client layout, and caching topology. | Software engineers, cloud architects, DevOps engineers. |
| `03-hydrology-engine/` *(Future Phase)* | **Hydrology & Science Reference**: FAO-56 Penman-Monteith formulas, persistent water bucket equations, soil depletion balance, and root depth dynamics. | Hydrologists, agricultural scientists, backend engineers. |
| `04-api-reference/` *(Future Phase)* | **REST API Contracts**: Endpoint specifications, schemas, authentication flows, error handling, and rate limits. | Mobile developers, API consumers, frontend engineers. |
| `05-jalsathi-ai/` *(Future Phase)* | **JalSathi AI Pipeline**: Vector search embeddings, ChromaDB schema, Groq multi-tier fallback, and safety guardrails. | AI/ML engineers, prompt engineers. |
| `06-operations-and-deployment/` *(Future Phase)* | **DevOps & Operations**: Local development setup, Docker, environment configuration, database migrations, and monitoring. | DevOps, SREs, system administrators. |
| `07-known-limitations/` *(Future Phase)* | **Limitations & Roadmap**: Transparent audit of known constraints, satellite resolution trade-offs, and future improvements. | All technical and product stakeholders. |

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
