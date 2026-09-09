import json
import os
import math
from datetime import date, datetime, timedelta
from typing import List, Optional
from fastapi import APIRouter, HTTPException, Depends, Query
from starlette.concurrency import run_in_threadpool
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.models.user import User
from app.models.farm_plot import FarmPlot, IrrigationLog, SoilDepletionState
from app.core.security import get_current_user
from app.core.constants import (
    FALLBACK_SOLAR_RADIATION_MJ_M2,
    DEFAULT_ELECTRIC_TARIFF_INR_HR,
    RAIN_HOLD_24H_THRESHOLD_MM,
    RAIN_HOLD_48H_THRESHOLD_MM,
    RAIN_HOLD_TODAY_PRECIP_THRESHOLD_MM,
    MINIMUM_HOURS_SAVED_RAIN_HOLD,
    TRADITIONAL_FLOOD_WASTE_FRACTION,
    MINIMUM_WATER_SAVED_PER_SESSION_MM,
    FALLBACK_WATER_SAVED_PER_SESSION_MM,
    DEFAULT_PUMP_FLOW_LPS,
    DEFAULT_PLOT_AREA_ACRES,
    ACRE_TO_SQUARE_METERS,
    WATER_DEPTH_MM_TO_L_PER_M2,
    DEFAULT_SOIL_CLAY_PERCENT,
    DEFAULT_SOIL_SAND_PERCENT
)
from app.schemas.irrigation_schema import (
    IrrigationRequest, IrrigationResponse, DailyMetric, WeatherSummary,
    IrrigationLogCreate, IrrigationLogResponse, CumulativeSavings
)
from app.services.weather_service import WeatherService
from app.services.soilgrids_service import SoilGridsService
from app.engine.penman_monteith import PenmanMonteithEngine
from app.engine.water_bucket_model import SoilWaterBucketModel
from app.services.crop_config_service import CropConfigService
from app.services.regional_tariff_service import RegionalTariffService

router = APIRouter()


def get_crop_config(crop_id: str):
    return CropConfigService.get_crop_config(crop_id)


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
def log_water_applied(
    payload: IrrigationLogCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    plot = db.query(FarmPlot).filter(FarmPlot.id == payload.farm_plot_id).first()
    if not plot:
        raise HTTPException(status_code=404, detail="Farm plot not found")
    if plot.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="You do not have permission to access or modify this farm plot")

    log_date = payload.applied_date if payload.applied_date else date.today()

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
def get_plot_irrigation_history(
    plot_id: int,
    limit: int = Query(20, ge=1, le=100, description="Page size limit"),
    offset: int = Query(0, ge=0, description="Page offset"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    plot = db.query(FarmPlot).filter(FarmPlot.id == plot_id).first()
    if not plot:
        raise HTTPException(status_code=404, detail="Farm plot not found")
    if plot.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="You do not have permission to access or modify this farm plot")

    logs = (
        db.query(IrrigationLog)
        .filter(IrrigationLog.farm_plot_id == plot_id)
        .order_by(IrrigationLog.id.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )
    return logs


@router.post("/recommendation", response_model=IrrigationResponse)
async def get_irrigation_recommendation(
    payload: IrrigationRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    plot = None
    if payload.plot_id:
        plot = await run_in_threadpool(
            lambda: db.query(FarmPlot).filter(FarmPlot.id == payload.plot_id).first()
        )
        if not plot:
            raise HTTPException(status_code=404, detail="Farm plot not found")
        if plot.user_id != current_user.id:
            raise HTTPException(status_code=403, detail="You do not have permission to access or modify this farm plot")

    # 1. Fetch Crop Profile
    crop_config = get_crop_config(payload.crop_id)

    # 2. Dynamic Stage & Kc Computation
    dynamic_stage = SoilWaterBucketModel.calculate_dynamic_crop_stage(
        sowing_date_val=payload.sowing_date,
        crop_stages_config=crop_config
    )

    kc = dynamic_stage["dynamic_kc"]
    root_depth = dynamic_stage["effective_root_depth_m"]
    p_fraction = crop_config.get("depletion_fraction_p", 0.4)
    crop_lifecycle_status = dynamic_stage["crop_status"]
    crop_status_message = dynamic_stage.get("status_message")

    # 3. Dynamic Soil Profile Fetching
    soil_res = await SoilGridsService.fetch_soil_profile(
        payload.latitude,
        payload.longitude,
        custom_soil_type=payload.soil_type
    )
    props = soil_res.get("soil_properties", {})
    clay = props.get("clay_percent", DEFAULT_SOIL_CLAY_PERCENT)
    sand = props.get("sand_percent", DEFAULT_SOIL_SAND_PERCENT)
    soil_caps = SoilWaterBucketModel.calculate_soil_capacities(clay, sand, root_depth)

    # 4. Fetch Real-time Weather Data
    weather_res = await WeatherService.fetch_realtime_weather(payload.latitude, payload.longitude)
    daily_weather = weather_res.get("daily_weather", {})

    # Identify exact TODAY date
    today_obj = date.today()
    today_str = today_obj.strftime("%Y-%m-%d")
    date_keys = list(daily_weather.keys())

    if today_str in date_keys:
        today_idx = date_keys.index(today_str)
        today_date = today_str
    elif date_keys:
        today_idx = min(3, len(date_keys) - 1)
        today_date = date_keys[today_idx]
    else:
        today_idx = 0
        today_date = today_str

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

    # Fetch Logged Irrigation Events for this Plot (F-01: normalize keys to ISO string; single query reused throughout)
    logged_irrigation_map = {}
    if payload.plot_id:
        logs = await run_in_threadpool(
            lambda: db.query(IrrigationLog).filter(IrrigationLog.farm_plot_id == payload.plot_id).all()
        )
        for log in logs:
            if isinstance(log.applied_date, (date, datetime)):
                date_iso = log.applied_date.isoformat()
            else:
                date_iso = str(log.applied_date)
            logged_irrigation_map[date_iso] = logged_irrigation_map.get(date_iso, 0.0) + log.applied_mm

    # Boundary Handling: Pre-planting or Post-harvest overdue (F-13)
    if crop_lifecycle_status in ["NOT_YET_SOWN", "HARVEST_OVERDUE"]:
        method_key = payload.irrigation_method if payload.irrigation_method in EFFICIENCY_MAP else "flood"
        method_info = EFFICIENCY_MAP[method_key]
        soil_display = SOIL_DISPLAY_MAP.get(payload.soil_type, "Clay Loam (High Retention)")

        # Create daily metrics with inactive recommendation status
        inactive_metrics = []
        for d_str, metrics in daily_weather.items():
            inactive_metrics.append(DailyMetric(
                date=d_str,
                eto_mm=0.0,
                etc_mm=0.0,
                rainfall_mm=metrics.get("precipitation_mm", 0.0),
                irrigation_applied_mm=logged_irrigation_map.get(d_str, 0.0),
                depletion_mm=0.0,
                raw_threshold_mm=soil_caps["taw_mm"] * p_fraction,
                max_temp_c=metrics.get("temp_max_c", 30.0),
                min_temp_c=metrics.get("temp_min_c", 22.0),
                humidity_percent=metrics.get("humidity_percent", 75.0),
                wind_speed_kmh=round(metrics.get("wind_speed_m_s", 3.0) * 3.6, 1),
                status=crop_lifecycle_status
            ))

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
            needs_irrigation_today=False,
            recommended_water_mm=None,
            recommended_gross_water_mm=None,
            recommended_pump_hours=0,
            recommended_pump_minutes=0,
            irrigation_method_display=method_info["name"],
            irrigation_efficiency_pct=method_info["pct"],
            soil_type_display=soil_display,
            soil_is_fallback=props.get("is_fallback", False),
            status_summary=crop_lifecycle_status,
            crop_lifecycle_status=crop_lifecycle_status,
            crop_status_message=crop_status_message,
            rain_hold_active=False,
            rain_hold_message=crop_status_message,
            upcoming_rain_mm=0.0,
            upcoming_rain_24h_mm=0.0,
            upcoming_rain_48h_mm=0.0,
            estimated_cost_saved_inr=0.0,
            cumulative_savings=CumulativeSavings(),
            weather_summary=weather_summary,
            daily_breakdown=inactive_metrics
        )

    # 5. Persistent Soil Moisture Depletion State Model (F-02 Fix)
    depletion_record = None
    yesterday_baseline = 0.0

    if payload.plot_id:
        depletion_record = await run_in_threadpool(
            lambda: db.query(SoilDepletionState).filter(
                SoilDepletionState.farm_plot_id == payload.plot_id
            ).first()
        )

        if not depletion_record:
            # First-ever calculation for this plot under persistent model
            if dynamic_stage["elapsed_days"] <= 0:
                # Freshly sown = field capacity (depletion = 0.0 mm)
                depletion_record = SoilDepletionState(
                    farm_plot_id=payload.plot_id,
                    current_depletion_mm=0.0,
                    yesterday_depletion_mm=0.0,
                    last_updated_date=today_obj,
                    skipped_runs_count=0
                )
            else:
                # Existing plot created before migration.
                # Backfill assumption: Assume soil was at field capacity (depletion = 0.0 mm)
                # at the earlier of (sowing_date, 7 days ago). Simulate forward across available
                # past weather up to yesterday. We do not invent unrecorded history.
                backfill_start = max(payload.sowing_date, today_obj - timedelta(days=7))
                sim_d = 0.0
                curr_date = backfill_start
                while curr_date < today_obj:
                    d_iso = curr_date.strftime("%Y-%m-%d")
                    if d_iso in daily_weather:
                        w_past = daily_weather[d_iso]
                        past_eto = PenmanMonteithEngine.calculate_daily_eto(
                            temp_max=w_past["temp_max_c"],
                            temp_min=w_past["temp_min_c"],
                            humidity_mean=w_past["humidity_percent"],
                            solar_rad_mj=w_past.get("solar_rad_mj_m2", FALLBACK_SOLAR_RADIATION_MJ_M2),
                            wind_speed_2m=w_past.get("wind_speed_m_s", 2.0),
                            elevation_m=weather_res.get("elevation", 12.0),
                            latitude_deg=payload.latitude
                        )
                        past_etc = round(past_eto * kc, 2)
                        past_rain = w_past.get("precipitation_mm", 0.0)
                        past_app = logged_irrigation_map.get(d_iso, 0.0)
                        sim_res = SoilWaterBucketModel.run_daily_water_balance(
                            previous_depletion_mm=sim_d,
                            etc_mm=past_etc,
                            rainfall_mm=past_rain,
                            irrigation_applied_mm=past_app,
                            taw_mm=soil_caps["taw_mm"],
                            depletion_fraction_p=p_fraction
                        )
                        sim_d = sim_res["current_depletion_mm"]
                    curr_date += timedelta(days=1)

                depletion_record = SoilDepletionState(
                    farm_plot_id=payload.plot_id,
                    current_depletion_mm=sim_d,
                    yesterday_depletion_mm=sim_d,
                    last_updated_date=today_obj - timedelta(days=1),
                    skipped_runs_count=0
                )

            def _save_initial_depletion(rec):
                db.add(rec)
                db.commit()
                db.refresh(rec)

            await run_in_threadpool(_save_initial_depletion, depletion_record)

        # Baseline carried from yesterday for today's mass balance
        if depletion_record.last_updated_date < today_obj:
            yesterday_baseline = depletion_record.current_depletion_mm
            depletion_record.yesterday_depletion_mm = yesterday_baseline
        else:
            # Already calculated today: use stored yesterday_depletion_mm baseline for idempotent recalculation
            yesterday_baseline = depletion_record.yesterday_depletion_mm

    # 6. Process TODAY's Hydrological Mass Balance Step
    today_w = daily_weather.get(today_date, {})
    today_eto = PenmanMonteithEngine.calculate_daily_eto(
        temp_max=today_w.get("temp_max_c", 30.0),
        temp_min=today_w.get("temp_min_c", 22.0),
        humidity_mean=today_w.get("humidity_percent", 75.0),
        solar_rad_mj=today_w.get("solar_rad_mj_m2", FALLBACK_SOLAR_RADIATION_MJ_M2),
        wind_speed_2m=today_w.get("wind_speed_m_s", 2.0),
        elevation_m=weather_res.get("elevation", 12.0),
        latitude_deg=payload.latitude
    )
    today_etc = round(today_eto * kc, 2)
    today_rain = today_w.get("precipitation_mm", 0.0)
    today_applied = logged_irrigation_map.get(today_date, 0.0)

    today_decision = SoilWaterBucketModel.run_daily_water_balance(
        previous_depletion_mm=yesterday_baseline,
        etc_mm=today_etc,
        rainfall_mm=today_rain,
        irrigation_applied_mm=today_applied,
        taw_mm=soil_caps["taw_mm"],
        depletion_fraction_p=p_fraction
    )

    # Persist today's new depletion value
    if payload.plot_id and depletion_record:
        def _save_today_depletion(rec, cur_dep, d_today):
            rec.current_depletion_mm = cur_dep
            rec.last_updated_date = d_today
            db.commit()

        await run_in_threadpool(
            _save_today_depletion,
            depletion_record,
            today_decision["current_depletion_mm"],
            today_obj
        )

    # 7. Construct 7-day Multi-Day Metrics for Visual Charts
    # Pre-today dates: backfill display metrics
    # Post-today dates: simulate forward forecast step from today_decision
    daily_metrics = []
    running_forecast_depletion = today_decision["current_depletion_mm"]

    for date_str in date_keys:
        metrics = daily_weather[date_str]
        eto = PenmanMonteithEngine.calculate_daily_eto(
            temp_max=metrics["temp_max_c"],
            temp_min=metrics["temp_min_c"],
            humidity_mean=metrics["humidity_percent"],
            solar_rad_mj=metrics.get("solar_rad_mj_m2", FALLBACK_SOLAR_RADIATION_MJ_M2),
            wind_speed_2m=metrics.get("wind_speed_m_s", 2.0),
            elevation_m=weather_res.get("elevation", 12.0),
            latitude_deg=payload.latitude
        )
        etc = round(eto * kc, 2)
        rain = metrics.get("precipitation_mm", 0.0)
        applied_water = logged_irrigation_map.get(date_str, 0.0)

        if date_str == today_date:
            display_balance = today_decision
        elif date_str < today_date:
            # Past display representation
            display_balance = SoilWaterBucketModel.run_daily_water_balance(
                previous_depletion_mm=max(0.0, yesterday_baseline - etc),
                etc_mm=etc,
                rainfall_mm=rain,
                irrigation_applied_mm=applied_water,
                taw_mm=soil_caps["taw_mm"],
                depletion_fraction_p=p_fraction
            )
        else:
            # Future forecast representation: step forward sequentially
            forecast_balance = SoilWaterBucketModel.run_daily_water_balance(
                previous_depletion_mm=running_forecast_depletion,
                etc_mm=etc,
                rainfall_mm=rain,
                irrigation_applied_mm=0.0,
                taw_mm=soil_caps["taw_mm"],
                depletion_fraction_p=p_fraction
            )
            running_forecast_depletion = forecast_balance["current_depletion_mm"]
            display_balance = forecast_balance

        daily_metrics.append(DailyMetric(
            date=date_str,
            eto_mm=eto,
            etc_mm=etc,
            rainfall_mm=rain,
            irrigation_applied_mm=applied_water,
            depletion_mm=display_balance["current_depletion_mm"],
            raw_threshold_mm=display_balance["raw_threshold_mm"],
            max_temp_c=metrics.get("temp_max_c", 30.0),
            min_temp_c=metrics.get("temp_min_c", 22.0),
            humidity_percent=metrics.get("humidity_percent", 75.0),
            wind_speed_kmh=round(metrics.get("wind_speed_m_s", 3.0) * 3.6, 1),
            status=display_balance["status"]
        ))

    # 8. Calculate System Efficiency & Gross Water Required for TODAY
    method_key = payload.irrigation_method if payload.irrigation_method in EFFICIENCY_MAP else "flood"
    method_info = EFFICIENCY_MAP[method_key]
    eff_pct = method_info["pct"]

    net_water_mm = today_decision.get("recommended_water_mm", 0.0)
    gross_water_mm = round(net_water_mm / (eff_pct / 100.0), 1) if net_water_mm > 0 else 0.0

    # 9. Convert Gross Water to Pumping Hours & Minutes
    pump_hours = 0
    pump_minutes = 0
    total_pump_seconds = 0.0
    area_acres = payload.area_acres if payload.area_acres else DEFAULT_PLOT_AREA_ACRES
    area_sqm = area_acres * ACRE_TO_SQUARE_METERS
    flow_lps = payload.pump_flow_lps if payload.pump_flow_lps else DEFAULT_PUMP_FLOW_LPS

    if gross_water_mm > 0:
        total_liters = gross_water_mm * area_sqm * WATER_DEPTH_MM_TO_L_PER_M2
        total_pump_seconds = total_liters / flow_lps
        pump_hours = int(total_pump_seconds // 3600)
        pump_minutes = int(round((total_pump_seconds % 3600) / 60.0))

    # 10. SMART RAIN HOLD & COST SAVINGS ENGINE
    upcoming_rain_24h_mm = 0.0
    upcoming_rain_48h_mm = 0.0

    if len(date_keys) > today_idx + 1:
        next_day_date = date_keys[today_idx + 1]
        upcoming_rain_24h_mm = round(daily_weather[next_day_date].get("precipitation_mm", 0.0), 1)

        for f_date in date_keys[today_idx + 1: today_idx + 3]:
            upcoming_rain_48h_mm += daily_weather[f_date].get("precipitation_mm", 0.0)

    upcoming_rain_48h_mm = round(upcoming_rain_48h_mm, 1)

    # Fetch Regional Economic Profile
    location_label = payload.field_name
    if payload.plot_id and plot:
        location_label = plot.location_name or payload.field_name

    regional_profile = await run_in_threadpool(
        RegionalTariffService.get_tariff_for_plot,
        db,
        location_name=location_label,
        lat=payload.latitude,
        lon=payload.longitude
    )

    is_electric = payload.irrigation_method in ["drip", "sprinkler"]
    tariff_inr_hr = regional_profile.electric_tariff_inr_hr if is_electric else regional_profile.diesel_tariff_inr_hr
    co2_factor_kg_hr = regional_profile.electric_co2_kg_hr if is_electric else regional_profile.diesel_co2_kg_hr

    needs_irrigation_would_have_been_true = today_decision.get("needs_irrigation", False)
    needs_irrigation_today = needs_irrigation_would_have_been_true
    status_summary = today_decision.get("status", "SOIL MOISTURE OPTIMAL")
    rain_hold_active = False
    rain_hold_message = None
    estimated_cost_saved_inr = 0.0

    # Rain Hold Trigger Condition
    if (upcoming_rain_24h_mm >= RAIN_HOLD_24H_THRESHOLD_MM or 
        upcoming_rain_48h_mm >= RAIN_HOLD_48H_THRESHOLD_MM or 
        (weather_summary and weather_summary.precipitation_mm >= RAIN_HOLD_TODAY_PRECIP_THRESHOLD_MM)):
        rain_hold_active = True
        if needs_irrigation_would_have_been_true:
            needs_irrigation_today = False
            status_summary = "RAIN_HOLD"
            hours_saved = max(total_pump_seconds / 3600.0, MINIMUM_HOURS_SAVED_RAIN_HOLD)
            estimated_cost_saved_inr = round(hours_saved * tariff_inr_hr, 0)
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

    # 11. REGIONAL FARMER ROI & SAVINGS TRACKER (F-14 Fix: Sane Skipped Runs Counting)
    # Skipped runs increment ONLY when Rain Hold actually overrides a needed irrigation event.
    if payload.plot_id and depletion_record:
        if rain_hold_active and needs_irrigation_would_have_been_true:
            if depletion_record.last_rain_hold_date != today_obj:
                def _update_rain_hold_skipped(rec, d_today):
                    rec.skipped_runs_count += 1
                    rec.last_rain_hold_date = d_today
                    db.commit()

                await run_in_threadpool(_update_rain_hold_skipped, depletion_record, today_obj)
        session_count = depletion_record.skipped_runs_count
    else:
        session_count = 1 if (rain_hold_active and needs_irrigation_would_have_been_true) else 0

    if session_count > 0:
        saved_water_per_session_mm = max(
            MINIMUM_WATER_SAVED_PER_SESSION_MM,
            (gross_water_mm * TRADITIONAL_FLOOD_WASTE_FRACTION) if gross_water_mm > 0 else FALLBACK_WATER_SAVED_PER_SESSION_MM
        )
        cum_water_liters = round(saved_water_per_session_mm * area_sqm * session_count, 0)
        cum_pump_hours = round(cum_water_liters / (flow_lps * 3600.0), 1)
        cum_money_saved = round(cum_pump_hours * tariff_inr_hr + (estimated_cost_saved_inr if rain_hold_active else 0.0), 0)
        cum_co2_kg = round(cum_pump_hours * co2_factor_kg_hr, 1)
    else:
        cum_water_liters = 0.0
        cum_pump_hours = 0.0
        cum_money_saved = 0.0
        cum_co2_kg = 0.0

    cumulative_savings = CumulativeSavings(
        total_water_saved_liters=cum_water_liters,
        total_pump_hours_saved=cum_pump_hours,
        total_money_saved_inr=cum_money_saved,
        total_co2_reduced_kg=cum_co2_kg,
        skipped_runs_count=session_count,
        state_code=regional_profile.state_code,
        state_name=regional_profile.state_name,
        tariff_rate_inr_hr=tariff_inr_hr,
        co2_factor_kg_hr=co2_factor_kg_hr,
        attribution_notice=regional_profile.attribution_notice
    )

    soil_display = SOIL_DISPLAY_MAP.get(payload.soil_type, "Clay Loam (High Retention)")
    soil_is_fallback = props.get("is_fallback", False)

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
        soil_is_fallback=soil_is_fallback,
        status_summary=status_summary,
        crop_lifecycle_status=crop_lifecycle_status,
        crop_status_message=crop_status_message,
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