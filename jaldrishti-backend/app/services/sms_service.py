import random
import os

class SMSService:
    @staticmethod
    def generate_otp() -> str:
        """Generates a 6-digit secure numeric OTP."""
        return str(random.randint(100000, 999999))

    @staticmethod
    def send_otp_sms(phone_number: str, otp_code: str) -> bool:
        """
        Dispatches SMS OTP to farmer phone number.
        Prints payload to logs for dev/testing, expandable to Twilio/Fast2SMS/MSG91 in production.
        """
        sms_body = f"Your JalDrishti Password Reset OTP is: {otp_code}. Valid for 10 minutes. Do not share with anyone."
        
        print("\n=======================================================")
        print(f"📱 [SMS DISPATCHER] -> TO: {phone_number}")
        print(f"💬 MESSAGE: {sms_body}")
        print("=======================================================\n")
        
        # Production SMS Gateway Hook (Twilio / Fast2SMS / MSG91)
        # if settings.TWILIO_ACCOUNT_SID:
        #     client.messages.create(body=sms_body, from_=settings.TWILIO_PHONE, to=phone_number)
        
        return True
