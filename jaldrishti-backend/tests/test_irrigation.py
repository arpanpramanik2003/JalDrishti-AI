import uuid
import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_irrigation_recommendation_and_logging():
    # 1. Test Irrigation Recommendation API
    req_payload = {
        "latitude": 22.5726,
        "longitude": 88.3639,
        "crop_id": "paddy_rice",
        "sowing_date": "2026-06-15",
        "field_name": "Test Paddy Plot",
        "area_acres": 2.5,
        "pump_hp": 5.0,
        "pump_flow_lps": 5.0,
        "irrigation_method": "flood",
        "soil_type": "clay_loam"
    }

    response = client.post("/api/v1/irrigation/recommendation", json=req_payload)
    assert response.status_code == 200, f"Recommendation failed: {response.json()}"
    data = response.json()
    assert "Paddy Rice" in data["crop_name"]
    assert "recommended_gross_water_mm" in data
    assert "recommended_pump_hours" in data
    assert "recommended_pump_minutes" in data
    assert data["irrigation_efficiency_pct"] == 50

    # 2. Test Logging Water Event
    unique_str = uuid.uuid4().hex[:8]
    username = f"irr_{unique_str}"
    phone = f"97{uuid.uuid4().int % 100000000:08d}"

    reg_resp = client.post("/api/v1/auth/register", json={
        "username": username,
        "phone_number": phone,
        "password": "pass123456"
    })
    assert reg_resp.status_code == 200, f"Register failed: {reg_resp.json()}"
    token = reg_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    plot_resp = client.post("/api/v1/plots/", json={
        "name": "Logged Plot",
        "latitude": 22.57,
        "longitude": 88.36,
        "crop_id": "wheat",
        "sowing_date": "2026-06-01",
        "area_acres": 3.0,
        "pump_hp": 5.0,
        "irrigation_method": "drip",
        "soil_type": "loam"
    }, headers=headers)
    assert plot_resp.status_code == 200, f"Plot creation failed: {plot_resp.json()}"
    plot_id = plot_resp.json()["id"]

    # Log 25mm water applied
    log_resp = client.post("/api/v1/irrigation/log", json={
        "farm_plot_id": plot_id,
        "applied_mm": 25.0,
        "notes": "Applied 2 hours of drip watering"
    })
    assert log_resp.status_code == 200
    assert log_resp.json()["applied_mm"] == 25.0

    # Fetch History
    hist_resp = client.get(f"/api/v1/irrigation/history/{plot_id}")
    assert hist_resp.status_code == 200
    assert len(hist_resp.json()) >= 1
