from typing import Optional
from fastapi import APIRouter
from pydantic import BaseModel, Field
from app.services.rag_service import RAGService
from app.services.weather_service import WeatherService

router = APIRouter()

# Lazy singleton instance to prevent blocking Uvicorn port binding on startup
_rag_service_instance: Optional[RAGService] = None

def get_rag_service() -> RAGService:
    global _rag_service_instance
    if _rag_service_instance is None:
        print("[Info] Lazy-initializing RAG Engine & Vector Store...")
        _rag_service_instance = RAGService()
    return _rag_service_instance

class ChatRequest(BaseModel):
    query: str = Field(..., min_length=1, max_length=500, example="Will it rain tomorrow?", description="Farmer query text")
    language: str = Field(default="English", max_length=20, example="Bengali", description="Target response language (English, Bengali, Hindi)")
    farmer_name: Optional[str] = Field(default=None, max_length=50, description="Farmer display name for personalizing response")
    location_name: Optional[str] = Field(default=None, max_length=100, description="Farm location/district")
    current_crop: Optional[str] = Field(default=None, max_length=50, description="Currently selected crop")
    farm_area_acres: Optional[float] = Field(default=None, ge=0.01, le=10000.0, description="Land area in acres")
    latitude: Optional[float] = Field(default=None, ge=-90.0, le=90.0, description="Farm plot latitude for live weather forecast")
    longitude: Optional[float] = Field(default=None, ge=-180.0, le=180.0, description="Farm plot longitude for live weather forecast")

class ChatResponse(BaseModel):
    query: str
    language: str
    response: str

@router.post("/query", response_model=ChatResponse)
async def ask_agri_bot(payload: ChatRequest):
    rag = get_rag_service()

    # Fetch live satellite weather forecast telemetry for farmer's location
    weather_data = None
    lat = payload.latitude if payload.latitude is not None else 22.5726
    lon = payload.longitude if payload.longitude is not None else 88.3639

    try:
        weather_data = await WeatherService.fetch_realtime_weather(lat, lon, past_days=1, forecast_days=5)
    except Exception as e:
        print(f"[Warning] Chatbot Weather fetch error: {e}")

    answer = await rag.answer_farmer_query_async(
        query=payload.query,
        language=payload.language,
        farmer_name=payload.farmer_name,
        location_name=payload.location_name,
        current_crop=payload.current_crop,
        farm_area_acres=payload.farm_area_acres,
        weather_data=weather_data
    )
    return ChatResponse(
        query=payload.query,
        language=payload.language,
        response=answer
    )