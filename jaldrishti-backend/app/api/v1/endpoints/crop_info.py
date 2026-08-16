import json
import os
from typing import Optional
from fastapi import APIRouter, HTTPException, Header
from pydantic import BaseModel, Field
from app.core.config import settings
from app.engine.pest_disease_engine import PestDiseaseEngine
from app.services.weather_service import WeatherService

router = APIRouter()

from app.services.crop_config_service import CropConfigService

class PestAdvisoryRequest(BaseModel):
    crop_id: str = Field(..., example="paddy_rice", description="Crop identifier")
    latitude: float = Field(..., example=22.5726, description="Farm Latitude")
    longitude: float = Field(..., example=88.3639, description="Farm Longitude")

@router.get("/all")
def get_all_crops():
    """Dynamically returns all crops supported by the JalDrishti engine from memory cache."""
    crop_list = CropConfigService.get_all_crops()
    return {"status": "success", "total_crops": len(crop_list), "crops": crop_list}

@router.post("/pest-advisory")
async def get_weather_pest_advisory(payload: PestAdvisoryRequest):
    """
    Evaluates weather-driven pest and disease risk index based on real-time micro-climate weather.
    """
    weather_res = await WeatherService.fetch_realtime_weather(payload.latitude, payload.longitude)
    daily_weather = weather_res.get("daily_weather", {})
    
    if not daily_weather:
        max_t, min_t, hum, rain = 32.0, 24.0, 85.0, 0.0
    else:
        today_key = list(daily_weather.keys())[0]
        w = daily_weather[today_key]
        max_t = w.get("temp_max_c", 32.0)
        min_t = w.get("temp_min_c", 24.0)
        hum = w.get("humidity_percent", 85.0)
        rain = w.get("precipitation_mm", 0.0)

    advisories = PestDiseaseEngine.evaluate_pest_risk(
        crop_id=payload.crop_id,
        max_temp_c=max_t,
        min_temp_c=min_t,
        humidity_percent=hum,
        precipitation_mm=rain
    )

    return {
        "status": "success",
        "crop_id": payload.crop_id,
        "weather_snapshot": {
            "max_temp_c": max_t,
            "min_temp_c": min_t,
            "humidity_percent": hum,
            "precipitation_mm": rain
        },
        "total_active_warnings": len(advisories),
        "advisories": advisories
    }


@router.post("/trigger-batch-advisories")
async def trigger_batch_advisories(x_admin_api_key: Optional[str] = Header(None)):
    """
    Manually triggers the background daily weather evaluation batch job across all registered farmer plots.
    Requires administrative API key header (X-Admin-API-Key).
    """
    if not x_admin_api_key or x_admin_api_key != settings.ADMIN_API_KEY:
        raise HTTPException(
            status_code=403,
            detail="Forbidden: Invalid or missing administrative API key header (X-Admin-API-Key)"
        )

    from app.services.automated_advisory_cron import run_daily_weather_and_pest_batch_job
    result = await run_daily_weather_and_pest_batch_job()
    return result