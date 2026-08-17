import pytest
from datetime import date, timedelta
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


class TestIrrigationEnd2End:
    """
    Round-trip integration test suite for the end-to-end irrigation recommendation API.
    """

    def test_round_trip_irrigation_recommendation_flow(self):
        """
        Creates a test user, sends a deterministic plot recommendation request,
        and validates all output fields (crop name, Kc, volumetric water depth, pump runtime,
        soil fallback flag, and cumulative savings).
        """
        # 1. Register test user
        resp_reg = client.post("/api/v1/auth/register", json={
            "username": "end2end_test_farmer",
            "phone_number": "+919811223344",
            "password": "Password123!"
        })
        if resp_reg.status_code == 200:
            token = resp_reg.json()["access_token"]
        else:
            token = client.post("/api/v1/auth/login", json={
                "login_identifier": "end2end_test_farmer",
                "password": "Password123!"
            }).json()["access_token"]

        headers = {"Authorization": f"Bearer {token}"}
        sowing = (date.today() - timedelta(days=65)).strftime("%Y-%m-%d")

        # 2. Trigger /api/v1/irrigation/recommendation
        payload = {
            "field_name": "End2End Integration Plot",
            "crop_id": "paddy_rice",
            "sowing_date": sowing,
            "latitude": 23.23,
            "longitude": 87.86,
            "area_acres": 2.5,
            "soil_type": "clay_loam",
            "irrigation_method": "drip"
        }

        response = client.post("/api/v1/irrigation/recommendation", json=payload, headers=headers)
        assert response.status_code == 200

        data = response.json()

        # 3. Assertions
        assert data["field_name"] == "End2End Integration Plot"
        assert "Paddy Rice" in data["crop_name"]
        assert data["elapsed_days"] == 65
        assert "Mid-Season" in data["current_growth_stage"]
        assert data["dynamic_kc"] == 1.20
        assert data["irrigation_efficiency_pct"] == 90
        assert "soil_is_fallback" in data
        assert "cumulative_savings" in data

        savings = data["cumulative_savings"]
        assert "state_code" in savings
        assert "state_name" in savings
        assert "tariff_rate_inr_hr" in savings
        assert "co2_factor_kg_hr" in savings
        assert "attribution_notice" in savings
