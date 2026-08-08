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
except Exception as e:
    print(f"[Info] Migration check notice: {e}")

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# Rate Limiting Middleware (10 requests per minute on login/register to prevent brute force)
app.add_middleware(RateLimiterMiddleware, max_requests=10, window_seconds=60)

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
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

@app.get("/")
def root():
    return {
        "app": settings.PROJECT_NAME,
        "status": "healthy",
        "documentation": "/docs"
    }

@app.get("/healthy", tags=["Health Check"])
@app.get("/health", tags=["Health Check"])
@app.get(f"{settings.API_V1_STR}/healthy", tags=["Health Check"])
@app.get(f"{settings.API_V1_STR}/health", tags=["Health Check"])
def health_check():
    return {
        "status": "healthy",
        "app": settings.PROJECT_NAME
    }