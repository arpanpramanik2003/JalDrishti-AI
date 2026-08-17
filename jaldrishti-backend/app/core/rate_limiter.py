import time
import logging
from collections import defaultdict
from fastapi import Request
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware
from app.services.cache_service import CacheService
from app.core.config import settings

logger = logging.getLogger("jaldrishti.rate_limiter")


class RateLimiterMiddleware(BaseHTTPMiddleware):
    """
    Multi-tier Distributed Rate Limiting Middleware.
    Enforces per-route quotas backed by Redis with process-memory fallback.
    """

    def __init__(self, app):
        super().__init__(app)
        self.memory_history = defaultdict(list)

    def _get_route_limit(self, path: str) -> tuple[str, int, int]:
        """
        Returns (category_name, max_requests, window_seconds) for a given endpoint path.
        """
        # Strict protection for LLM Chatbot endpoint
        if path.endswith("/chatbot/query"):
            return ("chatbot", 5, 60)

        # Auth & sensitive endpoints
        if "/auth/" in path:
            return ("auth", 10, 60)

        # External API calculation endpoints
        if "/irrigation/recommendation" in path or "/crops/pest-advisory" in path:
            return ("external_calc", 15, 60)

        # Default general API endpoints
        if path.startswith("/api/") or path.startswith("/plots"):
            return ("general_api", 60, 60)

        # Exempt health check & OpenAPI docs
        return ("exempt", 1000, 60)

    async def dispatch(self, request: Request, call_next):
        path = request.url.path
        category, max_requests, window_seconds = self._get_route_limit(path)

        if category == "exempt":
            return await call_next(request)

        client_ip = request.client.host if request.client else "127.0.0.1"
        
        # Bypass rate limits during automated unit testing
        if client_ip == "testclient" or getattr(settings, "ENVIRONMENT", "").lower() == "testing":
            return await call_next(request)

        key = f"rate_limit:{category}:{client_ip}"
        
        # 1. Try Redis Rate Limiting
        r = CacheService._get_redis()
        is_rate_limited = False

        if r:
            try:
                current_count = r.incr(key)
                if current_count == 1:
                    r.expire(key, window_seconds)
                if current_count > max_requests:
                    is_rate_limited = True
            except Exception as e:
                logger.warning(f"[RateLimiter] Redis error ({e}), resetting Redis connection pool.")
                CacheService._redis_client = None
                r = None

        # 2. Fallback to Process Memory Rate Limiting if Redis unavailable
        if not r:
            now = time.time()
            mem_key = f"{category}:{client_ip}"
            history = [t for t in self.memory_history[mem_key] if now - t < window_seconds]
            self.memory_history[mem_key] = history

            if len(history) >= max_requests:
                is_rate_limited = True
            else:
                self.memory_history[mem_key].append(now)

        if is_rate_limited:
            return JSONResponse(
                status_code=429,
                content={
                    "detail": f"Rate limit exceeded for endpoint category '{category}'. Maximum {max_requests} requests per {window_seconds} seconds allowed."
                }
            )

        response = await call_next(request)
        return response
