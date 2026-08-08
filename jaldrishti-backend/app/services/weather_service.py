import httpx
from datetime import datetime, timedelta
from app.services.cache_service import CacheService

class WeatherService:
    OPEN_METEO_URL = "https://api.open-meteo.com/v1/forecast"

    @staticmethod
    async def fetch_realtime_weather(lat: float, lon: float, past_days: int = 3, forecast_days: int = 3) -> dict:
        """
        Fetches daily meteorological data using Open-Meteo API with Redis caching and network fallback.
        Cache Key: weather:{lat_2dec}:{lon_2dec} (TTL: 3 hours)
        """
        grid_lat = round(lat, 2)
        grid_lon = round(lon, 2)
        cache_key = f"weather:{grid_lat}:{grid_lon}"

        cached_data = CacheService.get(cache_key)
        if cached_data:
            return cached_data

        params = {
            "latitude": lat,
            "longitude": lon,
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
            async with httpx.AsyncClient(timeout=20.0, follow_redirects=True) as client:
                response = await client.get(WeatherService.OPEN_METEO_URL, params=params, headers=headers)
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

                # Cache weather result for 3 hours (10800 seconds)
                CacheService.set(cache_key, result, expire_seconds=10800)
                return result

        except Exception as e:
            print(f"⚠️ Weather API network notice ({e}). Using synthetic fallback telemetry.")
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
                "source": "Fallback Weather Model",
                "latitude": lat,
                "longitude": lon,
                "elevation": 20,
                "daily_weather": fallback_daily
            }