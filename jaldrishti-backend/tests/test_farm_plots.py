import uuid
import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_farm_plots_crud():
    # 1. Register User
    unique_str = uuid.uuid4().hex[:8]
    reg_payload = {
        "username": f"plotuser_{unique_str}",
        "phone_number": f"97{uuid.uuid4().int % 100000000:08d}",
        "password": "securepassword123"
    }
    reg_resp = client.post("/api/v1/auth/register", json=reg_payload)
    assert reg_resp.status_code == 200
    token = reg_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Get Plots (should be empty initially)
    get_init_resp = client.get("/api/v1/plots/", headers=headers)
    assert get_init_resp.status_code == 200
    assert len(get_init_resp.json()) == 0

    # 3. Create First Plot ("Main Field")
    plot1_payload = {
        "name": "Main Paddy Plot",
        "location_name": "Burdwan, WB",
        "latitude": 23.2324,
        "longitude": 87.8615,
        "crop_id": "paddy_rice",
        "sowing_date": "2026-06-15",
        "area_acres": 3.5,
        "is_primary": True
    }
    create_resp1 = client.post("/api/v1/plots/", json=plot1_payload, headers=headers)
    assert create_resp1.status_code == 200
    plot1_data = create_resp1.json()
    assert plot1_data["name"] == "Main Paddy Plot"
    assert plot1_data["is_primary"] is True
    plot1_id = plot1_data["id"]

    # 4. Create Second Plot ("North Wheat Field")
    plot2_payload = {
        "name": "North Wheat Field",
        "location_name": "Hooghly, WB",
        "latitude": 22.9032,
        "longitude": 88.3842,
        "crop_id": "wheat",
        "sowing_date": "2026-11-01",
        "area_acres": 2.0,
        "is_primary": False
    }
    create_resp2 = client.post("/api/v1/plots/", json=plot2_payload, headers=headers)
    assert create_resp2.status_code == 200
    plot2_id = create_resp2.json()["id"]

    # 5. List Plots
    list_resp = client.get("/api/v1/plots/", headers=headers)
    assert list_resp.status_code == 200
    plots = list_resp.json()
    assert len(plots) == 2

    # 6. Set Second Plot as Primary
    set_primary_resp = client.put(f"/api/v1/plots/{plot2_id}/set-primary", headers=headers)
    assert set_primary_resp.status_code == 200
    assert set_primary_resp.json()["is_primary"] is True

    # 7. Delete First Plot
    del_resp = client.delete(f"/api/v1/plots/{plot1_id}", headers=headers)
    assert del_resp.status_code == 200

    # Verify remaining plots
    list_after_del = client.get("/api/v1/plots/", headers=headers)
    assert len(list_after_del.json()) == 1
