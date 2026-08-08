import time
import httpx
import logging
from datetime import datetime, timedelta
from typing import Optional
from app.core.config import settings
from app.services.cache_service import CacheService

logger = logging.getLogger("jaldrishti.weather")


class WeatherService:
    OPEN_METEO_URL = "https://api.open-meteo.com/v1/forecast"
    WEATHER_API_URL = "https://api.weatherapi.com/v1/forecast.json"

    # Circuit breaker & Stale memory storage
    _rate_limit_backoff_until = 0
    _stale_cache = {}

    @classmethod
    async def fetch_realtime_weather(cls, lat: float, lon: float, past_days: int = 3, forecast_days: int = 3) -> dict:
        """
        Fetches daily meteorological data using Open-Meteo or WeatherAPI.com with Redis caching,
        circuit-breaker rate limit protection, and stale-while-revalidate fallback.
        """
        grid_lat = round(lat, 2)
        grid_lon = round(lon, 2)
        cache_key = f"weather:{grid_lat}:{grid_lon}"

        # 1. Check Primary Cache (Redis or TTL Memory)
        cached_data = CacheService.get(cache_key)
        if cached_data:
            return cached_data

        # 2. Check if Open-Meteo is currently in Circuit Breaker Backoff (due to 429 Rate Limit)
        now = time.time()
        if now < cls._rate_limit_backoff_until:
            stale = cls._stale_cache.get(cache_key)
            if stale:
                logger.info(f"[WeatherService] Serving stale cached weather for ({grid_lat}, {grid_lon}) during rate-limit backoff.")
                return stale
            return cls._generate_fallback_telemetry(lat, lon, past_days, forecast_days)

        # 3. If WeatherAPI key is provided, try WeatherAPI first
        if settings.WEATHER_API_KEY:
            res = await cls._fetch_from_weather_api(grid_lat, grid_lon, past_days, forecast_days)
            if res:
                CacheService.set(cache_key, res, expire_seconds=10800)
                cls._stale_cache[cache_key] = res
                return res

        # 4. Fetch from Open-Meteo
        params = {
            "latitude": grid_lat,
            "longitude": grid_lon,
            "daily": "temperature_2m_max,temperature_2m_min,relative_humidity_2m_mean,shortwave_radiation_sum,wind_speed_10m_max,precipitation_sum",
            "timezone": "auto",
            "past_days": past_days,
            "forecast_days": forecast_days
        }

        headers = {
            "User-Agent": "JalDrishti-AI/2.0 (Precision Agriculture Engine; https://jaldrishti-ai.onrender.com)",
            "Accept": "application/json"
        }

        try:
            async with httpx.AsyncClient(timeout=15.0, follow_redirects=True) as client:
                response = await client.get(cls.OPEN_METEO_URL, params=params, headers=headers)
                
                if response.status_code == 429:
                    cls._rate_limit_backoff_until = time.time() + 1800  # 30-min backoff
                    logger.warning(
                        f"[WeatherService] Open-Meteo 429 Rate Limit reached on shared IP. "
                        f"Entering 30-minute backoff circuit breaker."
                    )
                    stale = cls._stale_cache.get(cache_key)
                    if stale:
                        return stale
                    return cls._generate_fallback_telemetry(lat, lon, past_days, forecast_days)

                response.raise_for_status()
                data = response.json()

                daily = data.get("daily", {})
                dates = daily.get("time", [])

                formatted_daily = {}
                for idx, date_str in enumerate(dates):
                    formatted_daily[date_str] = {
                        "temp_max_c": daily["temperature_2m_max"][idx],
                        "temp_min_c": daily["temperature_2m_min"][idx],
                        "humidity_percent": daily["relative_humidity_2m_mean"][idx],
                        "solar_rad_mj_m2": daily["shortwave_radiation_sum"][idx],
                        "wind_speed_m_s": daily["wind_speed_10m_max"][idx] / 3.6,  # km/h to m/s
                        "precipitation_mm": daily["precipitation_sum"][idx]
                    }

                result = {
                    "source": "Open-Meteo Realtime API",
                    "latitude": lat,
                    "longitude": lon,
                    "elevation": data.get("elevation", 0),
                    "daily_weather": formatted_daily
                }

                # Save in Cache & Stale Backup
                CacheService.set(cache_key, result, expire_seconds=10800)
                cls._stale_cache[cache_key] = result
                return result

        except Exception as e:
            logger.warning(f"[WeatherService] Open-Meteo notice ({e}). Using stale cache or fallback.")
            stale = cls._stale_cache.get(cache_key)
            if stale:
                return stale
            return cls._generate_fallback_telemetry(lat, lon, past_days, forecast_days)

    @classmethod
    async def _fetch_from_weather_api(cls, lat: float, lon: float, past_days: int, forecast_days: int) -> Optional[dict]:
        try:
            params = {
                "key": settings.WEATHER_API_KEY,
                "q": f"{lat},{lon}",
                "days": past_days + forecast_days + 1,
                "aqi": "no",
                "alerts": "no"
            }
            async with httpx.AsyncClient(timeout=10.0) as client:
                resp = await client.get(cls.WEATHER_API_URL, params=params)
                if resp.status_code == 200:
                    data = resp.json()
                    formatted_daily = {}
                    forecastday = data.get("forecast", {}).get("forecastday", [])
                    for item in forecastday:
                        d_str = item.get("date")
                        day_data = item.get("day", {})
                        formatted_daily[d_str] = {
                            "temp_max_c": day_data.get("maxtemp_c", 32.0),
                            "temp_min_c": day_data.get("mintemp_c", 24.0),
                            "humidity_percent": day_data.get("avghumidity", 75.0),
                            "solar_rad_mj_m2": 21.0,
                            "wind_speed_m_s": day_data.get("maxwind_kph", 10.0) / 3.6,
                            "precipitation_mm": day_data.get("totalprecip_mm", 0.0)
                        }
                    return {
                        "source": "WeatherAPI.com Realtime API",
                        "latitude": lat,
                        "longitude": lon,
                        "elevation": 20,
                        "daily_weather": formatted_daily
                    }
        except Exception as e:
            logger.warning(f"[WeatherService] WeatherAPI.com error: {e}")
        return None

    @classmethod
    def _generate_fallback_telemetry(cls, lat: float, lon: float, past_days: int, forecast_days: int) -> dict:
        today = datetime.now()
        fallback_daily = {}
        for i in range(-past_days, forecast_days + 1):
            d_str = (today + timedelta(days=i)).strftime("%Y-%m-%d")
            fallback_daily[d_str] = {
                "temp_max_c": 32.5,
                "temp_min_c": 24.0,
                "humidity_percent": 75.0,
                "solar_rad_mj_m2": 21.0,
                "wind_speed_m_s": 2.5,
                "precipitation_mm": 0.0
            }
        return {
            "source": "Fallback Agricultural Weather Model",
            "latitude": lat,
            "longitude": lon,
            "elevation": 20,
            "daily_weather": fallback_daily
        }