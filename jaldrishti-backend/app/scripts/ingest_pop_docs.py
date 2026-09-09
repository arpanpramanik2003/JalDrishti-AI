import os
import sys
import re
import logging
from typing import List, Dict, Any

# Ensure backend root is on sys.path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..')))

import chromadb
from sentence_transformers import SentenceTransformer

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("jaldrishti.ingest")

CHROMA_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'data', 'chroma_db'))
DOCS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'data', 'pop_docs'))
COLLECTION_NAME = "jaldrishti_pop_docs"
MODEL_NAME = "all-MiniLM-L6-v2"

def extract_chunks_from_file(filepath: str) -> List[Dict[str, Any]]:
    """
    Parses a Package of Practices text guide into logical, highly coherent semantic chunks
    split by domain section (Water Management, Pest & Disease Control, Fertilizer Application).
    """
    fname = os.path.basename(filepath)
    crop_name = fname.replace("_guide.txt", "").replace("_", " ").title()

    with open(filepath, "r", encoding="utf-8") as f:
        text = f.read().strip()

    # Split into logical sections by major numbered headings
    sections = re.split(r'\n(?=\d+\.\s+[A-Z\s&/]+:)', text)
    chunks = []

    header = ""
    if sections and not re.match(r'^\d+\.\s+', sections[0]):
        header = sections[0].strip()
        sections = sections[1:]

    for sec in sections:
        sec_text = sec.strip()
        if not sec_text:
            continue

        # Extract section title (e.g. "1. WATER & IRRIGATION MANAGEMENT:")
        title_match = re.match(r'^(\d+\.\s+[^\n:]+):?', sec_text)
        sec_title = title_match.group(1).strip() if title_match else "General Practice"

        # If section is Pest & Disease control and contains multiple pests, sub-chunk by pest for precision
        if "PEST" in sec_title.upper() and ("\n- " in sec_text or "\n* " in sec_text):
            pest_items = re.split(r'\n(?=- [A-Z])', sec_text)
            # First element has the section title
            intro = pest_items[0]
            for p in pest_items[1:]:
                chunk_content = f"{header}\n\n{sec_title}:\n{p.strip()}"
                chunks.append({
                    "crop": crop_name,
                    "doc_name": fname,
                    "section": sec_title,
                    "content": chunk_content
                })
        else:
            chunk_content = f"{header}\n\n{sec_text}"
            chunks.append({
                "crop": crop_name,
                "doc_name": fname,
                "section": sec_title,
                "content": chunk_content
            })

    return chunks

def ingest_pop_documents():
    """Reads all PoP guide files, embeds with all-MiniLM-L6-v2, and saves to ChromaDB."""
    logger.info(f"Starting PoP document ingestion from {DOCS_DIR}")
    if not os.path.exists(DOCS_DIR):
        logger.error(f"Documents directory not found: {DOCS_DIR}")
        return False

    os.makedirs(CHROMA_DIR, exist_ok=True)
    client = chromadb.PersistentClient(path=CHROMA_DIR)

    # Recreate collection with cosine distance metric
    try:
        client.delete_collection(COLLECTION_NAME)
        logger.info(f"Existing collection '{COLLECTION_NAME}' deleted for fresh ingestion.")
    except Exception:
        pass

    collection = client.create_collection(
        name=COLLECTION_NAME,
        metadata={"hnsw:space": "cosine"}
    )

    logger.info(f"Loading SentenceTransformer model: {MODEL_NAME}")
    model = SentenceTransformer(MODEL_NAME)

    all_chunks = []
    for fname in sorted(os.listdir(DOCS_DIR)):
        if fname.endswith(".txt"):
            fpath = os.path.join(DOCS_DIR, fname)
            file_chunks = extract_chunks_from_file(fpath)
            all_chunks.extend(file_chunks)
            logger.info(f"Processed {fname}: extracted {len(file_chunks)} chunks.")

    logger.info(f"Total extracted semantic chunks across all crops: {len(all_chunks)}")

    ids = []
    documents = []
    metadatas = []
    embeddings = []

    for idx, c in enumerate(all_chunks):
        chunk_id = f"pop_{c['doc_name'].replace('.txt', '')}_{idx:03d}"
        content = c["content"]
        emb = model.encode(content, convert_to_numpy=True).tolist()

        ids.append(chunk_id)
        documents.append(content)
        metadatas.append({
            "crop": c["crop"],
            "doc_name": c["doc_name"],
            "section": c["section"]
        })
        embeddings.append(emb)

    collection.add(
        ids=ids,
        documents=documents,
        metadatas=metadatas,
        embeddings=embeddings
    )

    logger.info(f"Successfully indexed {len(ids)} chunks into Chroma collection '{COLLECTION_NAME}' at {CHROMA_DIR}!")
    return True

if __name__ == "__main__":
    success = ingest_pop_documents()
    sys.exit(0 if success else 1)
