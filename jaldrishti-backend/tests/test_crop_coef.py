import json
import os
from datetime import date, timedelta
import pytest
from app.engine.water_bucket_model import SoilWaterBucketModel


class TestCropCoefficients:
    """
    Kc Stage Interpolation & Boundary Condition Tests.
    """

    @pytest.fixture
    def paddy_crop_config(self):
        json_path = os.path.join(os.path.dirname(__file__), '..', 'app', 'engine', 'crop_coefficients.json')
        with open(json_path, 'r', encoding='utf-8') as f:
            crop_db = json.load(f)
        return crop_db["paddy_rice"]

    def test_initial_stage_kc_boundary(self, paddy_crop_config):
        """
        Boundary Test: Day 10 (within 20-day Initial stage).
        Kc should equal initial stage Kc (1.05 for Paddy Rice).
        """
        today = date.today()
        sowing_date = today - timedelta(days=10)

        res = SoilWaterBucketModel.calculate_dynamic_crop_stage(sowing_date, paddy_crop_config)

        assert res["elapsed_days"] == 10
        assert "Initial Stage" in res["current_stage"]
        assert res["dynamic_kc"] == 1.05
        assert res["crop_status"] == "ACTIVE"

    def test_crop_dev_stage_kc_linear_interpolation(self, paddy_crop_config):
        """
        Boundary Test: Day 35 (15 days into 30-day Development stage, exactly midway).
        Kc should interpolate linearly between Kc_init (1.05) and Kc_mid (1.20).
        Midway Kc = 1.05 + 0.5 * (1.20 - 1.05) = 1.125 -> rounded to 1.13.
        """
        today = date.today()
        sowing_date = today - timedelta(days=35)  # 20 (init) + 15 (half of dev)

        res = SoilWaterBucketModel.calculate_dynamic_crop_stage(sowing_date, paddy_crop_config)

        assert res["elapsed_days"] == 35
        assert "Vegetative" in res["current_stage"]
        assert res["dynamic_kc"] == pytest.approx(1.13, abs=0.02)
        assert res["crop_status"] == "ACTIVE"

    def test_mid_season_kc_boundary(self, paddy_crop_config):
        """
        Boundary Test: Day 65 (within Mid-Season stage: days 51-90).
        Kc should equal peak Mid-Season Kc (1.20 for Paddy Rice).
        """
        today = date.today()
        sowing_date = today - timedelta(days=65)

        res = SoilWaterBucketModel.calculate_dynamic_crop_stage(sowing_date, paddy_crop_config)

        assert res["elapsed_days"] == 65
        assert "Mid-Season" in res["current_stage"]
        assert res["dynamic_kc"] == 1.20
        assert res["crop_status"] == "ACTIVE"

    def test_late_season_kc_linear_decay_interpolation(self, paddy_crop_config):
        """
        F-12 Linear Decay Test: Day 100 (10 days into 30-day Late-Season stage).
        Kc should linearly decay from Kc_mid (1.20) toward Kc_end (0.90).
        Decay progress = 10 / 30 = 0.3333
        Expected Kc = 1.20 + (1/3) * (0.90 - 1.20) = 1.10.
        """
        today = date.today()
        sowing_date = today - timedelta(days=100)

        res = SoilWaterBucketModel.calculate_dynamic_crop_stage(sowing_date, paddy_crop_config)

        assert res["elapsed_days"] == 100
        assert "Late Season" in res["current_stage"]
        assert res["dynamic_kc"] == pytest.approx(1.10, abs=0.01)
        assert res["crop_status"] == "ACTIVE"

    def test_late_season_kc_at_harvest(self, paddy_crop_config):
        """
        F-12 Harvest Day Test: Day 120 (exactly at completion of late season).
        Kc should reach Kc_end (0.90 for Paddy Rice).
        """
        today = date.today()
        sowing_date = today - timedelta(days=120)

        res = SoilWaterBucketModel.calculate_dynamic_crop_stage(sowing_date, paddy_crop_config)

        assert res["elapsed_days"] == 120
        assert res["dynamic_kc"] == 0.90
        assert res["crop_status"] == "ACTIVE"

    def test_future_sowing_date_boundary(self, paddy_crop_config):
        """
        F-13 Boundary Test: Sowing date is 5 days in the future.
        Must return crop_status="NOT_YET_SOWN" with negative elapsed days and dynamic_kc=0.0.
        """
        today = date.today()
        sowing_date = today + timedelta(days=5)

        res = SoilWaterBucketModel.calculate_dynamic_crop_stage(sowing_date, paddy_crop_config)

        assert res["elapsed_days"] == -5
        assert res["crop_status"] == "NOT_YET_SOWN"
        assert res["dynamic_kc"] == 0.0
        assert "future" in res["status_message"].lower()

    def test_post_harvest_overdue_boundary(self, paddy_crop_config):
        """
        Lifecycle Boundary Test: Day 140 (>120 + 15 days overdue).
        Must return crop_status="HARVEST_OVERDUE" with dynamic_kc=0.0.
        """
        today = date.today()
        sowing_date = today - timedelta(days=140)

        res = SoilWaterBucketModel.calculate_dynamic_crop_stage(sowing_date, paddy_crop_config)

        assert res["elapsed_days"] == 140
        assert res["crop_status"] == "HARVEST_OVERDUE"
        assert res["dynamic_kc"] == 0.0
        assert "completed" in res["status_message"].lower()
