# API Reference: Authentication & User Profile Endpoints

> **Audience**: Mobile app developers and backend integrators.  
> **Source Controller**: [`app/api/v1/endpoints/auth.py`](file:///d:/jaldrishti/jaldrishti-backend/app/api/v1/endpoints/auth.py)  
> **Schemas**: [`app/schemas/user_schema.py`](file:///d:/jaldrishti/jaldrishti-backend/app/schemas/user_schema.py)  
> **Security Dependency**: [`app/core/security.py`](file:///d:/jaldrishti/jaldrishti-backend/app/core/security.py)

---

## 1. `POST /api/v1/auth/register`
Creates a new farmer account and initializes an empty associated profile.

- **Authentication**: None (Public)
- **Request Body** (`UserRegister`):
  ```json
  {
    "username": "ramesh_patel",
    "phone_number": "+919876543210",
    "password": "SecurePassword123"
  }
  ```
- **Response** (`201 Created` - `TokenResponse`):
  ```json
  {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "token_type": "bearer",
    "user": {
      "id": 42,
      "username": "ramesh_patel",
      "phone_number": "+919876543210",
      "is_active": true
    }
  }
  ```

---

## 2. `POST /api/v1/auth/login`
Authenticates farmer credentials using phone number or username and issues JWT access and refresh tokens.

- **Authentication**: None (Public)
- **Request Body** (`UserLogin`):
  ```json
  {
    "phone_or_username": "+919876543210",
    "password": "SecurePassword123"
  }
  ```
- **Response** (`200 OK` - `TokenResponse`): Same structure as `/register`. Returns access token (24h validity) and refresh token (30d validity).

---

## 3. `POST /api/v1/auth/refresh`
Rotates and issues a new access token using a valid refresh token.

- **Authentication**: None (Requires valid refresh token in payload)
- **Request Body** (`TokenRefreshRequest`):
  ```json
  {
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
  ```
- **Response** (`200 OK`):
  ```json
  {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "token_type": "bearer"
  }
  ```
- **Error Codes**: `401 Unauthorized` if refresh token is expired, invalid, or blacklisted in Redis.

---

## 4. `POST /api/v1/auth/logout`
Revokes the current JWT session by blacklisting the token's unique identifier (`jti`) in Redis until its natural expiration.

- **Authentication**: `Bearer <access_token>` (`get_current_user`)
- **Request Body**: None
- **Response** (`200 OK`):
  ```json
  {
    "message": "Successfully logged out. Token revoked."
  }
  ```

---

## 5. `POST /api/v1/auth/forgot-password/request-otp`
Dispatches a 6-digit one-time password (OTP) to the farmer's registered phone number via Fast2SMS/Twilio.

- **Authentication**: None (Public)
- **Request Body** (`PasswordResetRequest`):
  ```json
  {
    "phone_or_username": "+919876543210"
  }
  ```
  *(Note: Phase 3 [F-04] fixed the mobile client to send `phone_or_username` matching this schema).*
- **Response** (`200 OK`):
  ```json
  {
    "message": "OTP sent to registered mobile number"
  }
  ```

---

## 6. `POST /api/v1/auth/forgot-password/reset-password`
Validates the SMS OTP and updates the account password.

- **Authentication**: None (Public, secured via single-use OTP)
- **Request Body** (`PasswordResetConfirm`):
  ```json
  {
    "phone_or_username": "+919876543210",
    "otp_code": "482910",
    "new_password": "NewSecurePassword456"
  }
  ```
- **Response** (`200 OK`):
  ```json
  {
    "message": "Password reset successfully. You may now log in."
  }
  ```

---

## 7. `GET /api/v1/auth/me`
Fetches account details, active subscription status, and full profile attributes for the logged-in user.

- **Authentication**: `Bearer <access_token>` (`get_current_user`)
- **Response** (`200 OK` - `UserResponse`):
  ```json
  {
    "id": 42,
    "username": "ramesh_patel",
    "phone_number": "+919876543210",
    "is_active": true,
    "profile": {
      "first_name": "Ramesh",
      "last_name": "Patel",
      "location_name": "Burdwan, West Bengal",
      "latitude": 23.2324,
      "longitude": 87.8615,
      "farm_area_acres": 3.5,
      "interested_crop": "paddy_rice",
      "farming_experience": "Intermediate",
      "preferred_language": "Bengali"
    }
  }
  ```

---

## 8. `PUT /api/v1/auth/profile`
Updates farmer profile metadata and regional defaults.

> [!IMPORTANT]
> **HTTP Method Contract (Phase 3 Fix [F-03])**: The backend exclusively accepts HTTP `PUT` for profile updates. The mobile app previously sent `POST`, which resulted in `HTTP 405 Method Not Allowed`. This was synchronized in Phase 3.

- **Authentication**: `Bearer <access_token>` (`get_current_user`)
- **Request Body** (`UserProfileUpdate`):
  ```json
  {
    "first_name": "Ramesh",
    "last_name": "Patel",
    "location_name": "Burdwan, West Bengal",
    "latitude": 23.2324,
    "longitude": 87.8615,
    "farm_area_acres": 3.5,
    "interested_crop": "paddy_rice",
    "farming_experience": "Intermediate",
    "preferred_language": "Bengali"
  }
  ```
- **Response** (`200 OK` - `UserProfileResponse`): Returns the complete updated profile object.

---

## 9. `POST /api/v1/auth/request-phone-update-otp`
Initiates a phone number change by dispatching an OTP to the proposed new mobile number.

- **Authentication**: `Bearer <access_token>` (`get_current_user`)
- **Request Body**:
  ```json
  {
    "new_phone_number": "+919123456780"
  }
  ```
- **Response** (`200 OK`):
  ```json
  {
    "message": "OTP dispatched to proposed phone number"
  }
  ```

---

## 10. `POST /api/v1/auth/verify-phone-update-otp`
Confirms the OTP and updates the user's primary login phone number.

- **Authentication**: `Bearer <access_token>` (`get_current_user`)
- **Request Body**:
  ```json
  {
    "new_phone_number": "+919123456780",
    "otp_code": "819204"
  }
  ```
- **Response** (`200 OK`):
  ```json
  {
    "message": "Phone number updated successfully"
  }
  ```

---

## 11. `POST /api/v1/auth/update-fcm-token`
Registers or updates the mobile device's Firebase Cloud Messaging token for push notifications.

- **Authentication**: `Bearer <access_token>` (`get_current_user`)
- **Request Body**:
  ```json
  {
    "fcm_token": "dK4jF8sL9pQ:APA91bH..."
  }
  ```
- **Response** (`200 OK`):
  ```json
  {
    "message": "FCM token updated successfully"
  }
  ```
