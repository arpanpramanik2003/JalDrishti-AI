import uuid
import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.core.config import settings

client = TestClient(app)


@pytest.fixture
def auth_headers():
    """Generates valid JWT bearer authentication headers for an active test user."""
    unique_str = uuid.uuid4().hex[:8]
    username = f"sec_{unique_str}"
    phone = f"96{uuid.uuid4().int % 100000000:08d}"

    reg_resp = client.post("/api/v1/auth/register", json={
        "username": username,
        "phone_number": phone,
        "password": "SecurePassword123!"
    })
    assert reg_resp.status_code == 200
    token = reg_resp.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


class TestSecurityAuthenticationGuards:
    """
    API Security Test Suite (agency-api-tester).
    Validates that previously unprotected endpoints now strictly enforce
    authentication and authorization, returning 401 or 403 as appropriate.
    """

    # --------------------------------------------------------------------------
    # F-06: Pest Advisory Endpoint Security Tests
    # --------------------------------------------------------------------------

    def test_pest_advisory_rejects_unauthenticated_request(self):
        """
        F-06 Verification: POST /api/v1/crops/pest-advisory must reject requests
        lacking Authorization header with HTTP 401 Unauthorized.
        """
        payload = {
            "crop_id": "paddy_rice",
            "latitude": 22.5726,
            "longitude": 88.3639
        }
        resp = client.post("/api/v1/crops/pest-advisory", json=payload)
        assert resp.status_code == 401, f"Expected 401 Unauthorized, got {resp.status_code}: {resp.text}"

    def test_pest_advisory_rejects_invalid_token(self):
        """
        F-06 Verification: POST /api/v1/crops/pest-advisory must reject invalid tokens
        with HTTP 401 Unauthorized.
        """
        payload = {
            "crop_id": "paddy_rice",
            "latitude": 22.5726,
            "longitude": 88.3639
        }
        headers = {"Authorization": "Bearer invalid_expired_forged_token_xyz"}
        resp = client.post("/api/v1/crops/pest-advisory", json=payload, headers=headers)
        assert resp.status_code == 401, f"Expected 401 Unauthorized, got {resp.status_code}: {resp.text}"

    def test_pest_advisory_accepts_valid_authenticated_user(self, auth_headers):
        """
        F-06 Verification: POST /api/v1/crops/pest-advisory succeeds with HTTP 200
        when called with a valid user bearer token.
        """
        payload = {
            "crop_id": "paddy_rice",
            "latitude": 22.5726,
            "longitude": 88.3639
        }
        resp = client.post("/api/v1/crops/pest-advisory", json=payload, headers=auth_headers)
        assert resp.status_code == 200, f"Expected 200 OK, got {resp.status_code}: {resp.text}"
        data = resp.json()
        assert data["status"] == "success"
        assert data["crop_id"] == "paddy_rice"
        assert "advisories" in data

    # --------------------------------------------------------------------------
    # F-07: Admin Tariffs Endpoint Security Tests
    # --------------------------------------------------------------------------

    def test_admin_tariffs_get_rejects_missing_key(self):
        """
        F-07 Verification: GET /api/v1/admin/tariffs must reject unauthenticated requests
        with HTTP 403 Forbidden.
        """
        resp = client.get("/api/v1/admin/tariffs")
        assert resp.status_code == 403, f"Expected 403 Forbidden, got {resp.status_code}: {resp.text}"

    def test_admin_tariffs_get_rejects_invalid_key(self):
        """
        F-07 Verification: GET /api/v1/admin/tariffs must reject incorrect admin keys
        with HTTP 403 Forbidden.
        """
        headers = {"X-Admin-API-Key": "wrong_unauthorized_admin_key"}
        resp = client.get("/api/v1/admin/tariffs", headers=headers)
        assert resp.status_code == 403, f"Expected 403 Forbidden, got {resp.status_code}: {resp.text}"

    def test_admin_tariffs_get_accepts_valid_key(self):
        """
        F-07 Verification: GET /api/v1/admin/tariffs succeeds with HTTP 200
        when presented with the valid X-Admin-API-Key header.
        """
        headers = {"X-Admin-API-Key": settings.ADMIN_API_KEY}
        resp = client.get("/api/v1/admin/tariffs", headers=headers)
        assert resp.status_code == 200, f"Expected 200 OK, got {resp.status_code}: {resp.text}"
        data = resp.json()
        assert isinstance(data, list)
        assert len(data) >= 1

    def test_admin_tariffs_put_rejects_missing_key(self):
        """
        F-07 Verification: PUT /api/v1/admin/tariffs/{state_code} must reject requests
        lacking X-Admin-API-Key with HTTP 403 Forbidden.
        """
        payload = {
            "electric_tariff_inr_hr": 85.0
        }
        resp = client.put("/api/v1/admin/tariffs/WB", json=payload)
        assert resp.status_code == 403, f"Expected 403 Forbidden, got {resp.status_code}: {resp.text}"

    def test_admin_tariffs_put_rejects_invalid_key(self):
        """
        F-07 Verification: PUT /api/v1/admin/tariffs/{state_code} rejects incorrect keys
        with HTTP 403 Forbidden.
        """
        payload = {"electric_tariff_inr_hr": 85.0}
        headers = {"X-Admin-API-Key": "fake_admin_key"}
        resp = client.put("/api/v1/admin/tariffs/WB", json=payload, headers=headers)
        assert resp.status_code == 403, f"Expected 403 Forbidden, got {resp.status_code}: {resp.text}"

    # --------------------------------------------------------------------------
    # Batch Advisory Trigger Security Tests
    # --------------------------------------------------------------------------

    def test_trigger_batch_advisories_rejects_missing_key(self):
        """
        POST /api/v1/crops/trigger-batch-advisories must reject requests lacking X-Admin-API-Key.
        """
        resp = client.post("/api/v1/crops/trigger-batch-advisories")
        assert resp.status_code == 403, f"Expected 403 Forbidden, got {resp.status_code}: {resp.text}"

    def test_trigger_batch_advisories_rejects_invalid_key(self):
        """
        POST /api/v1/crops/trigger-batch-advisories must reject requests with wrong key.
        """
        headers = {"X-Admin-API-Key": "invalid_key"}
        resp = client.post("/api/v1/crops/trigger-batch-advisories", headers=headers)
        assert resp.status_code == 403, f"Expected 403 Forbidden, got {resp.status_code}: {resp.text}"

    # --------------------------------------------------------------------------
    # F-05: Mandatory Secret Validation Tests
    # --------------------------------------------------------------------------

    def test_admin_api_key_is_set_and_non_empty(self):
        """
        F-05 Verification: Assert ADMIN_API_KEY is configured from environment
        and is not an empty or default string.
        """
        assert bool(settings.ADMIN_API_KEY) is True
        assert len(settings.ADMIN_API_KEY) >= 16
        assert bool(settings.JWT_SECRET_KEY) is True
