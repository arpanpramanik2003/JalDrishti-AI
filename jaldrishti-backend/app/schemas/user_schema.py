from typing import Optional
from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict

# User Registration Schema
class UserRegisterRequest(BaseModel):
    username: str = Field(
        ...,
        min_length=3,
        max_length=30,
        pattern=r"^[a-zA-Z0-9_]+$",
        description="Username must contain only letters, numbers, and underscores"
    )
    phone_number: str = Field(
        ...,
        min_length=10,
        max_length=15,
        pattern=r"^\+?[0-9]{10,15}$",
        description="Valid phone number containing 10-15 digits"
    )
    password: str = Field(..., min_length=6, max_length=64)

# Flexible Login Schema (Username OR Phone Number)
class UserLoginRequest(BaseModel):
    login_identifier: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=1, max_length=64)

# Forgot Password Request OTP Schema
class ForgotPasswordRequest(BaseModel):
    phone_or_username: str = Field(..., min_length=3, max_length=50, description="Phone number or username linked to farmer account")

# Forgot Password Response Schema
class ForgotPasswordResponse(BaseModel):
    status: str
    message: str
    phone_number: str

# Reset Password with OTP Schema
class ResetPasswordRequest(BaseModel):
    phone_or_username: str = Field(..., min_length=3, max_length=50)
    otp_code: str = Field(..., min_length=6, max_length=6, pattern=r"^\d{6}$", description="6-digit verification OTP code")
    new_password: str = Field(..., min_length=6, max_length=64, description="New password")

# Request OTP for Phone Update
class RequestPhoneUpdateOtpRequest(BaseModel):
    new_phone_number: str = Field(
        ...,
        min_length=10,
        max_length=15,
        pattern=r"^\+?[0-9]{10,15}$",
        description="New phone number to verify"
    )

# Response for Phone Update OTP Request
class RequestPhoneUpdateOtpResponse(BaseModel):
    status: str
    message: str
    new_phone_number: str

# Verify OTP for Phone Update
class VerifyPhoneUpdateOtpRequest(BaseModel):
    new_phone_number: str = Field(..., min_length=10, max_length=15, pattern=r"^\+?[0-9]{10,15}$")
    otp_code: str = Field(..., min_length=6, max_length=6, pattern=r"^\d{6}$", description="6-digit OTP code")

# Farmer Profile Schema (Survey data)
class UserProfileSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    first_name: Optional[str] = Field(default="Farmer", max_length=50)
    last_name: Optional[str] = Field(default="", max_length=50)
    location_name: Optional[str] = Field(default="Kolkata, WB", max_length=100)
    latitude: Optional[float] = Field(default=22.5726, ge=-90.0, le=90.0)
    longitude: Optional[float] = Field(default=88.3639, ge=-180.0, le=180.0)
    farm_area_acres: Optional[float] = Field(default=2.5, ge=0.01, le=10000.0)
    interested_crop: Optional[str] = Field(default="paddy_rice", max_length=50)
    farming_experience: Optional[str] = Field(default="Intermediate", max_length=30)
    preferred_language: Optional[str] = Field(default="English", max_length=20)

# Response Model for User
class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    username: str
    phone_number: str
    is_active: bool
    created_at: datetime
    profile: Optional[UserProfileSchema] = None

# Token Response Model
class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserResponse

class RefreshTokenRequest(BaseModel):
    refresh_token: str = Field(..., description="Valid refresh token")
