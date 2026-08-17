from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session
from sqlalchemy import or_
from app.db.database import get_db
from app.models.user import User, UserProfile, PasswordReset
from app.schemas.user_schema import (
    UserRegisterRequest, UserLoginRequest, UserResponse,
    TokenResponse, UserProfileSchema, ForgotPasswordRequest,
    ForgotPasswordResponse, ResetPasswordRequest,
    RequestPhoneUpdateOtpRequest, RequestPhoneUpdateOtpResponse,
    VerifyPhoneUpdateOtpRequest, RefreshTokenRequest
)
from app.core.security import (
    get_password_hash, verify_password, create_access_token,
    create_refresh_token, decode_token, revoke_token,
    get_current_user, security_scheme, HTTPAuthorizationCredentials
)
from app.services.sms_service import SMSService
from app.services.cache_service import CacheService

router = APIRouter()

@router.post("/register", response_model=TokenResponse)
def register_user(payload: UserRegisterRequest, db: Session = Depends(get_db)):
    # Check if username or phone_number already exists
    existing_user = db.query(User).filter(
        or_(User.username == payload.username, User.phone_number == payload.phone_number)
    ).first()

    if existing_user:
        if existing_user.username == payload.username:
            raise HTTPException(status_code=400, detail="Username is already taken.")
        if existing_user.phone_number == payload.phone_number:
            raise HTTPException(status_code=400, detail="Phone number is already registered.")

    # Create User
    new_user = User(
        username=payload.username.strip(),
        phone_number=payload.phone_number.strip(),
        hashed_password=get_password_hash(payload.password)
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    # Create Default Profile
    new_profile = UserProfile(
        user_id=new_user.id,
        first_name=payload.username.capitalize(),
        last_name="",
        location_name="Kolkata, WB",
        farm_area_acres=2.5,
        interested_crop="paddy_rice",
        farming_experience="Intermediate",
        preferred_language="English"
    )
    db.add(new_profile)
    db.commit()
    db.refresh(new_user)

    # Generate JWT Access & Refresh Token Pair
    access_token = create_access_token(data={"sub": new_user.id})
    refresh_token = create_refresh_token(user_id=new_user.id)

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        user=new_user
    )


@router.post("/login", response_model=TokenResponse)
def login_user(payload: UserLoginRequest, db: Session = Depends(get_db)):
    identifier = payload.login_identifier.strip()
    
    # Query user by username OR phone_number
    user = db.query(User).filter(
        or_(User.username == identifier, User.phone_number == identifier)
    ).first()

    if not user or not verify_password(payload.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid username/phone number or password"
        )

    access_token = create_access_token(data={"sub": user.id})
    refresh_token = create_refresh_token(user_id=user.id)

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        user=user
    )


@router.post("/refresh", response_model=TokenResponse)
def refresh_access_token(payload: RefreshTokenRequest, db: Session = Depends(get_db)):
    decoded = decode_token(payload.refresh_token)
    if decoded.get("token_type") != "refresh":
        raise HTTPException(status_code=401, detail="Invalid token type: Refresh token required")
    
    # Check Redis revocation
    jti = decoded.get("jti")
    if jti:
        r = CacheService._get_redis()
        if r and r.get(f"token_blacklist:{jti}"):
            raise HTTPException(status_code=401, detail="Refresh token has been revoked. Please log in again.")
    
    user_id = int(decoded.get("sub"))
    user = db.query(User).filter(User.id == user_id).first()
    if not user or not user.is_active:
        raise HTTPException(status_code=401, detail="User not found or inactive")
    
    # Revoke old refresh token & issue new token pair
    revoke_token(payload.refresh_token)
    new_access = create_access_token(data={"sub": user.id})
    new_refresh = create_refresh_token(user_id=user.id)
    
    return TokenResponse(
        access_token=new_access,
        refresh_token=new_refresh,
        token_type="bearer",
        user=user
    )


@router.post("/logout")
def logout_user(
    credentials: HTTPAuthorizationCredentials = Depends(security_scheme),
    current_user: User = Depends(get_current_user)
):
    revoke_token(credentials.credentials)
    return {"status": "success", "message": "Successfully logged out and token revoked."}


@router.post("/forgot-password/request-otp", response_model=ForgotPasswordResponse)
def request_password_reset_otp(payload: ForgotPasswordRequest, db: Session = Depends(get_db)):
    identifier = payload.phone_or_username.strip()
    
    # Lookup user by username or phone number
    user = db.query(User).filter(
        or_(User.username == identifier, User.phone_number == identifier)
    ).first()

    if not user:
        raise HTTPException(
            status_code=404,
            detail="No registered farmer account found with this username or phone number."
        )

    # Generate 6-digit OTP
    otp = SMSService.generate_otp()
    expires_at = datetime.utcnow() + timedelta(minutes=10)

    # Save OTP to database
    reset_record = PasswordReset(
        phone_number=user.phone_number,
        otp_code=otp,
        expires_at=expires_at,
        is_used=False
    )
    db.add(reset_record)
    db.commit()

    # Dispatch SMS OTP
    sent = SMSService.send_otp_sms(user.phone_number, otp)
    if not sent:
        raise HTTPException(
            status_code=500,
            detail="Unable to send verification code, please try again."
        )

    # Obfuscate phone number for security response (e.g. +91 ****** 4321)
    phone = user.phone_number
    masked_phone = phone[:3] + "******" + phone[-4:] if len(phone) >= 8 else phone

    return ForgotPasswordResponse(
        status="success",
        message=f"OTP verification code sent to registered phone number ({masked_phone}).",
        phone_number=user.phone_number
    )


@router.post("/forgot-password/reset-password")
def reset_password_with_otp(payload: ResetPasswordRequest, db: Session = Depends(get_db)):
    identifier = payload.phone_or_username.strip()

    # Lookup user
    user = db.query(User).filter(
        or_(User.username == identifier, User.phone_number == identifier)
    ).first()

    if not user:
        raise HTTPException(status_code=404, detail="User account not found.")

    # Find valid unexpired OTP record
    now = datetime.utcnow()
    reset_record = db.query(PasswordReset).filter(
        PasswordReset.phone_number == user.phone_number,
        PasswordReset.otp_code == payload.otp_code.strip(),
        PasswordReset.is_used == False,
        PasswordReset.expires_at > now
    ).order_by(PasswordReset.id.desc()).first()

    if not reset_record:
        raise HTTPException(
            status_code=400,
            detail="Invalid or expired OTP verification code. Please request a new OTP."
        )

    # Mark OTP as used
    reset_record.is_used = True

    # Update password using direct bcrypt hash
    user.hashed_password = get_password_hash(payload.new_password)
    user.updated_at = now
    db.commit()

    return {
        "status": "success",
        "message": "Password reset successfully! You can now log in with your new password."
    }


@router.get("/me", response_model=UserResponse)
def get_current_user_profile(current_user: User = Depends(get_current_user)):
    return current_user


@router.put("/profile", response_model=UserProfileSchema)
def update_user_profile(
    profile_data: UserProfileSchema,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    profile = current_user.profile
    if not profile:
        profile = UserProfile(user_id=current_user.id)
        db.add(profile)

    profile.first_name = profile_data.first_name
    profile.last_name = profile_data.last_name
    profile.location_name = profile_data.location_name
    profile.latitude = profile_data.latitude
    profile.longitude = profile_data.longitude
    profile.farm_area_acres = profile_data.farm_area_acres
    profile.interested_crop = profile_data.interested_crop
    profile.farming_experience = profile_data.farming_experience
    profile.preferred_language = profile_data.preferred_language

    db.commit()
    db.refresh(profile)
    return profile


@router.post("/request-phone-update-otp", response_model=RequestPhoneUpdateOtpResponse)
def request_phone_update_otp(
    payload: RequestPhoneUpdateOtpRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    new_phone = payload.new_phone_number.strip()

    if new_phone == current_user.phone_number:
        raise HTTPException(
            status_code=400,
            detail="The new phone number is identical to your current phone number."
        )

    # Check if new phone is registered to another user
    existing_user = db.query(User).filter(User.phone_number == new_phone).first()
    if existing_user:
        raise HTTPException(
            status_code=400,
            detail="This phone number is already registered to another account."
        )

    # Generate 6-digit OTP code
    otp = SMSService.generate_otp()
    expires_at = datetime.utcnow() + timedelta(minutes=10)

    # Store OTP record
    reset_record = PasswordReset(
        phone_number=new_phone,
        otp_code=otp,
        expires_at=expires_at,
        is_used=False
    )
    db.add(reset_record)
    db.commit()

    # Dispatch SMS OTP
    sent = SMSService.send_otp_sms(new_phone, otp)
    if not sent:
        raise HTTPException(
            status_code=500,
            detail="Unable to send verification code, please try again."
        )

    masked_phone = new_phone[:3] + "******" + new_phone[-4:] if len(new_phone) >= 8 else new_phone

    return RequestPhoneUpdateOtpResponse(
        status="success",
        message=f"OTP verification code sent to new phone number ({masked_phone}).",
        new_phone_number=new_phone
    )


@router.post("/verify-phone-update-otp", response_model=UserResponse)
def verify_phone_update_otp(
    payload: VerifyPhoneUpdateOtpRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    new_phone = payload.new_phone_number.strip()
    otp_code = payload.otp_code.strip()

    # Find valid unexpired OTP record for new_phone
    now = datetime.utcnow()
    otp_record = db.query(PasswordReset).filter(
        PasswordReset.phone_number == new_phone,
        PasswordReset.otp_code == otp_code,
        PasswordReset.is_used == False,
        PasswordReset.expires_at > now
    ).order_by(PasswordReset.id.desc()).first()

    if not otp_record:
        raise HTTPException(
            status_code=400,
            detail="Invalid or expired OTP verification code. Please request a new OTP."
        )

    # Mark OTP as used
    otp_record.is_used = True

    # Update phone number
    current_user.phone_number = new_phone
    current_user.updated_at = now
    db.commit()
    db.refresh(current_user)

    return current_user


class FcmTokenUpdateRequest(BaseModel):
    fcm_token: str = Field(..., description="Device Firebase Push Token")


@router.post("/update-fcm-token")
def update_user_fcm_token(
    payload: FcmTokenUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Registers or updates the farmer's mobile FCM push notification token.
    """
    current_user.fcm_token = payload.fcm_token.strip()
    db.commit()
    db.refresh(current_user)
    return {"status": "success", "message": "FCM device token registered successfully."}
