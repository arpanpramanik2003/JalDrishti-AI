from datetime import datetime, date

class SoilWaterBucketModel:
    @staticmethod
    def calculate_dynamic_crop_stage(sowing_date_val, crop_stages_config: dict) -> dict:
        """
        Dynamically calculates the current growth stage, Kc factor, and root depth 
        based on the farmer's Sowing Date and elapsed days.
        """
        if isinstance(sowing_date_val, date):
            sowing_date = sowing_date_val
        elif isinstance(sowing_date_val, datetime):
            sowing_date = sowing_date_val.date()
        else:
            sowing_date = datetime.strptime(str(sowing_date_val), "%Y-%m-%d").date()

        today = date.today()
        elapsed_days = max(0, (today - sowing_date).days)

        stages = crop_stages_config.get("stages", {})
        init_days = stages.get("initial", {}).get("duration_days", 20)
        dev_days = stages.get("crop_dev", {}).get("duration_days", 30)
        mid_days = stages.get("mid_season", {}).get("duration_days", 40)
        late_days = stages.get("late_season", {}).get("duration_days", 30)

        max_root_depth = crop_stages_config.get("root_depth_m", 0.5)

        # Stage 1: Initial
        if elapsed_days <= init_days:
            current_stage = "Initial Stage (Sowing/Germination)"
            kc = stages.get("initial", {}).get("Kc", 0.45)
            effective_root_depth = max(0.15, max_root_depth * 0.3)
        # Stage 2: Development
        elif elapsed_days <= (init_days + dev_days):
            current_stage = "Vegetative / Crop Development"
            kc_init = stages.get("initial", {}).get("Kc", 0.45)
            kc_mid = stages.get("mid_season", {}).get("Kc", 1.15)
            progress = (elapsed_days - init_days) / dev_days
            kc = kc_init + progress * (kc_mid - kc_init)
            effective_root_depth = max_root_depth * (0.3 + 0.7 * progress)
        # Stage 3: Mid-Season
        elif elapsed_days <= (init_days + dev_days + mid_days):
            current_stage = "Mid-Season (Flowering/Yield Formation)"
            kc = stages.get("mid_season", {}).get("Kc", 1.15)
            effective_root_depth = max_root_depth
        # Stage 4: Late Season
        else:
            current_stage = "Late Season (Ripening/Maturity)"
            kc = stages.get("late_season", {}).get("Kc", 0.75)
            effective_root_depth = max_root_depth

        return {
            "elapsed_days": elapsed_days,
            "current_stage": current_stage,
            "dynamic_kc": round(kc, 2),
            "effective_root_depth_m": round(effective_root_depth, 2)
        }

    @staticmethod
    def calculate_soil_capacities(clay_pct: float, sand_pct: float, root_depth_m: float) -> dict:
        theta_fc = 0.10 + 0.0025 * clay_pct + 0.0005 * (100.0 - sand_pct)
        theta_wp = 0.02 + 0.0020 * clay_pct
        taw_mm = 1000.0 * (theta_fc - theta_wp) * root_depth_m

        return {
            "theta_fc": round(theta_fc, 3),
            "theta_wp": round(theta_wp, 3),
            "taw_mm": round(taw_mm, 2)
        }

    @staticmethod
    def run_daily_water_balance(
        previous_depletion_mm: float,
        etc_mm: float,
        rainfall_mm: float,
        irrigation_applied_mm: float,
        taw_mm: float,
        depletion_fraction_p: float
    ) -> dict:
        raw_mm = depletion_fraction_p * taw_mm
        effective_rain = min(rainfall_mm * 0.8, rainfall_mm)

        current_depletion = previous_depletion_mm - effective_rain - irrigation_applied_mm + etc_mm
        current_depletion = max(0.0, min(taw_mm, current_depletion))

        needs_irrigation = current_depletion >= raw_mm
        recommended_water_mm = round(current_depletion, 1) if needs_irrigation else 0.0

        return {
            "current_depletion_mm": round(current_depletion, 2),
            "raw_threshold_mm": round(raw_mm, 2),
            "taw_mm": round(taw_mm, 2),
            "needs_irrigation": needs_irrigation,
            "recommended_water_mm": recommended_water_mm,
            "status": "IRRIGATE IMMEDIATELY" if needs_irrigation else "SOIL MOISTURE OPTIMAL"
        }