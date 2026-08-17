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
    _cached_embeddings: List[Dict[str, Any]] = None

    @classmethod
    def _get_model(cls):
        if cls._model is None:
            try:
                os.environ["TOKENIZERS_PARALLELISM"] = "false"
                os.environ["OMP_NUM_THREADS"] = "1"
                os.environ["MKL_NUM_THREADS"] = "1"
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
                if fname.endswith('.txt'):
                    fpath = os.path.join(docs_dir, fname)
                    try:
                        with open(fpath, 'r', encoding='utf-8') as f:
                            content = f.read().strip()
                            if content:
                                # Chunk large documents into 500-char passages
                                chunks = [content[i:i+600] for i in range(0, len(content), 500)]
                                for idx, chunk in enumerate(chunks):
                                    emb = cls.encode_text(chunk)
                                    if emb:
                                        rec = DocumentEmbedding(
                                            doc_name=fname,
                                            chunk_index=idx,
                                            content=chunk,
                                            embedding=emb
                                        )
                                        new_records.append(rec)
                    except Exception as err:
                        logger.error(f"[VectorSearch] Error reading {fname}: {err}")

            if new_records:
                db.bulk_save_objects(new_records)
                db.commit()
                logger.info(f"[VectorSearch] Successfully generated and stored {len(new_records)} document vector embeddings.")
                cls._cached_embeddings = None  # Reset cache so new records are reloaded
        finally:
            if close_session:
                db.close()

    _file_docs = None

    @classmethod
    def _get_local_docs(cls) -> List[Dict[str, str]]:
        if cls._file_docs is None:
            docs = []
            docs_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'data', 'pop_docs'))
            if os.path.exists(docs_dir):
                for fname in os.listdir(docs_dir):
                    if fname.endswith('.txt'):
                        fpath = os.path.join(docs_dir, fname)
                        try:
                            with open(fpath, 'r', encoding='utf-8') as f:
                                content = f.read()
                                docs.append({
                                    'doc_name': fname.replace('_guide.txt', '').upper(),
                                    'content': content
                                })
                        except Exception as e:
                            logger.warning(f"[VectorSearch] Error reading {fname}: {e}")
            cls._file_docs = docs
        return cls._file_docs

    @classmethod
    def search_semantic_chunks(cls, query: str, top_k: int = 3, db: Session = None) -> List[Dict[str, Any]]:
        """
        Ultra-Fast Zero-Overhead In-Memory Local POP Document Retriever.
        Eliminates remote PostgreSQL SSL database connection drops and 20s latency.
        """
        docs = cls._get_local_docs()
        if not docs:
            return []

        query_words = set(query.lower().split())
        scored = []
        for d in docs:
            content_lower = d['content'].lower()
            matches = sum(1 for word in query_words if len(word) > 2 and word in content_lower)
            # Extra boost if crop name matches document name
            doc_name_lower = d['doc_name'].lower()
            if any(word in doc_name_lower for word in query_words):
                matches += 3
            
            score = matches / max(len(query_words), 1)
            scored.append((score, d['content'], d['doc_name']))

        scored.sort(key=lambda x: x[0], reverse=True)
        return [{'content': content, 'doc_name': doc_name, 'similarity': score} for score, content, doc_name in scored[:top_k] if score > 0]

        scored = []
        if np is not None:
            q_arr = np.array(query_vec)
            q_norm = float(np.linalg.norm(q_arr))
            if q_norm == 0:
                return []
            for item in cls._cached_embeddings:
                d_norm = item['norm']
                if d_norm > 0:
                    similarity = float(np.dot(q_arr, item['np_vec']) / (q_norm * d_norm))
                    scored.append((similarity, item['content'], item['doc_name']))
        else:
            q_norm = math.sqrt(sum(x * x for x in query_vec))
            if q_norm == 0:
                return []
            for item in cls._cached_embeddings:
                d_norm = item['norm']
                doc_vec = item['vec']
                if d_norm > 0 and len(doc_vec) == len(query_vec):
                    dot = sum(a * b for a, b in zip(query_vec, doc_vec))
                    similarity = dot / (q_norm * d_norm)
                    scored.append((similarity, item['content'], item['doc_name']))

        scored.sort(key=lambda x: x[0], reverse=True)
        return [
            {"similarity": float(s[0]), "content": s[1], "doc_name": s[2]}
            for s in scored[:top_k]
        ]
