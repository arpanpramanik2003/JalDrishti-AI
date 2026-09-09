import sys
import os
import uuid
import pytest

# Ensure backend root is in Python path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from fastapi.testclient import TestClient
from app.main import app
from app.db.database import SessionLocal
from app.models.user import PasswordReset

client = TestClient(app)

def test_profile_update_contract_f03():
    """
    Validates [F-03]: Profile update contract.
    - POST /api/v1/auth/profile must return 405 Method Not Allowed (confirming mobile bug).
    - PUT /api/v1/auth/profile must return 200 OK with UserProfileSchema payload.
    """
    unique_str = uuid.uuid4().hex[:8]
    username = f"farmer_{unique_str}"
    phone_number = f"91{uuid.uuid4().int % 100000000:08d}"

    # Register
    reg_resp = client.post("/api/v1/auth/register", json={
        "username": username,
        "phone_number": phone_number,
        "password": "password123"
    })
    assert reg_resp.status_code == 200
    token = reg_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    survey_payload = {
        "first_name": "Ramesh",
        "last_name": "Kumar",
        "location_name": "Bardhaman",
        "latitude": 23.23,
        "longitude": 87.86,
        "farm_area_acres": 3.5,
        "interested_crop": "paddy_rice",
        "farming_experience": "Experienced",
        "preferred_language": "Hindi"
    }

    # Verify POST returns 405 Method Not Allowed
    post_resp = client.post("/api/v1/auth/profile", json=survey_payload, headers=headers)
    assert post_resp.status_code == 405, f"Expected 405 for POST /auth/profile, got {post_resp.status_code}"

    # Verify PUT returns 200 OK (the corrected mobile contract)
    put_resp = client.put("/api/v1/auth/profile", json=survey_payload, headers=headers)
    assert put_resp.status_code == 200, f"Expected 200 for PUT /auth/profile, got {put_resp.status_code}: {put_resp.text}"
    profile_data = put_resp.json()
    assert profile_data["first_name"] == "Ramesh"
    assert profile_data["last_name"] == "Kumar"
    assert profile_data["location_name"] == "Bardhaman"
    assert profile_data["farm_area_acres"] == 3.5
    assert profile_data["farming_experience"] == "Experienced"

def test_password_reset_contract_f04():
    """
    Validates [F-04]: Password reset payload contract.
    - Sending 'phone_number' returns 422 Unprocessable Entity (confirming old mobile mismatch).
    - Sending 'phone_or_username' returns 200 OK (confirming corrected mobile contract).
    """
    unique_str = uuid.uuid4().hex[:8]
    username = f"user_{unique_str}"
    phone_number = f"92{uuid.uuid4().int % 100000000:08d}"

    # Register
    reg_resp = client.post("/api/v1/auth/register", json={
        "username": username,
        "phone_number": phone_number,
        "password": "initial_password_123"
    })
    assert reg_resp.status_code == 200

    # 1. Negative test: Old mobile sent 'phone_number' to request-otp -> 422
    neg_otp_resp = client.post("/api/v1/auth/forgot-password/request-otp", json={
        "phone_number": phone_number
    })
    assert neg_otp_resp.status_code == 422, f"Expected 422 for phone_number key, got {neg_otp_resp.status_code}"

    # 2. Positive test: Corrected mobile sends 'phone_or_username' -> 200
    pos_otp_resp = client.post("/api/v1/auth/forgot-password/request-otp", json={
        "phone_or_username": phone_number
    })
    assert pos_otp_resp.status_code == 200, f"Expected 200 for phone_or_username, got {pos_otp_resp.status_code}: {pos_otp_resp.text}"

    # Retrieve OTP code from DB
    db = SessionLocal()
    reset_rec = db.query(PasswordReset).filter_by(phone_number=phone_number).order_by(PasswordReset.id.desc()).first()
    assert reset_rec is not None
    otp_code = reset_rec.otp_code
    db.close()

    # 3. Negative test: Old mobile sent 'phone_number' to reset-password -> 422
    neg_reset_resp = client.post("/api/v1/auth/forgot-password/reset-password", json={
        "phone_number": phone_number,
        "otp_code": otp_code,
        "new_password": "new_secure_password_456"
    })
    assert neg_reset_resp.status_code == 422, f"Expected 422 for phone_number in reset-password, got {neg_reset_resp.status_code}"

    # 4. Positive test: Corrected mobile sends 'phone_or_username' to reset-password -> 200
    pos_reset_resp = client.post("/api/v1/auth/forgot-password/reset-password", json={
        "phone_or_username": phone_number,
        "otp_code": otp_code,
        "new_password": "new_secure_password_456"
    })
    assert pos_reset_resp.status_code == 200, f"Expected 200 for reset-password, got {pos_reset_resp.status_code}: {pos_reset_resp.text}"

    # 5. Verify login succeeds with new password
    login_resp = client.post("/api/v1/auth/login", json={
        "login_identifier": username,
        "password": "new_secure_password_456"
    })
    assert login_resp.status_code == 200
    assert "access_token" in login_resp.json()

def test_token_expiry_and_refresh_flow_f20():
    """
    Validates [F-20]: Token expiry and silent refresh contract.
    - Invalid/expired access token receives HTTP 401.
    - Valid refresh token to /api/v1/auth/refresh returns new access and refresh tokens.
    - Protected endpoints accept the newly refreshed access token.
    """
    unique_str = uuid.uuid4().hex[:8]
    username = f"refresh_{unique_str}"
    phone_number = f"93{uuid.uuid4().int % 100000000:08d}"

    # Register
    reg_resp = client.post("/api/v1/auth/register", json={
        "username": username,
        "phone_number": phone_number,
        "password": "password123"
    })
    assert reg_resp.status_code == 200
    reg_data = reg_resp.json()
    refresh_token = reg_data["refresh_token"]

    # 1. Sending an invalid/expired Bearer token must trigger 401
    bad_resp = client.get("/api/v1/auth/me", headers={"Authorization": "Bearer invalid_expired_jwt_token"})
    assert bad_resp.status_code == 401

    # 2. Silent refresh request to /api/v1/auth/refresh
    refresh_resp = client.post("/api/v1/auth/refresh", json={
        "refresh_token": refresh_token
    })
    assert refresh_resp.status_code == 200, f"Refresh failed: {refresh_resp.text}"
    new_data = refresh_resp.json()
    assert "access_token" in new_data
    assert "refresh_token" in new_data
    new_access_token = new_data["access_token"]

    # 3. Retry protected endpoint with new access token
    retry_resp = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {new_access_token}"})
    assert retry_resp.status_code == 200
    assert retry_resp.json()["username"] == username
