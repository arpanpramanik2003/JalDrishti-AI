# Retrieval Pipeline: Dense Vector Embeddings & ChromaDB

> **Audience**: AI/ML engineers, data scientists, and backend developers.  
> **Source Modules**:  
> - [`app/services/vector_search_service.py`](file:///d:/jaldrishti/jaldrishti-backend/app/services/vector_search_service.py)  
> - [`app/scripts/ingest_pop_docs.py`](file:///d:/jaldrishti/jaldrishti-backend/app/scripts/ingest_pop_docs.py)  
> - Knowledge Base Directory: [`app/data/pop_docs/`](file:///d:/jaldrishti/jaldrishti-backend/app/data/pop_docs/)  
> **Dependencies**: `chromadb==1.5.9`, `sentence-transformers==5.6.1`

---

## 1. Pipeline Overview

In legacy versions of the backend, vector search was dead code that fell back to naive substring matching. Phase 5 ([`PHASE5_CHANGELOG.md`](file:///d:/jaldrishti/PHASE5_CHANGELOG.md)) rebuilt the retrieval engine from scratch using a local, high-performance dense semantic vector pipeline:

```
[Raw ICAR PoP Markdown Guides]
             |
             v
[Offline Chunking: Section-Aware Parsing]
             |
             v
[SentenceTransformer: all-MiniLM-L6-v2 (384-d)]
             |
             v
[ChromaDB 1.5.9: Persistent SQLite Store] (jaldrishti_pop_docs)
             |
    +--------+--------+
    |                 |
[Online Query]        |
    |                 v
[Dense Embedding] --> [Cosine Distance Match] --> [Threshold Filter (>= 0.35)] --> [Top 3 Context Chunks]
```

---

## 2. Ingestion & Document Chunking Strategy

Document ingestion is handled by [`app/scripts/ingest_pop_docs.py`](file:///d:/jaldrishti/jaldrishti-backend/app/scripts/ingest_pop_docs.py). Rather than using arbitrary fixed-character window chunking (e.g. 500 characters with 50-character overlap), which frequently slices chemical dosages in half, JalDrishti employs **agronomic section-aware chunking**:

1. **Source Documents**: Authoritative regional Package of Practices (PoP) guidelines from ICAR and State Agricultural Universities (Bidhan Chandra Krishi Viswavidyalaya, West Bengal, and Punjab Agricultural University) covering major crops:
   - Paddy Rice (`paddy_rice_wb.md`)
   - Wheat (`wheat_pop.md`)
   - Mustard (`mustard_pop.md`)
   - Potato (`potato_pop.md`)
   - Maize (`maize_pop.md`)
   - Tomato (`tomato_pop.md`)
   - Onion (`onion_pop.md`)
2. **Parsing Logic**: Markdown headers (`##`, `###`) are parsed into cohesive functional units:
   - Sowing & Seed Treatment
   - Nutrient & Fertilizer Scheduling
   - Water Management & Critical Irrigation Stages
   - Pest & Insect Management
   - Fungal & Bacterial Disease Control
   - Harvesting & Post-Harvest Dry-Down
3. **Metadata Enrichment**: Every chunk is indexed with metadata tags: `crop`, `section`, and `source`.

---

## 3. Dense Embedding Model (`all-MiniLM-L6-v2`)

- **Architecture**: 6-layer MiniLM transformer mapping text to a 384-dimensional dense vector space.
- **Resource Footprint**:
  - Model disk footprint: $\approx 80\text{ MB}$
  - Peak RAM on CPU during embedding: $\approx 120\text{ MB}$
- **Threading Optimization** ([`vector_search_service.py:35-37`](file:///d:/jaldrishti/jaldrishti-backend/app/services/vector_search_service.py#L35-L37)):
  ```python
  os.environ["TOKENIZERS_PARALLELISM"] = "false"
  os.environ["OMP_NUM_THREADS"] = "1"
  os.environ["MKL_NUM_THREADS"] = "1"
  ```
  Enforces single-threaded CPU inference to prevent thread-pool contention with FastAPI's asynchronous event loop.

---

## 4. ChromaDB Collection & Storage

- **Persistence Mode**: ChromaDB 1.5.9 running as an embedded persistent client (`chromadb.PersistentClient(path=cls.CHROMA_DIR)`).
- **Directory Location**: `app/data/chroma_db/`
- **Collection Name**: `jaldrishti_pop_docs`
- **Distance Metric**: Cosine Distance ($d_{\text{cosine}} \in [0, 2]$).

---

## 5. Online Semantic Search Execution (`search_semantic_chunks`)

When a user query arrives ([`vector_search_service.py:86-150`](file:///d:/jaldrishti/jaldrishti-backend/app/services/vector_search_service.py#L86-L150)):
1. **Query Encoding**: The query is converted into a 384-d dense vector.
2. **ChromaDB Query**:
   ```python
   results = collection.query(
       query_embeddings=[query_vec],
       n_results=top_k, # default: 3
       where={"crop": crop_filter} if crop_filter else None
   )
   ```
3. **Cosine Similarity Conversion**:
   ChromaDB returns cosine distances. The service converts distances to similarity scores:
   $$\text{similarity} = 1.0 - \text{distance}$$
4. **Strict Minimum Similarity Thresholding**:
   ```python
   DEFAULT_SIMILARITY_THRESHOLD = 0.35
   ```
   Every candidate chunk must meet or exceed `similarity >= 0.35`. If a query is unrelated to agriculture (e.g. *"What is the capital of France?"*), all chunks score below 0.35 and the function returns an empty list `[]`. This prevents injecting misleading agricultural text into unrelated queries.
