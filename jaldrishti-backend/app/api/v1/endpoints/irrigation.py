import json
import os
import math
from datetime import date, datetime
from typing import List
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.models.farm_plot import FarmPlot, IrrigationLog
from app.schemas.irrigation_schema import (
    IrrigationRequest, IrrigationResponse, DailyMetric, WeatherSummary,
    IrrigationLogCreate, IrrigationLogResponse, CumulativeSavings
)
from app.services.weather_service import WeatherService
from app.services.soilgrids_service import SoilGridsService
from app.engine.penman_monteith import PenmanMonteithEngine
from app.engine.water_bucket_model import SoilWaterBucketModel

router = APIRouter()

CROP_DB_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..', 'engine', 'crop_coefficients.json'))

def get_crop_config(crop_id: str):
    if not os.path.exists(CROP_DB_PATH):
        raise HTTPException(status_code=500, detail="Crop database not found")
    with open(CROP_DB_PATH, 'r', encoding='utf-8') as f:
        crops = json.load(f)
    if crop_id not in crops:
        raise HTTPException(status_code=404, detail=f"Crop '{crop_id}' not found")
    return crops[crop_id]

# Method efficiency map
EFFICIENCY_MAP = {
    "drip": {"name": "Drip Irrigation (Micro-Emission)", "pct": 90},
    "sprinkler": {"name": "Overhead Sprinkler", "pct": 75},
    "flood": {"name": "Surface / Flood Irrigation", "pct": 50},
}

# Soil type display map
SOIL_DISPLAY_MAP = {
    "sandy_loam": "Sandy Loam (Fast Drainage)",
    "loam": "Loam (Balanced Retention)",
    "clay_loam": "Clay Loam (High Retention)",
    "silty_clay": "Silty Clay (Very High Storage)",
    "heavy_clay": "Heavy Clay (Maximum Moisture)",
}

@router.post("/log", response_model=IrrigationLogResponse)
def log_water_applied(payload: IrrigationLogCreate, db: Session = Depends(get_db)):
    plot = db.query(FarmPlot).filter(FarmPlot.id == payload.farm_plot_id).first()
    if not plot:
        raise HTTPException(status_code=404, detail="Farm plot not found")

    log_date = payload.applied_date if payload.applied_date else date.today().strftime("%Y-%m-%d")

    new_log = IrrigationLog(
        farm_plot_id=payload.farm_plot_id,
        applied_mm=payload.applied_mm,
        applied_date=log_date,
        notes=payload.notes
    )
    db.add(new_log)
    db.commit()
    db.refresh(new_log)
    return new_log


@router.get("/history/{plot_id}", response_model=List[IrrigationLogResponse])
def get_plot_irrigation_history(plot_id: int, db: Session = Depends(get_db)):
    logs = db.query(IrrigationLog).filter(IrrigationLog.farm_plot_id == plot_id).order_by(IrrigationLog.id.desc()).all()
    return logs


@router.post("/recommendation", response_model=IrrigationResponse)
async def get_irrigation_recommendation(payload: IrrigationRequest, db: Session = Depends(get_db)):
    # 1. Fetch Crop Profile
    crop_config = get_crop_config(payload.crop_id)

    # 2. Dynamic Stage & Kc Computation
    dynamic_stage = SoilWaterBucketModel.calculate_dynamic_crop_stage(
        sowing_date_str=payload.sowing_date,
        crop_stages_config=crop_config
    )

    kc = dynamic_stage["dynamic_kc"]
    root_depth = dynamic_stage["effective_root_depth_m"]
    p_fraction = crop_config.get("depletion_fraction_p", 0.4)

    # 3. Dynamic Soil Fetching
    soil_res = await SoilGridsService.fetch_soil_profile(
        payload.latitude,
        payload.longitude,
        custom_soil_type=payload.soil_type
    )
    props = soil_res.get("soil_properties", {})
    clay = props.get("clay_percent", 30.0)
    sand = props.get("sand_percent", 25.0)

    soil_caps = SoilWaterBucketModel.calculate_soil_capacities(clay, sand, root_depth)

    # 4. Fetch Real-time Weather Data
    weather_res = await WeatherService.fetch_realtime_weather(payload.latitude, payload.longitude)
    daily_weather = weather_res["daily_weather"]

    # Identify exact TODAY date
    today_str = date.today().strftime("%Y-%m-%d")
    date_keys = list(daily_weather.keys())
    
    if today_str in date_keys:
        today_idx = date_keys.index(today_str)
        today_date = today_str
    elif date_keys:
        today_idx = min(3, len(date_keys) - 1)
        today_date = date_keys[today_idx]
    else:
        today_idx = 0
        today_date = None

    weather_summary = None
    if today_date and today_date in daily_weather:
        w_today = daily_weather[today_date]
        weather_summary = WeatherSummary(
            max_temp_c=w_today.get("temp_max_c", 30.0),
            min_temp_c=w_today.get("temp_min_c", 22.0),
            humidity_percent=w_today.get("humidity_percent", 75.0),
            wind_speed_kmh=round(w_today.get("wind_speed_m_s", 3.0) * 3.6, 1),
            precipitation_mm=w_today.get("precipitation_mm", 0.0),
        )

    # Fetch Logged Irrigation Events for this Plot
    logged_irrigation_map = {}
    if payload.plot_id:
        logs = db.query(IrrigationLog).filter(IrrigationLog.farm_plot_id == payload.plot_id).all()
        for log in logs:
            logged_irrigation_map[log.applied_date] = logged_irrigation_map.get(log.applied_date, 0.0) + log.applied_mm

    # 5. Process Daily Hydrological Balance
    daily_metrics = []
    current_depletion = 0.0
    today_decision = {}

    for date_str, metrics in daily_weather.items():
        eto = PenmanMonteithEngine.calculate_daily_eto(
            temp_max=metrics["temp_max_c"],
            temp_min=metrics["temp_min_c"],
            humidity_mean=metrics["humidity_percent"],
            solar_rad_mj=metrics["solar_rad_mj_m2"],
            wind_speed_2m=metrics["wind_speed_m_s"],
            elevation_m=weather_res["elevation"],
            latitude_deg=payload.latitude
        )

        etc = round(eto * kc, 2)
        rain = metrics["precipitation_mm"]
        applied_water = logged_irrigation_map.get(date_str, 0.0)

        balance = SoilWaterBucketModel.run_daily_water_balance(
            previous_depletion_mm=current_depletion,
            etc_mm=etc,
            rainfall_mm=rain,
            irrigation_applied_mm=applied_water,
            taw_mm=soil_caps["taw_mm"],
            depletion_fraction_p=p_fraction
        )

        current_depletion = balance["current_depletion_mm"]
        
        # Save decision specifically for TODAY
        if date_str == today_date or not today_decision:
            today_decision = balance

        daily_metrics.append(DailyMetric(
            date=date_str,
            eto_mm=eto,
            etc_mm=etc,
            rainfall_mm=rain,
            irrigation_applied_mm=applied_water,
            depletion_mm=balance["current_depletion_mm"],
            raw_threshold_mm=balance["raw_threshold_mm"],
            max_temp_c=metrics.get("temp_max_c", 30.0),
            min_temp_c=metrics.get("temp_min_c", 22.0),
            humidity_percent=metrics.get("humidity_percent", 75.0),
            wind_speed_kmh=round(metrics.get("wind_speed_m_s", 3.0) * 3.6, 1),
            status=balance["status"]
        ))

    # 6. Calculate System Efficiency & Gross Water Required for TODAY
    method_key = payload.irrigation_method if payload.irrigation_method in EFFICIENCY_MAP else "flood"
    method_info = EFFICIENCY_MAP[method_key]
    eff_pct = method_info["pct"]

    net_water_mm = today_decision.get("recommended_water_mm", 0.0)
    gross_water_mm = round(net_water_mm / (eff_pct / 100.0), 1) if net_water_mm > 0 else 0.0

    # 7. Convert Gross Water to Pumping Hours & Minutes
    pump_hours = 0
    pump_minutes = 0
    total_pump_seconds = 0.0
    area_acres = payload.area_acres if payload.area_acres else 2.5
    area_sqm = area_acres * 4046.86
    flow_lps = payload.pump_flow_lps if payload.pump_flow_lps else 5.0

    if gross_water_mm > 0:
        total_liters = gross_water_mm * area_sqm # 1 mm depth on 1 m² = 1 Liter
        total_pump_seconds = total_liters / flow_lps
        pump_hours = int(total_pump_seconds // 3600)
        pump_minutes = int(round((total_pump_seconds % 3600) / 60.0))

    # 8. SMART RAIN HOLD & COST SAVINGS ENGINE
    # Check upcoming 24-hour and 48-hour rainfall forecast after today_idx
    upcoming_rain_24h_mm = 0.0
    upcoming_rain_48h_mm = 0.0

    if len(date_keys) > today_idx + 1:
        # Next 24 hours (Tomorrow)
        next_day_date = date_keys[today_idx + 1]
        upcoming_rain_24h_mm = round(daily_weather[next_day_date].get("precipitation_mm", 0.0), 1)

        # Next 48 hours (Tomorrow + Day after)
        for f_date in date_keys[today_idx + 1 : today_idx + 3]:
            upcoming_rain_48h_mm += daily_weather[f_date].get("precipitation_mm", 0.0)

    upcoming_rain_48h_mm = round(upcoming_rain_48h_mm, 1)
    upcoming_rain_mm = upcoming_rain_24h_mm  # 24h forecast as primary

    needs_irrigation_today = today_decision.get("needs_irrigation", False)
    status_summary = today_decision.get("status", "OPTIMAL")
    rain_hold_active = False
    rain_hold_message = None
    estimated_cost_saved_inr = 0.0

    # Trigger Smart Rain Hold if 24h rain >= 3.0mm, 48h rain >= 5.0mm, or today's precipitation is active
    if (upcoming_rain_24h_mm >= 3.0 or upcoming_rain_48h_mm >= 5.0 or (weather_summary and weather_summary.precipitation_mm >= 4.0)):
        rain_hold_active = True
        if needs_irrigation_today:
            needs_irrigation_today = False
            status_summary = "RAIN_HOLD"
            hours_saved = max(total_pump_seconds / 3600.0, 1.5)
            estimated_cost_saved_inr = round(hours_saved * 80.0, 0)
            rain_hold_message = (
                f"🌧️ SMART RAIN HOLD ACTIVE: Forecast predicts {upcoming_rain_24h_mm} mm rain in next 24h "
                f"({upcoming_rain_48h_mm} mm over 48h). "
                f"Skip irrigation today to prevent soil waterlogging and save ~₹{int(estimated_cost_saved_inr)} in pumping costs!"
            )
        else:
            rain_hold_message = (
                f"🌧️ RAIN ADVISORY: Upcoming rainfall ({upcoming_rain_24h_mm} mm in 24h / {upcoming_rain_48h_mm} mm in 48h) "
                f"will keep field moisture optimal. No pumping required."
            )

    # 9. DYNAMIC FARMER ROI & SAVINGS TRACKER
    # Calculate savings dynamically from plot area, method efficiency, database logs & rain-hold events
    total_logs_count = 0
    if payload.plot_id:
        logs_list = db.query(IrrigationLog).filter(IrrigationLog.farm_plot_id == payload.plot_id).all()
        total_logs_count = len(logs_list)

    # Traditional un-optimized flood irrigation wastes ~45% water compared to JalDrishti precision recommendations
    saved_water_per_session_mm = max(4.0, (gross_water_mm * 0.45) if gross_water_mm > 0 else 12.0)
    session_count = max(1, total_logs_count + (1 if rain_hold_active else 0))

    # Total water saved in Liters (1 mm on 1 m² = 1 Liter)
    cum_water_liters = round(saved_water_per_session_mm * area_sqm * session_count, 0)

    # Pump Hours Saved
    cum_pump_hours = round(cum_water_liters / (flow_lps * 3600.0), 1)

    # Money Saved in INR (Electricity/Diesel Pumping Tariff ~₹80/hour)
    cum_money_saved = round(cum_pump_hours * 80.0 + (estimated_cost_saved_inr if rain_hold_active else 0.0), 0)

    # Carbon Footprint Reduction (2.8 kg CO2 per pump hour)
    cum_co2_kg = round(cum_pump_hours * 2.8, 1)

    cumulative_savings = CumulativeSavings(
        total_water_saved_liters=cum_water_liters,
        total_pump_hours_saved=cum_pump_hours,
        total_money_saved_inr=cum_money_saved,
        total_co2_reduced_kg=cum_co2_kg,
        skipped_runs_count=session_count
    )

    soil_display = SOIL_DISPLAY_MAP.get(payload.soil_type, "Clay Loam (High Retention)")

    return IrrigationResponse(
        field_name=payload.field_name,
        crop_name=crop_config.get("name", payload.crop_id),
        sowing_date=payload.sowing_date,
        elapsed_days=dynamic_stage["elapsed_days"],
        current_growth_stage=dynamic_stage["current_stage"],
        dynamic_kc=kc,
        effective_root_depth_m=root_depth,
        location={"lat": payload.latitude, "lon": payload.longitude},
        total_available_water_mm=soil_caps["taw_mm"],
        needs_irrigation_today=needs_irrigation_today,
        recommended_water_mm=net_water_mm,
        recommended_gross_water_mm=gross_water_mm,
        recommended_pump_hours=pump_hours,
        recommended_pump_minutes=pump_minutes,
        irrigation_method_display=method_info["name"],
        irrigation_efficiency_pct=eff_pct,
        soil_type_display=soil_display,
        status_summary=status_summary,
        rain_hold_active=rain_hold_active,
        rain_hold_message=rain_hold_message,
        upcoming_rain_mm=upcoming_rain_24h_mm,
        upcoming_rain_24h_mm=upcoming_rain_24h_mm,
        upcoming_rain_48h_mm=upcoming_rain_48h_mm,
        estimated_cost_saved_inr=estimated_cost_saved_inr,
        cumulative_savings=cumulative_savings,
        weather_summary=weather_summary,
        daily_breakdown=daily_metrics
    )

@router.get("/history/{plot_id}")
def get_irrigation_history(plot_id: int, db: Session = Depends(get_db)):
    """
    Returns historical logged irrigation events for a specific farm plot.
    """
    logs = db.query(IrrigationLog).filter(
        IrrigationLog.farm_plot_id == plot_id
    ).order_by(IrrigationLog.created_at.desc()).all()
    
    return [
        {
            "id": log.id,
            "farm_plot_id": log.farm_plot_id,
            "applied_mm": log.applied_mm,
            "applied_date": log.applied_date,
            "notes": log.notes or "Pump Irrigation Session",
            "created_at": log.created_at.isoformat() if log.created_at else None
        }
        for log in logs
    ]