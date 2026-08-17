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

    def test_crop_dev_stage_kc_linear_interpolation(self, paddy_crop_config):
        """
        Boundary Test: Day 35 (15 days into 30-day Development stage, exactly midway).
        Kc should interpolate linearly between Kc_init (1.05) and Kc_mid (1.20).
        Midway Kc = 1.05 + 0.5 * (1.20 - 1.05) = 1.125 -> rounded to 1.13.
        """
        today = date.today()
        sowing_date = today - timedelta(days=35) # 20 (init) + 15 (half of dev)

        res = SoilWaterBucketModel.calculate_dynamic_crop_stage(sowing_date, paddy_crop_config)

        assert res["elapsed_days"] == 35
        assert "Vegetative" in res["current_stage"]
        assert res["dynamic_kc"] == pytest.approx(1.13, abs=0.02)

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

    def test_late_season_kc_boundary(self, paddy_crop_config):
        """
        Boundary Test: Day 100 (Late-Season stage: >90 days).
        Kc should equal Late-Season Kc (0.90 for Paddy Rice).
        """
        today = date.today()
        sowing_date = today - timedelta(days=100)

        res = SoilWaterBucketModel.calculate_dynamic_crop_stage(sowing_date, paddy_crop_config)

        assert res["elapsed_days"] == 100
        assert "Late Season" in res["current_stage"]
        assert res["dynamic_kc"] == 0.90
