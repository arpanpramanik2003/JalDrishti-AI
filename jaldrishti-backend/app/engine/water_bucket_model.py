from datetime import datetime, date
from typing import Dict, Any, Union, Optional
from app.core.constants import (
    EFFECTIVE_RAINFALL_COEFFICIENT,
    POST_HARVEST_MAX_OVERDUE_DAYS,
    INITIAL_ROOT_DEPTH_FRACTION,
    MINIMUM_EFFECTIVE_ROOT_DEPTH_M
)


class SoilWaterBucketModel:
    """
    Implements the FAO-56 daily root-zone soil water balance model (FAO Paper 56, Chapter 8).
    Tracks depletion D_i, Total Available Water (TAW), Readily Available Water (RAW),
    and dynamic crop growth stage interpolation Kc(t).
    """

    @staticmethod
    def calculate_dynamic_crop_stage(
        sowing_date_val: Union[date, datetime, str],
        crop_stages_config: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Dynamically calculates the current growth stage, Kc factor, and root depth 
        based on the farmer's Sowing Date and elapsed days per FAO-56 Chapter 6 (Eq. 66).

        Handles boundary conditions:
        - Future sowing dates: returns crop_status="NOT_YET_SOWN" with negative elapsed days.
        - Post-harvest runaway: returns crop_status="HARVEST_OVERDUE" if elapsed days exceed
          total lifecycle by more than POST_HARVEST_MAX_OVERDUE_DAYS (15 days).
        - Late-season linear decay: interpolates Kc linearly from Kc_mid to Kc_end.

        Parameters:
        - sowing_date_val: Date of planting / sowing
        - crop_stages_config: Phenological parameters loaded from crop_coefficients.json

        Returns:
        - Dict with elapsed_days, current_stage, dynamic_kc, effective_root_depth_m,
          crop_status, and status_message.
        """
        if isinstance(sowing_date_val, date) and not isinstance(sowing_date_val, datetime):
            sowing_date = sowing_date_val
        elif isinstance(sowing_date_val, datetime):
            sowing_date = sowing_date_val.date()
        else:
            sowing_date = datetime.strptime(str(sowing_date_val), "%Y-%m-%d").date()

        today = date.today()
        elapsed_days = (today - sowing_date).days

        stages = crop_stages_config.get("stages", {})
        init_days = stages.get("initial", {}).get("duration_days", 20)
        dev_days = stages.get("crop_dev", {}).get("duration_days", 30)
        mid_days = stages.get("mid_season", {}).get("duration_days", 40)
        late_days = stages.get("late_season", {}).get("duration_days", 30)
        total_cycle_days = init_days + dev_days + mid_days + late_days

        max_root_depth = crop_stages_config.get("root_depth_m", 0.5)

        # Boundary Case 1: Future Sowing Date (F-13)
        if elapsed_days < 0:
            return {
                "elapsed_days": elapsed_days,
                "current_stage": "Not Yet Sown (Pre-Planting)",
                "dynamic_kc": 0.0,
                "effective_root_depth_m": 0.0,
                "crop_status": "NOT_YET_SOWN",
                "status_message": (
                    f"Crop sowing date is in the future ({sowing_date.strftime('%Y-%m-%d')}, "
                    f"{abs(elapsed_days)} day(s) remaining). Irrigation recommendations are inactive."
                )
            }

        # Boundary Case 2: Post-Harvest Runaway (Exceeds total lifecycle + 15-day tolerance)
        if elapsed_days > (total_cycle_days + POST_HARVEST_MAX_OVERDUE_DAYS):
            return {
                "elapsed_days": elapsed_days,
                "current_stage": "Post-Harvest / Lifecycle Completed",
                "dynamic_kc": 0.0,
                "effective_root_depth_m": max_root_depth,
                "crop_status": "HARVEST_OVERDUE",
                "status_message": (
                    f"Crop total documented lifecycle ({total_cycle_days} days) completed "
                    f"{elapsed_days - total_cycle_days} days ago. Active irrigation recommendations halted."
                )
            }

        # Stage 1: Initial (Sowing / Germination / Early Establishment)
        if elapsed_days <= init_days:
            current_stage = "Initial Stage (Sowing/Germination)"
            kc = stages.get("initial", {}).get("Kc", 0.45)
            effective_root_depth = max(MINIMUM_EFFECTIVE_ROOT_DEPTH_M, max_root_depth * INITIAL_ROOT_DEPTH_FRACTION)

        # Stage 2: Development (Vegetative Canopy Development) - Linear interpolation from Kc_init to Kc_mid
        elif elapsed_days <= (init_days + dev_days):
            current_stage = "Vegetative / Crop Development"
            kc_init = stages.get("initial", {}).get("Kc", 0.45)
            kc_mid = stages.get("mid_season", {}).get("Kc", 1.15)
            progress = (elapsed_days - init_days) / dev_days if dev_days > 0 else 1.0
            kc = kc_init + progress * (kc_mid - kc_init)
            effective_root_depth = max_root_depth * (INITIAL_ROOT_DEPTH_FRACTION + (1.0 - INITIAL_ROOT_DEPTH_FRACTION) * progress)

        # Stage 3: Mid-Season (Flowering / Yield Formation) - Peak Kc
        elif elapsed_days <= (init_days + dev_days + mid_days):
            current_stage = "Mid-Season (Flowering/Yield Formation)"
            kc = stages.get("mid_season", {}).get("Kc", 1.15)
            effective_root_depth = max_root_depth

        # Stage 4: Late Season (Ripening / Maturity) - FAO-56 linear decay from Kc_mid to Kc_end (F-12)
        elif elapsed_days <= total_cycle_days:
            current_stage = "Late Season (Ripening/Maturity)"
            kc_mid = stages.get("mid_season", {}).get("Kc", 1.15)
            kc_end = stages.get("late_season", {}).get("Kc", 0.75)
            days_into_late = elapsed_days - (init_days + dev_days + mid_days)
            progress = max(0.0, min(1.0, days_into_late / late_days)) if late_days > 0 else 1.0
            kc = kc_mid + progress * (kc_end - kc_mid)
            effective_root_depth = max_root_depth

        # Stage 5: Grace period awaiting harvest (within 15 days past total_cycle_days)
        else:
            current_stage = "Maturity Reached (Awaiting Harvest)"
            kc = stages.get("late_season", {}).get("Kc", 0.75)
            effective_root_depth = max_root_depth

        return {
            "elapsed_days": elapsed_days,
            "current_stage": current_stage,
            "dynamic_kc": round(kc, 2),
            "effective_root_depth_m": round(effective_root_depth, 2),
            "crop_status": "ACTIVE",
            "status_message": None
        }

    @staticmethod
    def calculate_soil_capacities(clay_pct: float, sand_pct: float, root_depth_m: float) -> Dict[str, float]:
        """
        Calculates soil moisture retention thresholds using standard pedotransfer functions
        (Saxton & Rawls / FAO-56 Chapter 8):
        - Field Capacity (theta_fc): volumetric water content at -33 kPa matric potential
        - Wilting Point (theta_wp): volumetric water content at -1500 kPa matric potential
        - Total Available Water (TAW): 1000 * (theta_fc - theta_wp) * root_depth_m (FAO-56 Eq. 82)
        """
        theta_fc = 0.10 + 0.0025 * clay_pct + 0.0005 * (100.0 - sand_pct)
        theta_wp = 0.02 + 0.0020 * clay_pct
        taw_mm = 1000.0 * (theta_fc - theta_wp) * root_depth_m

        return {
            "theta_fc": round(theta_fc, 3),
            "theta_wp": round(theta_wp, 3),
            "taw_mm": max(10.0, round(taw_mm, 2))
        }

    @staticmethod
    def run_daily_water_balance(
        previous_depletion_mm: float,
        etc_mm: float,
        rainfall_mm: float,
        irrigation_applied_mm: float,
        taw_mm: float,
        depletion_fraction_p: float
    ) -> Dict[str, Any]:
        """
        Executes daily root-zone mass balance per FAO-56 Eq. 85:

            D_i = D_{i-1} - P_eff - I_{applied} + ET_c

        Constraints:
        - Depletion is clamped to [0, TAW]:
          - Cannot be negative (excess water beyond field capacity is lost to deep percolation / runoff)
          - Cannot exceed TAW (soil cannot dry past permanent wilting point without stress shutdown)
        - Readily Available Water threshold:
          RAW = p * TAW (FAO-56 Eq. 83)
        """
        raw_mm = depletion_fraction_p * taw_mm
        effective_rain = min(rainfall_mm * EFFECTIVE_RAINFALL_COEFFICIENT, rainfall_mm)

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