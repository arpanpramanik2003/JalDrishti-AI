from typing import Optional
from datetime import date, datetime
from pydantic import BaseModel, Field, ConfigDict

class FarmPlotCreate(BaseModel):
    name: str = Field(..., min_length=2, max_length=50, example="North Paddy Plot")
    location_name: Optional[str] = Field(default="Burdwan, WB", max_length=100)
    latitude: float = Field(..., ge=-90.0, le=90.0, example=22.5726)
    longitude: float = Field(..., ge=-180.0, le=180.0, example=88.3639)
    crop_id: str = Field(..., max_length=50, pattern=r"^[a-zA-Z0-9_]+$", example="paddy_rice")
    sowing_date: date = Field(..., example="2026-06-15")
    area_acres: float = Field(..., ge=0.01, le=10000.0, example=2.5)
    is_primary: Optional[bool] = False
    pump_hp: Optional[float] = Field(default=5.0, ge=0.1, le=100.0)
    pump_flow_lps: Optional[float] = Field(default=5.0, ge=0.1, le=500.0)
    irrigation_method: Optional[str] = Field(default="flood", max_length=30)
    soil_type: Optional[str] = Field(default="clay_loam", max_length=30)

class FarmPlotUpdate(BaseModel):
    expected_version: Optional[int] = Field(default=None, description="Current version number for optimistic concurrency control")
    name: Optional[str] = Field(default=None, min_length=2, max_length=50)
    location_name: Optional[str] = Field(default=None, max_length=100)
    latitude: Optional[float] = Field(default=None, ge=-90.0, le=90.0)
    longitude: Optional[float] = Field(default=None, ge=-180.0, le=180.0)
    crop_id: Optional[str] = Field(default=None, max_length=50, pattern=r"^[a-zA-Z0-9_]+$")
    sowing_date: Optional[date] = Field(default=None)
    area_acres: Optional[float] = Field(default=None, ge=0.01, le=10000.0)
    is_primary: Optional[bool] = None
    pump_hp: Optional[float] = Field(default=None, ge=0.1, le=100.0)
    pump_flow_lps: Optional[float] = Field(default=None, ge=0.1, le=500.0)
    irrigation_method: Optional[str] = Field(default=None, max_length=30)
    soil_type: Optional[str] = Field(default=None, max_length=30)

class FarmPlotResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    name: str
    location_name: str
    latitude: float
    longitude: float
    crop_id: str
    sowing_date: date
    area_acres: float
    is_primary: bool
    pump_hp: float = 5.0
    pump_flow_lps: float = 5.0
    irrigation_method: str = "flood"
    soil_type: str = "clay_loam"
    version: int = 1
    created_at: datetime
