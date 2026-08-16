from datetime import date, datetime
from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, Date, ForeignKey
from sqlalchemy.orm import relationship
from app.db.database import Base

class FarmPlot(Base):
    __tablename__ = "farm_plots"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    
    name = Column(String(100), nullable=False) # e.g. "Main Paddy Plot"
    location_name = Column(String(100), nullable=True, default="Burdwan, West Bengal")
    latitude = Column(Float, nullable=False, default=22.5726)
    longitude = Column(Float, nullable=False, default=88.3639)
    crop_id = Column(String(50), nullable=False, default="paddy_rice")
    sowing_date = Column(Date, nullable=False, default=date.today)
    area_acres = Column(Float, nullable=False, default=2.5)
    is_primary = Column(Boolean, default=False)

    # Module 2, 3, 4 Attributes
    pump_hp = Column(Float, nullable=False, default=5.0)
    pump_flow_lps = Column(Float, nullable=False, default=5.0)
    irrigation_method = Column(String(30), nullable=False, default="flood") # "drip", "sprinkler", "flood"
    soil_type = Column(String(30), nullable=False, default="clay_loam") # "sandy_loam", "loam", "clay_loam", "silty_clay", "heavy_clay"
    version = Column(Integer, default=1, nullable=False)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationship back to User and IrrigationLogs
    user = relationship("User", backref="farm_plots")
    irrigation_logs = relationship("IrrigationLog", back_populates="farm_plot", cascade="all, delete-orphan")


class IrrigationLog(Base):
    __tablename__ = "irrigation_logs"

    id = Column(Integer, primary_key=True, index=True)
    farm_plot_id = Column(Integer, ForeignKey("farm_plots.id"), nullable=False, index=True)
    applied_mm = Column(Float, nullable=False)
    applied_date = Column(Date, nullable=False, index=True, default=date.today)
    notes = Column(String(200), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    farm_plot = relationship("FarmPlot", back_populates="irrigation_logs")
