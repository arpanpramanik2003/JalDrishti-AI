import secrets
import logging
import httpx
from typing import Optional
from app.core.config import settings

logger = logging.getLogger("jaldrishti.sms")


class SMSService:
    FAST2SMS_URL = "https://www.fast2sms.com/dev/bulkV2"

    @staticmethod
    def generate_otp() -> str:
        """
        Generates a cryptographically secure 6-digit numeric OTP.
        """
        return str(secrets.randbelow(900000) + 100000)

    @classmethod
    def send_otp_sms(cls, phone_number: str, otp_code: str) -> bool:
        """
        Dispatches SMS OTP to farmer phone number via Fast2SMS or Twilio gateway.
        Strictly enforces zero OTP logging in production/staging environments.
        Returns True if delivered/accepted by gateway, False if failed.
        """
        # 1. Sanitize Phone Number
        raw_digits = "".join(filter(str.isdigit, str(phone_number)))
        # For Indian numbers, extract last 10 digits
        clean_10_digit = raw_digits[-10:] if len(raw_digits) >= 10 else raw_digits
        full_e164 = f"+91{clean_10_digit}" if len(clean_10_digit) == 10 else f"+{raw_digits}"
        masked_phone = f"{full_e164[:3]} ****** {full_e164[-4:]}" if len(full_e164) >= 8 else full_e164

        is_dev_env = settings.ENVIRONMENT.lower() in ["development", "dev", "local", "testing"] or settings.ENABLE_DEV_OTP_LOGS

        # 2. Development Logging (ONLY when in explicit dev environment)
        if is_dev_env:
            logger.info(
                f"\n=======================================================\n"
                f"[SMS DEV DISPATCHER] -> TO: {phone_number}\n"
                f"[OTP CODE]: {otp_code}\n"
                f"=======================================================\n"
            )
        else:
            logger.info(f"[SMS Dispatcher] Initiating secure SMS OTP dispatch to {masked_phone}...")

        # 3. Provider Priority 1: Fast2SMS (Preferred for Indian Mobile Carriers)
        if settings.FAST2SMS_API_KEY:
            return cls._send_via_fast2sms(clean_10_digit, otp_code, masked_phone)

        # 4. Provider Priority 2: Twilio (Global Fallback)
        if settings.TWILIO_ACCOUNT_SID and settings.TWILIO_AUTH_TOKEN:
            return cls._send_via_twilio(full_e164, otp_code, masked_phone)

        # 5. Local Development Fallback
        if is_dev_env:
            logger.warning(
                f"[SMS Dispatcher] No production SMS API key configured. "
                f"Operating in Development Mode for {masked_phone}."
            )
            return True

        # 6. Production Misconfiguration Safety Catch
        logger.error(
            f"[SMS Error] Production environment misconfiguration: "
            f"No SMS gateway API keys (FAST2SMS_API_KEY or TWILIO_ACCOUNT_SID) configured!"
        )
        return False

    @classmethod
    def _send_via_fast2sms(cls, clean_phone_10_digit: str, otp_code: str, masked_phone: str) -> bool:
        """
        Dispatches OTP via Fast2SMS DLT-compliant Quick OTP API.
        """
        headers = {
            "authorization": settings.FAST2SMS_API_KEY,
            "Content-Type": "application/json"
        }
        payload = {
            "route": "otp",
            "variables_values": otp_code,
            "numbers": clean_phone_10_digit
        }

        try:
            with httpx.Client(timeout=10.0) as client:
                response = client.post(cls.FAST2SMS_URL, json=payload, headers=headers)
                
                if response.status_code == 200:
                    data = response.json()
                    if data.get("return") is True:
                        request_id = data.get("request_id", "N/A")
                        logger.info(f"[SMS Dispatcher] Fast2SMS OTP sent successfully to {masked_phone}! Request ID: {request_id}")
                        return True
                    else:
                        err_msg = data.get("message", ["Unknown Fast2SMS Error"])
                        logger.error(f"[SMS Error] Fast2SMS delivery rejection for {masked_phone}: {err_msg}")
                        return False
                else:
                    logger.error(f"[SMS Error] Fast2SMS HTTP {response.status_code} failure for {masked_phone}: {response.text}")
                    return False

        except Exception as e:
            logger.error(f"[SMS Exception] Fast2SMS dispatch exception for {masked_phone}: {e}")
            return False

    @classmethod
    def _send_via_twilio(cls, e164_phone: str, otp_code: str, masked_phone: str) -> bool:
        """
        Dispatches OTP via Twilio REST API.
        """
        sms_body = f"Your JalDrishti verification OTP code is: {otp_code}. Valid for 10 minutes. Do not share with anyone."
        twilio_url = f"https://api.twilio.com/2008-04-01/Accounts/{settings.TWILIO_ACCOUNT_SID}/Messages.json"
        
        payload = {
            "To": e164_phone,
            "From": settings.TWILIO_PHONE_NUMBER,
            "Body": sms_body
        }

        try:
            with httpx.Client(timeout=10.0) as client:
                response = client.post(
                    twilio_url,
                    data=payload,
                    auth=(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
                )

                if response.status_code in [200, 201]:
                    data = response.json()
                    sid = data.get("sid", "N/A")
                    logger.info(f"[SMS Dispatcher] Twilio OTP sent successfully to {masked_phone}! Message SID: {sid}")
                    return True
                else:
                    logger.error(f"[SMS Error] Twilio HTTP {response.status_code} failure for {masked_phone}: {response.text}")
                    return False

        except Exception as e:
            logger.error(f"[SMS Exception] Twilio dispatch exception for {masked_phone}: {e}")
            return False
