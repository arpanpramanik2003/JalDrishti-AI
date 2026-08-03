import httpx
from app.core.config import settings

class NASAPowerService:
    @staticmethod
    async def fetch_historical_weather(lat: float, lon: float, start_date: str = "20240101", end_date: str = "20240107") -> dict:
        """
        Fetches historical baseline weather from NASA POWER archive.
        Uses fixed historical date ranges to avoid processing lag errors.
        """
        params = {
            "latitude": lat,
            "longitude": lon,
            "parameters": "T2M_MAX,T2M_MIN,RH2M,ALLSKY_SWRAD_DAILY,WS2M,PRECTOTCORR",
            "community": "AG",
            "format": "JSON",
            "start": start_date,
            "end": end_date
        }

        try:
            async with httpx.AsyncClient(timeout=15.0) as client:
                response = await client.get(settings.NASA_POWER_BASE_URL, params=params)
                response.raise_for_status()
                data = response.json()
                return {
                    "source": "NASA POWER Archive",
                    "latitude": lat,
                    "longitude": lon,
                    "daily_weather": data.get("properties", {}).get("parameter", {})
                }
        except Exception as e:
            return {
                "source": "NASA POWER Archive",
                "error": str(e),
                "is_fallback": True
            }