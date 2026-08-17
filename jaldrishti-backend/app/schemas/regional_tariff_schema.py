from pydantic import BaseModel, Field, ConfigDict
from typing import Optional
from datetime import datetime


class RegionalTariffCreateUpdate(BaseModel):
    state_name: Optional[str] = Field(default=None, max_length=100)
    diesel_tariff_inr_hr: Optional[float] = Field(default=None, ge=1.0, le=1000.0)
    electric_tariff_inr_hr: Optional[float] = Field(default=None, ge=1.0, le=1000.0)
    diesel_co2_kg_hr: Optional[float] = Field(default=None, ge=0.1, le=50.0)
    electric_co2_kg_hr: Optional[float] = Field(default=None, ge=0.1, le=50.0)
    attribution_notice: Optional[str] = Field(default=None, max_length=255)


class RegionalTariffResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    state_code: str
    state_name: str
    diesel_tariff_inr_hr: float
    electric_tariff_inr_hr: float
    diesel_co2_kg_hr: float
    electric_co2_kg_hr: float
    attribution_notice: str
    updated_at: datetime
