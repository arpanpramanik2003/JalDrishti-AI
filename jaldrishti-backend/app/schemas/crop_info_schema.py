from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field

class CropItemResponse(BaseModel):
    id: str = Field(..., description="Crop unique identifier")
    name: str = Field(..., description="Crop display name")
    season: str = Field(..., description="Growing season")
    root_depth_m: float = Field(..., description="Maximum root depth in meters")
    depletion_fraction_p: float = Field(..., description="FAO-56 depletion fraction p")

class CropListResponse(BaseModel):
    status: str = "success"
    total_crops: int
    crops: List[CropItemResponse]

class WeatherSnapshot(BaseModel):
    max_temp_c: float
    min_temp_c: float
    humidity_percent: float
    precipitation_mm: float

class PestAdvisoryResponse(BaseModel):
    status: str = "success"
    crop_id: str
    weather_snapshot: WeatherSnapshot
    total_active_warnings: int
    advisories: List[Dict[str, Any]]
