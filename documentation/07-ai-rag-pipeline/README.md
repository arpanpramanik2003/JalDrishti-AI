# JalSathi AI: Agronomic RAG Pipeline Reference

> **Notice for Readers**: This section is written for AI/ML engineers, prompt engineers, and backend system developers. For a plain-language explanation of how JalSathi AI assists farmers in vernacular scripts, see [JalSathi AI Explained](../01-concepts-and-workflows/jalsathi-ai-explained.md).

---

## Overview

**JalSathi AI** (জলসাথী AI) is an agronomic conversational decision-support assistant engineered specifically for Indian smallholder farmers. Rebuilt in **Phase 5**, the pipeline is **100% Groq-native** and combines dense vector embeddings, preliminary multilingual translation, strict anti-hallucination prompt constraints, and a genuine three-tier fallback cascade.

> [!IMPORTANT]
> **Complete Gemini Removal**:
> The system does not utilize Google Gemini or any external proprietary translation APIs. All mentions of Gemini in legacy documentation have been purged and superseded by this verified architecture.

---

## Documents in this Section & Conceptual Equivalents

| RAG Technical Document | Focus & Scope | Conceptual Equivalent |
|:-----------------------|:--------------|:----------------------|
| [`retrieval-pipeline-explained.md`](retrieval-pipeline-explained.md) | Ingestion pipeline, section chunking strategy, `all-MiniLM-L6-v2` dense embeddings, ChromaDB 1.5.9 persistent storage, and cosine similarity filtering ($\ge 0.35$). | [`01-concepts-and-workflows/jalsathi-ai-explained.md`](../01-concepts-and-workflows/jalsathi-ai-explained.md) |
| [`multilingual-translation-step.md`](multilingual-translation-step.md) | Preliminary query translation hop via fast Groq inference, bridging Bengali/Hindi vernacular inputs to English agronomy documents without adding third-party APIs. | [`01-concepts-and-workflows/jalsathi-ai-explained.md`](../01-concepts-and-workflows/jalsathi-ai-explained.md) |
| [`fallback-cascade-and-groq-models.md`](fallback-cascade-and-groq-models.md) | The verified 3-tier cascade: Tier 1 Primary Groq (`openai/gpt-oss-20b`) $\to$ Tier 2 Fast Groq (`groq/compound-mini`) $\to$ Tier 3 Local Deterministic Fallback (ICAR chunk formatter without LLM). | [`01-concepts-and-workflows/jalsathi-ai-explained.md`](../01-concepts-and-workflows/jalsathi-ai-explained.md) |
| [`prompt-and-grounding-safeguards.md`](prompt-and-grounding-safeguards.md) | Grounded system prompt design, Pydantic structured output validation (`StructuredDualSolution`), and post-generation active ingredient guardrails with honest limitations. | [`01-concepts-and-workflows/jalsathi-ai-explained.md`](../01-concepts-and-workflows/jalsathi-ai-explained.md) |
| [`PHASE7C_NOTES.md`](PHASE7C_NOTES.md) | Build provenance and verification notes for documentation Phase 7C. | N/A (Internal engineering) |

---

## Core Source Code Directory

- RAG Orchestrator & Multi-Turn Session Engine: [`app/services/rag_service.py`](file:///d:/jaldrishti/jaldrishti-backend/app/services/rag_service.py)
- Vector Embeddings & ChromaDB Collection: [`app/services/vector_search_service.py`](file:///d:/jaldrishti/jaldrishti-backend/app/services/vector_search_service.py)
- Offline Ingestion Script: [`app/scripts/ingest_pop_docs.py`](file:///d:/jaldrishti/jaldrishti-backend/app/scripts/ingest_pop_docs.py)
- Source ICAR Package of Practices Guides: [`app/data/pop_docs/`](file:///d:/jaldrishti/jaldrishti-backend/app/data/pop_docs/)
