import json
import time
import logging
from typing import Optional, Any
from app.core.config import settings

logger = logging.getLogger("jaldrishti.cache")

class CacheService:
    _redis_client = None
    _memory_cache = {}

    @classmethod
    def _get_redis(cls):
        if cls._redis_client is None and settings.REDIS_URL:
            try:
                import redis
                cls._redis_client = redis.Redis.from_url(
                    settings.REDIS_URL,
                    decode_responses=True,
                    socket_connect_timeout=3,
                    socket_timeout=3
                )
                # Ping test
                cls._redis_client.ping()
                logger.info("[CacheService] Connected to Redis Cloud successfully!")
            except Exception as e:
                logger.warning(f"[CacheService] Redis connection failed, falling back to memory cache: {e}")
                cls._redis_client = False
        return cls._redis_client if cls._redis_client else None

    @classmethod
    def get(cls, key: str) -> Optional[Any]:
        r = cls._get_redis()
        if r:
            try:
                val = r.get(key)
                if val:
                    return json.loads(val)
            except Exception as e:
                logger.warning(f"[Cache] Redis get error: {e}")

        # Fallback memory cache with TTL check
        entry = cls._memory_cache.get(key)
        if entry:
            val, expire_time = entry
            if time.time() < expire_time:
                return val
            else:
                del cls._memory_cache[key]
        return None

    @classmethod
    def set(cls, key: str, value: Any, expire_seconds: int = 10800) -> bool:
        """Sets cache key with TTL (Default: 3 hours = 10800 seconds)."""
        r = cls._get_redis()
        try:
            serialized = json.dumps(value)
            if r:
                r.setex(key, expire_seconds, serialized)
                return True
            else:
                cls._memory_cache[key] = (value, time.time() + expire_seconds)
                return True
        except Exception as e:
            logger.warning(f"[Cache] Set error: {e}")
            return False
