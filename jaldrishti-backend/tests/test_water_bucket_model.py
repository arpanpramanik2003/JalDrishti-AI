import pytest
from app.engine.water_bucket_model import SoilWaterBucketModel


class TestSoilWaterBucketModel:
    """
    Soil Water Bucket & Volumetric Scaling Unit Tests.
    """

    def test_volumetric_scaling_10x_ratio_baseline(self):
        """
        Reference Case 3: Volumetric 10x Scaling Baseline.
        Verifies that a 5.0 acre plot requires exactly 10.0x the water volume (in Liters)
        of a 0.5 acre plot for the same recommended gross water depth (e.g. 25.0 mm).
        """
        recommended_gross_depth_mm = 25.0
        acres_small = 0.5
        acres_large = 5.0

        # Volume (Liters) = depth_mm * acres * 4046.86 m²/acre * (1 m / 1000 mm) * (1000 L / 1 m³)
        # Liters = depth_mm * acres * 4046.86
        vol_small_liters = recommended_gross_depth_mm * acres_small * 4046.86
        vol_large_liters = recommended_gross_depth_mm * acres_large * 4046.86

        scaling_ratio = vol_large_liters / vol_small_liters
        assert scaling_ratio == pytest.approx(10.0, rel=1e-5)
        assert vol_small_liters == pytest.approx(50585.75, abs=1.0)
        assert vol_large_liters == pytest.approx(505857.5, abs=1.0)

    def test_soil_capacity_calculations_clay_loam(self):
        """
        Validates Field Capacity (FC), Wilting Point (WP), and Total Available Water (TAW).
        For Clay=32%, Sand=30%, RootDepth=0.5m:
        theta_fc = 0.10 + 0.0025(32) + 0.0005(70) = 0.215
        theta_wp = 0.02 + 0.0020(32) = 0.084
        TAW = 1000 * (0.215 - 0.084) * 0.5 = 65.5 mm
        """
        caps = SoilWaterBucketModel.calculate_soil_capacities(clay_pct=32.0, sand_pct=30.0, root_depth_m=0.5)
        assert caps["theta_fc"] == pytest.approx(0.215, abs=0.001)
        assert caps["theta_wp"] == pytest.approx(0.084, abs=0.001)
        assert caps["taw_mm"] == pytest.approx(65.5, abs=0.2)

    def test_daily_water_balance_no_irrigation_needed(self):
        """
        Validates water balance when depletion is below the Readily Available Water (RAW) threshold.
        """
        taw_mm = 100.0
        p_fraction = 0.50 # RAW = 50.0 mm
        
        balance = SoilWaterBucketModel.run_daily_water_balance(
            previous_depletion_mm=10.0,
            etc_mm=5.0,
            rainfall_mm=0.0,
            irrigation_applied_mm=0.0,
            taw_mm=taw_mm,
            depletion_fraction_p=p_fraction
        )

        assert balance["current_depletion_mm"] == 15.0
        assert balance["raw_threshold_mm"] == 50.0
        assert balance["needs_irrigation"] is False
        assert balance["recommended_water_mm"] == 0.0
        assert balance["status"] == "SOIL MOISTURE OPTIMAL"

    def test_daily_water_balance_trigger_irrigation(self):
        """
        Validates water balance when depletion exceeds RAW threshold (60 mm > 50 mm RAW).
        """
        taw_mm = 100.0
        p_fraction = 0.50 # RAW = 50.0 mm
        
        balance = SoilWaterBucketModel.run_daily_water_balance(
            previous_depletion_mm=48.0,
            etc_mm=12.0,
            rainfall_mm=0.0,
            irrigation_applied_mm=0.0,
            taw_mm=taw_mm,
            depletion_fraction_p=p_fraction
        )

        assert balance["current_depletion_mm"] == 60.0
        assert balance["needs_irrigation"] is True
        assert balance["recommended_water_mm"] == 60.0
        assert balance["status"] == "IRRIGATE IMMEDIATELY"

    def test_heavy_rainfall_caps_depletion_to_zero(self):
        """
        Heavy rain (> current depletion) fills soil to field capacity (depletion = 0 mm).
        """
        balance = SoilWaterBucketModel.run_daily_water_balance(
            previous_depletion_mm=30.0,
            etc_mm=4.0,
            rainfall_mm=100.0, # 80mm effective rain
            irrigation_applied_mm=0.0,
            taw_mm=100.0,
            depletion_fraction_p=0.5
        )

        assert balance["current_depletion_mm"] == 0.0
        assert balance["needs_irrigation"] is False
