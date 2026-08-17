from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from app.core.config import settings
from app.core.rate_limiter import RateLimiterMiddleware
from app.api.v1.endpoints import irrigation, chatbot, crop_info, auth, farm_plots, admin_tariffs
from app.db.database import engine, Base
# Ensure models are imported for metadata registration
import app.models.user
import app.models.farm_plot
import app.models.regional_tariff

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# GZip Response Compression Middleware (compresses payloads >1000 bytes for low-bandwidth networks)
app.add_middleware(GZipMiddleware, minimum_size=1000)

# Multi-tier Redis-Backed Rate Limiting Middleware
app.add_middleware(RateLimiterMiddleware)

# Enable CORS with explicit allowed client origins and regex for dynamic local dev ports (Flutter Web)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?|https://.*",
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

app.include_router(
    admin_tariffs.router,
    prefix=f"{settings.API_V1_STR}/admin/tariffs",
    tags=["Regional Tariffs Policy Engine"]
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