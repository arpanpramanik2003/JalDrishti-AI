import os
import math
import logging
from typing import List, Dict, Any
from sqlalchemy.orm import Session
from app.db.database import SessionLocal
from app.models.document_embedding import DocumentEmbedding

try:
    import numpy as np
except ImportError:
    np = None

logger = logging.getLogger("jaldrishti.vector_search")

import os
import logging
from typing import List, Dict, Any, Optional

logger = logging.getLogger("jaldrishti.vector_search")

class VectorSearchService:
    _model = None
    _chroma_client = None
    _chroma_collection = None
    CHROMA_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'data', 'chroma_db'))
    COLLECTION_NAME = "jaldrishti_pop_docs"
    DEFAULT_SIMILARITY_THRESHOLD = 0.35

    @classmethod
    def _get_model(cls):
        """Lazy loader for SentenceTransformer model ('all-MiniLM-L6-v2')."""
        if cls._model is None:
            try:
                os.environ["TOKENIZERS_PARALLELISM"] = "false"
                os.environ["OMP_NUM_THREADS"] = "1"
                os.environ["MKL_NUM_THREADS"] = "1"
                from sentence_transformers import SentenceTransformer
                logger.info("[VectorSearch] Loading SentenceTransformer ('all-MiniLM-L6-v2')...")
                cls._model = SentenceTransformer('all-MiniLM-L6-v2')
            except Exception as e:
                logger.error(f"[VectorSearch] Failed to load SentenceTransformer: {e}")
                cls._model = None
        return cls._model

    @classmethod
    def encode_text(cls, text: str) -> List[float]:
        """Encodes text into a 384-dimensional dense vector."""
        model = cls._get_model()
        if model:
            vec = model.encode(text, convert_to_numpy=True)
            return vec.tolist()
        return []

    @classmethod
    def _get_collection(cls):
        """Connects to the persistent ChromaDB collection, auto-ingesting if necessary."""
        if cls._chroma_collection is None:
            try:
                import chromadb
                if cls._chroma_client is None:
                    cls._chroma_client = chromadb.PersistentClient(path=cls.CHROMA_DIR)

                try:
                    cls._chroma_collection = cls._chroma_client.get_collection(cls.COLLECTION_NAME)
                    if cls._chroma_collection.count() == 0:
                        raise ValueError("Chroma collection empty")
                except Exception:
                    logger.info(f"[VectorSearch] Collection '{cls.COLLECTION_NAME}' not found or empty. Running ingestion...")
                    from app.scripts.ingest_pop_docs import ingest_pop_documents
                    ingest_pop_documents()
                    cls._chroma_collection = cls._chroma_client.get_collection(cls.COLLECTION_NAME)

                logger.info(f"[VectorSearch] ChromaDB connected to '{cls.COLLECTION_NAME}' with {cls._chroma_collection.count()} chunks.")
            except Exception as e:
                logger.error(f"[VectorSearch] ChromaDB connection failed: {e}")
                cls._chroma_collection = None
        return cls._chroma_collection

    @classmethod
    def initialize_and_index_docs(cls, docs_dir: str = None, db=None):
        """Ensures ChromaDB collection is initialized and indexed."""
        cls._get_collection()

    @classmethod
    def search_semantic_chunks(
        cls,
        query: str,
        top_k: int = 3,
        similarity_threshold: float = None,
        crop_filter: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        True Dense Vector Semantic Retrieval against ChromaDB:
        1. Encodes query into 384-d embedding via all-MiniLM-L6-v2.
        2. Queries ChromaDB persistent vector collection by cosine distance.
        3. Converts distance to cosine similarity (1.0 - distance).
        4. Applies minimum similarity threshold; returns [] if no chunk meets the bar.
        """
        threshold = similarity_threshold if similarity_threshold is not None else cls.DEFAULT_SIMILARITY_THRESHOLD
        col = cls._get_collection()
        if col is None:
            logger.warning("[VectorSearch] Chroma collection unavailable. Returning empty context.")
            return []

        q_clean = query.strip()
        if not q_clean:
            return []

        q_vec = cls.encode_text(q_clean)
        if not q_vec:
            logger.warning("[VectorSearch] Failed to encode query. Returning empty context.")
            return []

        try:
            where_clause = None
            if crop_filter:
                where_clause = {"crop": crop_filter.replace("_", " ").title()}

            results = col.query(
                query_embeddings=[q_vec],
                n_results=top_k,
                where=where_clause
            )

            if not results or not results.get("documents") or not results["documents"][0]:
                return []

            docs = results["documents"][0]
            distances = results["distances"][0]
            metadatas = results["metadatas"][0]

            matched = []
            for doc, dist, meta in zip(docs, distances, metadatas):
                similarity = 1.0 - float(dist)
                if similarity >= threshold:
                    matched.append({
                        "similarity": round(similarity, 4),
                        "content": doc,
                        "doc_name": meta.get("doc_name", "guide.txt"),
                        "crop": meta.get("crop", "General"),
                        "section": meta.get("section", "")
                    })

            # Sort by similarity descending
            matched.sort(key=lambda x: x["similarity"], reverse=True)
            logger.info(f"[VectorSearch] Query '{query[:40]}...' matched {len(matched)} chunks above threshold {threshold}.")
            return matched

        except Exception as err:
            logger.error(f"[VectorSearch] Chroma query error: {err}")
            return []
