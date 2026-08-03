import httpx
from datetime import datetime
from app.services.cache_service import CacheService

class WeatherService:
    OPEN_METEO_URL = "https://api.open-meteo.com/v1/forecast"

    @staticmethod
    async def fetch_realtime_weather(lat: float, lon: float, past_days: int = 3, forecast_days: int = 3) -> dict:
        """
        Fetches daily meteorological data using Open-Meteo API with Redis caching.
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
            "daily": [
                "temperature_2m_max",
                "temperature_2m_min",
                "relative_humidity_2m_mean",
                "shortwave_radiation_sum",
                "wind_speed_10m_max",
                "precipitation_sum"
            ],
            "timezone": "auto",
            "past_days": past_days,
            "forecast_days": forecast_days
        }

        async with httpx.AsyncClient(timeout=15.0) as client:
            response = await client.get(WeatherService.OPEN_METEO_URL, params=params)
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