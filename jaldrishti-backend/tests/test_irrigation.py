import uuid
import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_irrigation_recommendation_and_logging():
    # 0. Authenticate Test User
    unique_str = uuid.uuid4().hex[:8]
    username = f"irr_{unique_str}"
    phone = f"97{uuid.uuid4().int % 100000000:08d}"

    reg_resp = client.post("/api/v1/auth/register", json={
        "username": username,
        "phone_number": phone,
        "password": "pass123456"
    })
    token = reg_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

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

    response = client.post("/api/v1/irrigation/recommendation", json=req_payload, headers=headers)
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
    }, headers=headers)
    assert log_resp.status_code == 200
    assert log_resp.json()["applied_mm"] == 25.0

    # Fetch History
    hist_resp = client.get(f"/api/v1/irrigation/history/{plot_id}", headers=headers)
    assert hist_resp.status_code == 200
    assert len(hist_resp.json()) >= 1


def test_f01_and_f02_logged_irrigation_reduces_soil_depletion():
    """
    F-01 and F-02 Correctness Test:
    1. Verify that logged irrigation applied today (date object) is correctly matched
       against today's string date in the water balance engine (no date vs str bug).
    2. Verify that logging water applied reduces today's reported depletion.
    """
    from datetime import date, timedelta

    # 1. Register & authenticate test farmer
    unique_str = uuid.uuid4().hex[:8]
    reg_resp = client.post("/api/v1/auth/register", json={
        "username": f"dep_{unique_str}",
        "phone_number": f"98{uuid.uuid4().int % 100000000:08d}",
        "password": "password123"
    })
    token = reg_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Create a farm plot sown 30 days ago (vegetative stage)
    sowing_date = (date.today() - timedelta(days=30)).strftime("%Y-%m-%d")
    plot_resp = client.post("/api/v1/plots/", json={
        "name": "Depletion Test Plot",
        "latitude": 23.23,
        "longitude": 87.86,
        "crop_id": "paddy_rice",
        "sowing_date": sowing_date,
        "area_acres": 2.0,
        "pump_hp": 5.0,
        "irrigation_method": "flood",
        "soil_type": "clay_loam"
    }, headers=headers)
    assert plot_resp.status_code == 200
    plot_id = plot_resp.json()["id"]

    rec_payload = {
        "plot_id": plot_id,
        "latitude": 23.23,
        "longitude": 87.86,
        "crop_id": "paddy_rice",
        "sowing_date": sowing_date,
        "field_name": "Depletion Test Plot",
        "area_acres": 2.0,
        "irrigation_method": "flood",
        "soil_type": "clay_loam"
    }

    # Initial recommendation before irrigation
    rec1 = client.post("/api/v1/irrigation/recommendation", json=rec_payload, headers=headers)
    assert rec1.status_code == 200
    data1 = rec1.json()

    today_str = date.today().strftime("%Y-%m-%d")
    today_metric1 = next((m for m in data1["daily_breakdown"] if m["date"] == today_str), None)
    assert today_metric1 is not None
    depletion_before = today_metric1["depletion_mm"]

    # 3. Log 20.0 mm of irrigation applied today
    log_resp = client.post("/api/v1/irrigation/log", json={
        "farm_plot_id": plot_id,
        "applied_mm": 20.0,
        "applied_date": today_str,
        "notes": "Applied 20mm morning watering"
    }, headers=headers)
    assert log_resp.status_code == 200

    # 4. Request recommendation again after logging irrigation
    rec2 = client.post("/api/v1/irrigation/recommendation", json=rec_payload, headers=headers)
    assert rec2.status_code == 200
    data2 = rec2.json()

    today_metric2 = next((m for m in data2["daily_breakdown"] if m["date"] == today_str), None)
    assert today_metric2 is not None
    depletion_after = today_metric2["depletion_mm"]

    # Assert applied water was registered and depletion was reduced (or clamped at 0.0)
    assert today_metric2["irrigation_applied_mm"] == 20.0
    assert (depletion_after < depletion_before) or (depletion_after == 0.0)


def test_f13_future_sowing_date_inactive_recommendation():
    """
    F-13 Verification: Sowing date in the future returns NOT_YET_SOWN status
    and null recommended water.
    """
    from datetime import date, timedelta

    unique_str = uuid.uuid4().hex[:8]
    reg_resp = client.post("/api/v1/auth/register", json={
        "username": f"fut_{unique_str}",
        "phone_number": f"98{uuid.uuid4().int % 100000000:08d}",
        "password": "password123"
    })
    headers = {"Authorization": f"Bearer {reg_resp.json()['access_token']}"}

    future_sowing = (date.today() + timedelta(days=10)).strftime("%Y-%m-%d")
    resp = client.post("/api/v1/irrigation/recommendation", json={
        "latitude": 22.57,
        "longitude": 88.36,
        "crop_id": "paddy_rice",
        "sowing_date": future_sowing,
        "field_name": "Future Plot"
    }, headers=headers)

    assert resp.status_code == 200
    data = resp.json()
    assert data["status_summary"] == "NOT_YET_SOWN"
    assert data["crop_lifecycle_status"] == "NOT_YET_SOWN"
    assert data["recommended_water_mm"] is None
    assert data["recommended_gross_water_mm"] is None
    assert data["recommended_pump_hours"] == 0
    assert data["needs_irrigation_today"] is False


def test_post_harvest_overdue_inactive_recommendation():
    """
    Lifecycle Verification: Sowing date 200 days ago for 120-day paddy rice
    exceeds the 15-day overdue tolerance, returning HARVEST_OVERDUE status.
    """
    from datetime import date, timedelta

    unique_str = uuid.uuid4().hex[:8]
    reg_resp = client.post("/api/v1/auth/register", json={
        "username": f"over_{unique_str}",
        "phone_number": f"98{uuid.uuid4().int % 100000000:08d}",
        "password": "password123"
    })
    headers = {"Authorization": f"Bearer {reg_resp.json()['access_token']}"}

    overdue_sowing = (date.today() - timedelta(days=200)).strftime("%Y-%m-%d")
    resp = client.post("/api/v1/irrigation/recommendation", json={
        "latitude": 22.57,
        "longitude": 88.36,
        "crop_id": "paddy_rice",
        "sowing_date": overdue_sowing,
        "field_name": "Overdue Plot"
    }, headers=headers)

    assert resp.status_code == 200
    data = resp.json()
    assert data["status_summary"] == "HARVEST_OVERDUE"
    assert data["crop_lifecycle_status"] == "HARVEST_OVERDUE"
    assert data["recommended_water_mm"] is None
    assert data["needs_irrigation_today"] is False

