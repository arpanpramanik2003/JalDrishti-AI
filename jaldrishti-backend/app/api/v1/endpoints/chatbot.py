from typing import Optional
from fastapi import APIRouter
from pydantic import BaseModel, Field
from app.services.rag_service import RAGService

router = APIRouter()
rag_service = RAGService()

class ChatRequest(BaseModel):
    query: str = Field(..., min_length=1, max_length=500, example="How do I control Stem Borer in paddy?", description="Farmer query text")
    language: str = Field(default="English", max_length=20, example="Bengali", description="Target response language (English, Bengali, Hindi)")
    farmer_name: Optional[str] = Field(default=None, max_length=50, description="Farmer display name for personalizing response")
    location_name: Optional[str] = Field(default=None, max_length=100, description="Farm location/district")
    current_crop: Optional[str] = Field(default=None, max_length=50, description="Currently selected crop")
    farm_area_acres: Optional[float] = Field(default=None, ge=0.01, le=10000.0, description="Land area in acres")

class ChatResponse(BaseModel):
    query: str
    language: str
    response: str

@router.post("/query", response_model=ChatResponse)
async def ask_agri_bot(payload: ChatRequest):
    answer = await rag_service.answer_farmer_query_async(
        query=payload.query,
        language=payload.language,
        farmer_name=payload.farmer_name,
        location_name=payload.location_name,
        current_crop=payload.current_crop,
        farm_area_acres=payload.farm_area_acres
    )
    return ChatResponse(
        query=payload.query,
        language=payload.language,
        response=answer
    )