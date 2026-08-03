import uuid
import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_user_registration_and_login():
    unique_str = uuid.uuid4().hex[:8]
    username = f"user_{unique_str}"
    phone_number = f"99{uuid.uuid4().int % 100000000:08d}"

    # 1. Register User
    reg_payload = {
        "username": username,
        "phone_number": phone_number,
        "password": "securepassword123"
    }
    response = client.post("/api/v1/auth/register", json=reg_payload)
    assert response.status_code == 200, f"Registration failed: {response.json()}"
    data = response.json()
    assert "access_token" in data
    assert data["user"]["username"] == username
    assert data["user"]["phone_number"] == phone_number

    token = data["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Login via Username
    login_user_resp = client.post("/api/v1/auth/login", json={
        "login_identifier": username,
        "password": "securepassword123"
    })
    assert login_user_resp.status_code == 200, f"Login by username failed: {login_user_resp.json()}"
    assert "access_token" in login_user_resp.json()

    # 3. Login via Phone Number
    login_phone_resp = client.post("/api/v1/auth/login", json={
        "login_identifier": phone_number,
        "password": "securepassword123"
    })
    assert login_phone_resp.status_code == 200, f"Login by phone failed: {login_phone_resp.json()}"
    assert "access_token" in login_phone_resp.json()

    # 4. Get Current User Profile (/me)
    me_resp = client.get("/api/v1/auth/me", headers=headers)
    assert me_resp.status_code == 200, f"Get me failed: {me_resp.json()}"
    me_data = me_resp.json()
    assert me_data["username"] == username

    # 5. Update Profile Survey Data
    update_payload = {
        "first_name": "Arpan",
        "last_name": "Pramanik",
        "location_name": "Burdwan, West Bengal",
        "latitude": 23.2324,
        "longitude": 87.8615,
        "farm_area_acres": 5.0,
        "interested_crop": "paddy_rice",
        "farming_experience": "Experienced",
        "preferred_language": "Bengali"
    }
    prof_resp = client.put("/api/v1/auth/profile", json=update_payload, headers=headers)
    assert prof_resp.status_code == 200, f"Update profile failed: {prof_resp.json()}"
    prof_data = prof_resp.json()
    assert prof_data["first_name"] == "Arpan"
    assert prof_data["farming_experience"] == "Experienced"

def test_forgot_password_otp_reset():
    unique_str = uuid.uuid4().hex[:8]
    username = f"farmer_{unique_str}"
    phone_number = f"98{uuid.uuid4().int % 100000000:08d}"

    # Register
    client.post("/api/v1/auth/register", json={
        "username": username,
        "phone_number": phone_number,
        "password": "oldpassword123"
    })

    # 1. Request OTP via Username or Phone
    req_resp = client.post("/api/v1/auth/forgot-password/request-otp", json={
        "phone_or_username": username
    })
    assert req_resp.status_code == 200, f"Request OTP failed: {req_resp.json()}"
    otp_data = req_resp.json()
    assert "otp_code_dev" in otp_data
    otp_code = otp_data["otp_code_dev"]
    assert len(otp_code) == 6

    # 2. Reset Password with OTP
    reset_resp = client.post("/api/v1/auth/forgot-password/reset-password", json={
        "phone_or_username": phone_number,
        "otp_code": otp_code,
        "new_password": "newsecurepassword99"
    })
    assert reset_resp.status_code == 200, f"Reset password failed: {reset_resp.json()}"

    # 3. Verify Login with New Password
    login_resp = client.post("/api/v1/auth/login", json={
        "login_identifier": username,
        "password": "newsecurepassword99"
    })
    assert login_resp.status_code == 200, "Login with new password failed!"
    assert "access_token" in login_resp.json()
