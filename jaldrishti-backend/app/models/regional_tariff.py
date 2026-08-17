from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, DateTime
from app.db.database import Base


class RegionalTariff(Base):
    __tablename__ = "regional_tariffs"

    id = Column(Integer, primary_key=True, index=True)
    state_code = Column(String(10), unique=True, index=True, nullable=False) # e.g. "WB", "UP", "PB", "MH", "BR", "DEFAULT"
    state_name = Column(String(100), nullable=False)                         # e.g. "West Bengal", "Punjab", "National Benchmark"
    
    diesel_tariff_inr_hr = Column(Float, nullable=False, default=80.0)      # ₹80/hr average labor & fuel tariff
    electric_tariff_inr_hr = Column(Float, nullable=False, default=25.0)    # ₹25/hr subsidized agricultural grid power
    
    diesel_co2_kg_hr = Column(Float, nullable=False, default=2.68)          # 2.68 kg CO2 / hr for diesel pump
    electric_co2_kg_hr = Column(Float, nullable=False, default=0.72)        # 0.72 kg CO2 / hr (CEA India Grid Factor)
    
    attribution_notice = Column(String(255), nullable=False, default="Calculated using state agricultural tariff benchmarks & CEA India Grid emission factor.")
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
