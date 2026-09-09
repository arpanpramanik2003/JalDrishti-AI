# How to Navigate this Documentation

This documentation set is designed to serve a diverse group of readers: agricultural officers, field extension agents, investors, software architects, and mobile developers. To make your reading efficient, this guide outlines the organization of the documentation and suggests specific reading paths based on your role.

---

## 🗂️ Folder Organization Scheme

The documentation follows a strictly ordered numeric hierarchy:

```text
documentation/
├── README.md                          # Master index and overview
├── 00-start-here/                     # Non-technical fundamentals & navigation
├── 01-concepts-and-workflows/         # Core agronomy mental models & user flows
├── 02-architecture/                   # High-level system design & service topology
├── 03-hydrology-engine/               # Mathematical & scientific reference (FAO-56)
├── 04-api-reference/                  # Backend REST API contracts & schemas
├── 05-jalsathi-ai/                    # Vector search, embeddings & LLM fallback
├── 06-operations-and-deployment/      # Runbooks, configuration, caching & Docker
└── 07-known-limitations/              # Transparent engineering constraints & audit
```

- **00 to 01 (Conceptual & Operational)**: Written in plain, accessible language with relatable analogies. Focuses on *what* the system does and *why* it behaves that way.
- **02 to 06 (Deep Technical Reference)**: Targeted at software developers, cloud engineers, and data scientists building, deploying, or testing the platform.
- **07 (Limitations & Integrity)**: A frank, transparent summary of technical boundaries, scientific trade-offs, and future roadmap items.

---

## 🧭 Suggested Reading Paths

Choose the path that best matches your immediate goal:

### Path A: The Non-Technical & Business Reader
*(For investors, agriculture ministry partners, project sponsors, and new team members)*

1. [**What is JalDrishti?**](./what-is-jaldrishti.md): Understand the core problem of flood irrigation, why physical sensors fail smallholders, and how satellite modeling works.
2. [**The Irrigation Problem**](../01-concepts-and-workflows/the-irrigation-problem.md): Learn why calendar-based irrigation wastes water and money in rural India.
3. [**How JalDrishti Decides When to Water**](../01-concepts-and-workflows/how-jaldrishti-decides-when-to-water.md): Understand the "Soil Water Bucket" mental model without getting bogged down in equations.
4. [**End-to-End Farmer Journey**](../01-concepts-and-workflows/end-to-end-farmer-journey.md): Walk through what a farmer actually experiences on their phone from planting to harvest.
5. [**Rain Hold and Savings Explained**](../01-concepts-and-workflows/rain-hold-and-savings-explained.md): Discover how weather forecasts save pump fuel and how financial ROI is calculated.
6. [**JalSathi AI Explained**](../01-concepts-and-workflows/jalsathi-ai-explained.md): See how the voice assistant works and why it refuses to invent unverified chemical dosages.

### Path B: The Agronomist & Field Extension Specialist
*(For Krishi Vigyan Kendra (KVK) officers, agronomists, and farm managers)*

1. [**What is JalDrishti?**](./what-is-jaldrishti.md): High-level overview of capabilities and trade-offs.
2. [**How JalDrishti Decides When to Water**](../01-concepts-and-workflows/how-jaldrishti-decides-when-to-water.md): Detailed explanation of field capacity, wilting point, RAW, and crop growth stages.
3. [**Rain Hold and Savings Explained**](../01-concepts-and-workflows/rain-hold-and-savings-explained.md): Criteria for rain hold-offs and cumulative water balance calculations.
4. [**JalSathi AI Explained**](../01-concepts-and-workflows/jalsathi-ai-explained.md): Verification against ICAR Package of Practices (PoP) guidelines.
5. *(Future Phase)* **03-hydrology-engine/**: Deep dive into crop coefficients ($K_c$), root zone depth ($Z_r$), and depletion balance formulas ($D_{r,i}$).

### Path C: The Software Engineer & Mobile Developer
*(For backend engineers, mobile developers, and DevOps contributors)*

1. **Skim** [**What is JalDrishti?**](./what-is-jaldrishti.md) for domain grounding.
2. **Review "For Technical Readers"** sections at the end of every file in `01-concepts-and-workflows/` for exact file pointers and function names.
3. *(Future Phase)* **02-architecture/**: Multi-tier service topology, Redis caching layer, and background task architecture.
4. *(Future Phase)* **04-api-reference/**: REST endpoints, JWT authentication, and Pydantic validation schemas.
5. *(Future Phase)* **05-jalsathi-ai/**: ChromaDB vector store, `all-MiniLM-L6-v2` embeddings, and Groq fallback cascade.
6. *(Future Phase)* **06-operations-and-deployment/**: Running FastAPI and Flutter locally, managing environment variables, and executing the test suite.
