import json
import os
from typing import Optional
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from app.engine.pest_disease_engine import PestDiseaseEngine
from app.services.weather_service import WeatherService

router = APIRouter()

CROP_DB_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..', 'engine', 'crop_coefficients.json'))

class PestAdvisoryRequest(BaseModel):
    crop_id: str = Field(..., example="paddy_rice", description="Crop identifier")
    latitude: float = Field(..., example=22.5726, description="Farm Latitude")
    longitude: float = Field(..., example=88.3639, description="Farm Longitude")

@router.get("/all")
def get_all_crops():
    """Dynamically returns all crops supported by the JalDrishti engine, sorted alphabetically."""
    if not os.path.exists(CROP_DB_PATH):
        raise HTTPException(status_code=500, detail="Crop database not found")
    
    with open(CROP_DB_PATH, 'r', encoding='utf-8') as f:
        crop_data = json.load(f)
        
    crop_list = []
    for crop_id, details in crop_data.items():
        crop_list.append({
            "id": crop_id,
            "name": details.get("name", crop_id),
            "season": details.get("season", "All-Season"),
            "root_depth_m": details.get("root_depth_m", 0.5),
            "depletion_fraction_p": details.get("depletion_fraction_p", 0.5)
        })
    
    crop_list.sort(key=lambda x: x["name"])
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
async def trigger_batch_advisories():
    """
    Manually triggers the background daily weather evaluation batch job across all registered farmer plots.
    """
    from app.services.automated_advisory_cron import run_daily_weather_and_pest_batch_job
    result = await run_daily_weather_and_pest_batch_job()
    return result