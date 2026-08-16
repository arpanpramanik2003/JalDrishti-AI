from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "JalDrishti AI Engine"
    API_V1_STR: str = "/api/v1"
    
    DATABASE_URL: str = "sqlite:///./jaldrishti.db"
    REDIS_URL: str = ""
    JWT_SECRET_KEY: str = "jaldrishti_saas_super_secret_jwt_key_2026_prod"
    
    NASA_POWER_BASE_URL: str = "https://power.larc.nasa.gov/api/temporal/daily/point"
    SOILGRIDS_BASE_URL: str = "https://rest.isric.org/soilgrids/v2.0/properties/query"
    
    # GROQ & Weather API Configurations
    GROQ_API_KEY: str = ""
    GROQ_MODEL_NAME: str = "llama-3.3-70b-versatile"
    WEATHER_API_KEY: str = ""
    ADMIN_API_KEY: str = "jaldrishti_admin_secret_key_2026_prod"

    class Config:
        env_file = ".env"
        extra = "ignore"

settings = Settings()