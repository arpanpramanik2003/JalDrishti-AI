import time
from collections import defaultdict
from fastapi import Request
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware

class RateLimiterMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, max_requests: int = 30, window_seconds: int = 60):
        super().__init__(app)
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self.request_history = defaultdict(list)

    async def dispatch(self, request: Request, call_next):
        # Rate limit only sensitive authentication endpoints
        path = request.url.path
        if path.endswith("/auth/login") or path.endswith("/auth/register"):
            client_ip = request.client.host if request.client else "127.0.0.1"
            now = time.time()
            
            # Clean history older than window
            history = [t for t in self.request_history[client_ip] if now - t < self.window_seconds]
            self.request_history[client_ip] = history

            if len(history) >= self.max_requests:
                return JSONResponse(
                    status_code=429,
                    content={"detail": "Too many authentication attempts. Please wait 1 minute before retrying."}
                )
            
            self.request_history[client_ip].append(now)

        response = await call_next(request)
        return response
