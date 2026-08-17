from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "JalDrishti AI Engine"
    API_V1_STR: str = "/api/v1"
    
    DATABASE_URL: str = "sqlite:///./jaldrishti.db"
    REDIS_URL: str = ""
    JWT_SECRET_KEY: str = ""
    
    ALLOWED_ORIGINS: list[str] = [
        "http://localhost:3000",
        "http://localhost:8080",
        "http://127.0.0.1:3000",
        "http://localhost:5000",
        "https://jaldrishti-ai.onrender.com",
        "app://jaldrishti"
    ]
    
    NASA_POWER_BASE_URL: str = "https://power.larc.nasa.gov/api/temporal/daily/point"
    SOILGRIDS_BASE_URL: str = "https://rest.isric.org/soilgrids/v2.0/properties/query"
    
    # Environment & Logging Configuration
    ENVIRONMENT: str = "development"
    ENABLE_DEV_OTP_LOGS: bool = True

    # GROQ & Weather API Configurations
    GROQ_API_KEY: str = ""
    GROQ_MODEL_NAME: str = "openai/gpt-oss-120b"
    WEATHER_API_KEY: str = ""
    ADMIN_API_KEY: str = "jaldrishti_admin_secret_key_2026_prod"

    # Production SMS Gateway Configurations (Fast2SMS & Twilio)
    FAST2SMS_API_KEY: str = ""
    TWILIO_ACCOUNT_SID: str = ""
    TWILIO_AUTH_TOKEN: str = ""
    TWILIO_PHONE_NUMBER: str = ""

    class Config:
        env_file = ".env"
        extra = "ignore"

settings = Settings()