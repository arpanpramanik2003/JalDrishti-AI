from datetime import datetime
from sqlalchemy import Column, Integer, String, Text, DateTime, JSON
from app.db.database import Base

class DocumentEmbedding(Base):
    __tablename__ = "document_embeddings"

    id = Column(Integer, primary_key=True, index=True)
    doc_name = Column(String(100), index=True, nullable=False)
    chunk_index = Column(Integer, nullable=False)
    content = Column(Text, nullable=False)
    embedding = Column(JSON, nullable=False) # JSON list of float embedding dimensions
    created_at = Column(DateTime, default=datetime.utcnow)
