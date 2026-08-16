from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import inspect, text
from app.core.config import settings
from app.core.rate_limiter import RateLimiterMiddleware
from app.api.v1.endpoints import irrigation, chatbot, crop_info, auth, farm_plots
from app.db.database import engine, Base
import app.models.user # Ensure models are imported
import app.models.farm_plot # Ensure models are imported for table creation

# Create Database Tables on startup
Base.metadata.create_all(bind=engine)

# Auto-migrate new columns for SQLite database
try:
    with engine.connect() as conn:
        inspector = inspect(engine)
        if "farm_plots" in inspector.get_table_names():
            columns = [c["name"] for c in inspector.get_columns("farm_plots")]
            if "pump_hp" not in columns:
                conn.execute(text("ALTER TABLE farm_plots ADD COLUMN pump_hp FLOAT DEFAULT 5.0"))
            if "pump_flow_lps" not in columns:
                conn.execute(text("ALTER TABLE farm_plots ADD COLUMN pump_flow_lps FLOAT DEFAULT 5.0"))
            if "irrigation_method" not in columns:
                conn.execute(text("ALTER TABLE farm_plots ADD COLUMN irrigation_method VARCHAR(30) DEFAULT 'flood'"))
            if "soil_type" not in columns:
                conn.execute(text("ALTER TABLE farm_plots ADD COLUMN soil_type VARCHAR(30) DEFAULT 'clay_loam'"))
            conn.commit()
        if "users" in inspector.get_table_names():
            columns = [c["name"] for c in inspector.get_columns("users")]
            if "fcm_token" not in columns:
                conn.execute(text("ALTER TABLE users ADD COLUMN fcm_token VARCHAR(255)"))
            conn.commit()
except Exception as e:
    print(f"[Info] Migration check notice: {e}")

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# Start Automated Background Weather & Disease Scheduler (Runs every 12 hours)
try:
    from apscheduler.schedulers.asyncio import AsyncIOScheduler
    from app.services.automated_advisory_cron import run_daily_weather_and_pest_batch_job

    scheduler = AsyncIOScheduler()

    @app.on_event("startup")
    def start_automated_scheduler():
        scheduler.add_job(run_daily_weather_and_pest_batch_job, 'interval', hours=12)
        scheduler.start()
        print("[Scheduler] Automated background weather & pest monitoring scheduler active.")
except Exception as scheduler_err:
    print(f"[Scheduler Notice] {scheduler_err}")

# Multi-tier Redis-Backed Rate Limiting Middleware
app.add_middleware(RateLimiterMiddleware)

# Enable CORS with explicit allowed client origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register API routes
app.include_router(
    auth.router,
    prefix=f"{settings.API_V1_STR}/auth",
    tags=["Authentication & Profiles"]
)

app.include_router(
    farm_plots.router,
    prefix=f"{settings.API_V1_STR}/plots",
    tags=["Multi-Farm Plot Management"]
)

app.include_router(
    irrigation.router,
    prefix=f"{settings.API_V1_STR}/irrigation",
    tags=["Irrigation Engine"]
)

app.include_router(
    chatbot.router,
    prefix=f"{settings.API_V1_STR}/chatbot",
    tags=["Agri-LLM Chatbot"]
)

app.include_router(
    crop_info.router,
    prefix=f"{settings.API_V1_STR}/crops",
    tags=["Crop Management"]
)

@app.api_route("/", methods=["GET", "HEAD"], tags=["Health Check"])
def root():
    return {
        "app": settings.PROJECT_NAME,
        "status": "healthy",
        "documentation": "/docs"
    }

@app.api_route("/healthy", methods=["GET", "HEAD"], tags=["Health Check"])
@app.api_route("/health", methods=["GET", "HEAD"], tags=["Health Check"])
@app.api_route(f"{settings.API_V1_STR}/healthy", methods=["GET", "HEAD"], tags=["Health Check"])
@app.api_route(f"{settings.API_V1_STR}/health", methods=["GET", "HEAD"], tags=["Health Check"])
def health_check():
    return {
        "status": "healthy",
        "app": settings.PROJECT_NAME
    }