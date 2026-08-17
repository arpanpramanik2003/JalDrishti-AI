from pydantic import BaseModel, Field, ConfigDict
from typing import List, Optional, Union
from datetime import date, datetime

class IrrigationRequest(BaseModel):
    plot_id: Optional[int] = Field(default=None, description="Farm plot ID for historical logging lookup")
    latitude: float = Field(..., description="Farm GPS Latitude")
    longitude: float = Field(..., description="Farm GPS Longitude")
    crop_id: str = Field(..., description="Crop unique identifier")
    sowing_date: date = Field(..., description="Sowing date (YYYY-MM-DD)")
    field_name: Optional[str] = Field(default="Main Plot", description="User field label")
    area_acres: Optional[float] = Field(default=2.5, description="Plot size in acres")
    pump_hp: Optional[float] = Field(default=5.0, description="Pump Horsepower (HP)")
    pump_flow_lps: Optional[float] = Field(default=5.0, description="Pump discharge rate (Liters/second)")
    irrigation_method: Optional[str] = Field(default="flood", description="drip, sprinkler, or flood")
    soil_type: Optional[str] = Field(default="clay_loam", description="sandy_loam, loam, clay_loam, silty_clay, heavy_clay")

class IrrigationLogCreate(BaseModel):
    farm_plot_id: int = Field(..., description="Farm plot ID")
    applied_mm: float = Field(..., ge=0.1, le=500.0, description="Water depth applied in mm")
    applied_date: Optional[date] = Field(default=None, description="YYYY-MM-DD date object (defaults to today)")
    notes: Optional[str] = Field(default="", max_length=200, description="Optional notes")

class IrrigationLogResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    farm_plot_id: int
    applied_mm: float
    applied_date: date
    notes: Optional[str] = None
    created_at: datetime

class WeatherSummary(BaseModel):
    max_temp_c: float
    min_temp_c: float
    humidity_percent: float
    wind_speed_kmh: float
    precipitation_mm: float

class DailyMetric(BaseModel):
    date: str
    eto_mm: float
    etc_mm: float
    rainfall_mm: float
    irrigation_applied_mm: float = 0.0
    depletion_mm: float
    raw_threshold_mm: float
    max_temp_c: Optional[float] = 30.0
    min_temp_c: Optional[float] = 22.0
    humidity_percent: Optional[float] = 75.0
    wind_speed_kmh: Optional[float] = 12.0
    status: str

class CumulativeSavings(BaseModel):
    total_water_saved_liters: float = 0.0
    total_pump_hours_saved: float = 0.0
    total_money_saved_inr: float = 0.0
    total_co2_reduced_kg: float = 0.0
    skipped_runs_count: int = 0
    state_code: Optional[str] = "DEFAULT"
    state_name: Optional[str] = "National Benchmark"
    tariff_rate_inr_hr: Optional[float] = 80.0
    co2_factor_kg_hr: Optional[float] = 2.68
    attribution_notice: Optional[str] = "Calculated using state agricultural benchmark & CEA India Grid emission factor."

class IrrigationResponse(BaseModel):
    field_name: str
    crop_name: str
    sowing_date: date
    elapsed_days: int
    current_growth_stage: str
    dynamic_kc: float
    effective_root_depth_m: float
    location: dict
    total_available_water_mm: float
    needs_irrigation_today: bool
    recommended_water_mm: float
    recommended_gross_water_mm: float
    recommended_pump_hours: int
    recommended_pump_minutes: int
    irrigation_method_display: str
    irrigation_efficiency_pct: int
    soil_type_display: str
    soil_is_fallback: bool = False
    status_summary: str
    
    # Smart Rain Hold & Cost Savings
    rain_hold_active: bool = False
    rain_hold_message: Optional[str] = None
    upcoming_rain_mm: float = 0.0
    upcoming_rain_24h_mm: float = 0.0
    upcoming_rain_48h_mm: float = 0.0
    estimated_cost_saved_inr: float = 0.0
    cumulative_savings: Optional[CumulativeSavings] = None

    weather_summary: Optional[WeatherSummary] = None
    daily_breakdown: List[DailyMetric]