import json
import time
import logging
from typing import Optional, Any
from app.core.config import settings

logger = logging.getLogger("jaldrishti.cache")

class CacheService:
    _async_redis_client = None
    _redis_client = None
    _memory_cache = {}

    @classmethod
    async def _get_async_redis(cls):
        """Asynchronous Redis client for non-blocking I/O in async routes."""
        if cls._async_redis_client is None:
            if settings.REDIS_URL:
                try:
                    import redis.asyncio as aioredis
                    client = aioredis.from_url(
                        settings.REDIS_URL,
                        decode_responses=True,
                        socket_connect_timeout=3,
                        socket_timeout=3
                    )
                    await client.ping()
                    cls._async_redis_client = client
                    logger.info("[CacheService] Connected to Redis Cloud (async) successfully!")
                except Exception as e:
                    logger.warning(
                        f"[CacheService WARNING] Async Redis connection to '{settings.REDIS_URL}' failed ({e}). "
                        f"Falling back to single-process IN-MEMORY cache."
                    )
                    cls._async_redis_client = False
            else:
                logger.warning(
                    "[CacheService WARNING] REDIS_URL environment variable is not configured! "
                    "Operating on single-process IN-MEMORY cache fallback."
                )
                cls._async_redis_client = False
        return cls._async_redis_client if cls._async_redis_client else None

    @classmethod
    def _get_redis(cls):
        """Synchronous Redis client retained for sync security dependencies."""
        if cls._redis_client is None:
            if settings.REDIS_URL:
                try:
                    import redis
                    client = redis.Redis.from_url(
                        settings.REDIS_URL,
                        decode_responses=True,
                        socket_connect_timeout=3,
                        socket_timeout=3
                    )
                    client.ping()
                    cls._redis_client = client
                    logger.info("[CacheService] Connected to Redis Cloud (sync) successfully!")
                except Exception as e:
                    logger.warning(
                        f"[CacheService WARNING] Sync Redis connection to '{settings.REDIS_URL}' failed ({e}). "
                        f"Falling back to single-process IN-MEMORY cache."
                    )
                    cls._redis_client = False
            else:
                cls._redis_client = False
        return cls._redis_client if cls._redis_client else None

    @classmethod
    async def get(cls, key: str) -> Optional[Any]:
        """Asynchronously retrieve and deserialize value from Redis or in-memory fallback."""
        r = await cls._get_async_redis()
        if r:
            try:
                val = await r.get(key)
                if val:
                    return json.loads(val)
            except Exception as e:
                logger.warning(f"[CacheService] Async Redis GET error for '{key}' ({e}). Resetting Redis pool.")
                cls._async_redis_client = None

        # In-memory fallback
        item = cls._memory_cache.get(key)
        if item:
            val, exp = item
            if exp is None or time.time() < exp:
                return val
            else:
                del cls._memory_cache[key]
        return None

    @classmethod
    async def set(cls, key: str, value: Any, expire_seconds: int = 10800) -> bool:
        """Asynchronously sets cache key with TTL (Default: 3 hours = 10800 seconds)."""
        r = await cls._get_async_redis()
        try:
            serialized = json.dumps(value)
            if r:
                await r.set(key, serialized, ex=expire_seconds)
                return True
            else:
                cls._memory_cache[key] = (value, time.time() + expire_seconds)
                return True
        except Exception as e:
            logger.warning(f"[Cache] Async Set error: {e}")
            return False

    @classmethod
    async def delete(cls, key: str) -> bool:
        """Asynchronously deletes cache key."""
        r = await cls._get_async_redis()
        try:
            if r:
                await r.delete(key)
            cls._memory_cache.pop(key, None)
            return True
        except Exception as e:
            logger.warning(f"[Cache] Async Delete error: {e}")
            return False

    @classmethod
    def get_sync(cls, key: str) -> Optional[Any]:
        """Synchronous retrieval helper for legacy non-async services."""
        r = cls._get_redis()
        if r:
            try:
                val = r.get(key)
                if val:
                    return json.loads(val)
            except Exception as e:
                logger.warning(f"[CacheService] Sync Redis GET error for '{key}' ({e}).")
                cls._redis_client = None

        item = cls._memory_cache.get(key)
        if item:
            val, exp = item
            if exp is None or time.time() < exp:
                return val
            else:
                del cls._memory_cache[key]
        return None

    @classmethod
    def set_sync(cls, key: str, value: Any, expire_seconds: int = 10800) -> bool:
        """Synchronous set helper for legacy non-async services."""
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
            logger.warning(f"[Cache] Sync Set error: {e}")
            return False
