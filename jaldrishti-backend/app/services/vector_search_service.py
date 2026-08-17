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

class VectorSearchService:
    _model = None

    @classmethod
    def _get_model(cls):
        if cls._model is None:
            try:
                from sentence_transformers import SentenceTransformer
                logger.info("[VectorSearch] Loading SentenceTransformer model ('all-MiniLM-L6-v2')...")
                cls._model = SentenceTransformer('all-MiniLM-L6-v2')
            except Exception as e:
                logger.error(f"[VectorSearch] Failed to load SentenceTransformer: {e}")
                cls._model = None
        return cls._model

    @classmethod
    def encode_text(cls, text: str) -> List[float]:
        model = cls._get_model()
        if model:
            vec = model.encode(text, convert_to_numpy=True)
            return vec.tolist()
        return []

    @classmethod
    def initialize_and_index_docs(cls, docs_dir: str, db: Session = None):
        """
        Indexes all Package of Practices text files into the database document_embeddings table
        with dense semantic vector embeddings.
        """
        close_session = False
        if db is None:
            db = SessionLocal()
            close_session = True

        try:
            count = db.query(DocumentEmbedding).count()
            if count > 0:
                logger.info(f"[VectorSearch] Vector store already indexed with {count} document passages.")
                return

            if not os.path.exists(docs_dir):
                logger.warning(f"[VectorSearch] Docs directory missing at {docs_dir}")
                return

            logger.info(f"[VectorSearch] Indexing PoP text documents from {docs_dir} into vector database...")
            new_records = []

            for fname in os.listdir(docs_dir):
                if fname.endswith(".txt"):
                    fpath = os.path.join(docs_dir, fname)
                    try:
                        with open(fpath, "r", encoding="utf-8") as f:
                            content = f.read()
                            paras = [p.strip() for p in content.split("\n\n") if len(p.strip()) > 30]
                            for idx, p in enumerate(paras):
                                vec = cls.encode_text(p)
                                if vec:
                                    doc_emb = DocumentEmbedding(
                                        doc_name=fname,
                                        chunk_index=idx,
                                        content=p,
                                        embedding=vec
                                    )
                                    new_records.append(doc_emb)
                    except Exception as err:
                        logger.error(f"[VectorSearch] Error reading {fname}: {err}")

            if new_records:
                db.bulk_save_objects(new_records)
                db.commit()
                logger.info(f"[VectorSearch] Successfully generated and stored {len(new_records)} document vector embeddings.")
        finally:
            if close_session:
                db.close()

    @classmethod
    def search_semantic_chunks(cls, query: str, top_k: int = 3, db: Session = None) -> List[Dict[str, Any]]:
        """
        Performs dense vector cosine similarity search against stored document embeddings.
        """
        query_vec = cls.encode_text(query)
        if not query_vec:
            return []

        close_session = False
        if db is None:
            db = SessionLocal()
            close_session = True

        try:
            records = db.query(DocumentEmbedding).all()
            if not records:
                docs_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'data', 'pop_docs'))
                cls.initialize_and_index_docs(docs_dir, db=db)
                records = db.query(DocumentEmbedding).all()
                
            if not records:
                return []

            scored = []
            if np is not None:
                q_norm = np.linalg.norm(query_vec)
                if q_norm == 0:
                    return []
                for rec in records:
                    doc_vec = np.array(rec.embedding)
                    d_norm = np.linalg.norm(doc_vec)
                    if d_norm > 0:
                        similarity = float(np.dot(query_vec, doc_vec) / (q_norm * d_norm))
                        scored.append((similarity, rec.content, rec.doc_name))
            else:
                # Pure Python Fallback (No numpy dependency needed)
                q_norm = math.sqrt(sum(x * x for x in query_vec))
                if q_norm == 0:
                    return []
                for rec in records:
                    doc_vec = rec.embedding or []
                    if len(doc_vec) == len(query_vec):
                        dot = sum(a * b for a, b in zip(query_vec, doc_vec))
                        d_norm = math.sqrt(sum(x * x for x in doc_vec))
                        if d_norm > 0:
                            similarity = dot / (q_norm * d_norm)
                            scored.append((similarity, rec.content, rec.doc_name))

            scored.sort(key=lambda x: x[0], reverse=True)
            top_results = []
            for sim, text, name in scored[:top_k]:
                top_results.append({"similarity": sim, "content": text, "doc_name": name})
            return top_results
        finally:
            if close_session:
                db.close()
