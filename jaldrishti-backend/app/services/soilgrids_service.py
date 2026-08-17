import time
import asyncio
import httpx
import logging
from app.core.config import settings
from app.services.cache_service import CacheService

logger = logging.getLogger("jaldrishti.soilgrids")


class SoilGridsService:
    # Default regional fallback (West Bengal Gangetic Alluvium Profile)
    DEFAULT_SOIL_PROFILE = {
        "clay_percent": 30.0,
        "sand_percent": 25.0,
        "bulk_density_kg_dm3": 1.35,
        "soc_g_kg": 10.0,
        "is_fallback": True
    }

    SOIL_TYPE_PRESETS = {
        "sandy_loam": {"clay_percent": 10.0, "sand_percent": 65.0, "name": "Sandy Loam (Fast Drainage)"},
        "loam": {"clay_percent": 20.0, "sand_percent": 40.0, "name": "Loam (Balanced Retention)"},
        "clay_loam": {"clay_percent": 32.0, "sand_percent": 30.0, "name": "Clay Loam (High Retention)"},
        "silty_clay": {"clay_percent": 45.0, "sand_percent": 10.0, "name": "Silty Clay (Very High Storage)"},
        "heavy_clay": {"clay_percent": 60.0, "sand_percent": 15.0, "name": "Heavy Clay (Maximum Moisture)"},
    }

    # Circuit breaker & Stale memory storage
    _circuit_breaker_until = 0
    _consecutive_failures = 0
    _stale_cache = {}

    @staticmethod
    def get_preset_soil_profile(soil_type: str) -> dict:
        """Returns clay % and sand % based on farmer's selected soil texture preset."""
        preset = SoilGridsService.SOIL_TYPE_PRESETS.get(soil_type, SoilGridsService.SOIL_TYPE_PRESETS["clay_loam"])
        return {
            "clay_percent": preset["clay_percent"],
            "sand_percent": preset["sand_percent"],
            "bulk_density_kg_dm3": 1.35,
            "soc_g_kg": 10.0,
            "is_fallback": False,
            "preset_name": preset["name"]
        }

    @classmethod
    async def fetch_soil_profile(cls, lat: float, lon: float, custom_soil_type: str = None) -> dict:
        """
        Queries SoilGrids v2.0 REST API with 5.5km grid caching, circuit breaker protection,
        retry policy, and fallback to user-selected presets or regional soil estimates.
        """
        if custom_soil_type and custom_soil_type in cls.SOIL_TYPE_PRESETS:
            preset_props = cls.get_preset_soil_profile(custom_soil_type)
            return {"latitude": lat, "longitude": lon, "soil_properties": preset_props}

        # 1. Coarsen grid resolution to 0.05° (~5.5km x 5.5km grid cell)
        grid_lat = round(round(lat * 20) / 20.0, 2)
        grid_lon = round(round(lon * 20) / 20.0, 2)
        cache_key = f"soil_grid:{grid_lat}:{grid_lon}"

        # 2. Check Primary Redis / Memory Cache
        cached_data = CacheService.get(cache_key)
        if cached_data:
            return cached_data

        # 3. Check Circuit Breaker Status
        now = time.time()
        if now < cls._circuit_breaker_until:
            stale = cls._stale_cache.get(cache_key)
            if stale:
                logger.info(f"[SoilGrids] Serving stale cached soil profile for grid ({grid_lat}, {grid_lon}) during circuit breaker backoff.")
                return stale
            logger.info(f"[SoilGrids] Circuit breaker active. Serving regional fallback soil profile for ({grid_lat}, {grid_lon}).")
            return {"latitude": lat, "longitude": lon, "soil_properties": cls.DEFAULT_SOIL_PROFILE}

        # 4. Prepare API request parameters
        params = [
            ("lon", str(lon)),
            ("lat", str(lat)),
            ("property", "clay"),
            ("property", "sand"),
            ("property", "soc"),
            ("property", "bdod"),
            ("depth", "0-5cm"),
            ("depth", "5-15cm"),
            ("depth", "15-30cm"),
            ("value", "mean")
        ]

        # 5. Execute API call with 3.5s timeout and 1 retry attempt
        max_attempts = 2
        for attempt in range(1, max_attempts + 1):
            try:
                async with httpx.AsyncClient(timeout=3.5) as client:
                    response = await client.get(settings.SOILGRIDS_BASE_URL, params=params)
                    response.raise_for_status()
                    data = response.json()

                    layers = data.get("properties", {}).get("layers", [])
                    parsed_properties = {}

                    for layer in layers:
                        prop_name = layer.get("name")
                        depths = layer.get("depths", [])
                        values = [d["values"]["mean"] for d in depths if d.get("values", {}).get("mean") is not None]

                        if values:
                            raw_avg = sum(values) / len(values)
                            if prop_name in ["clay", "sand"]:
                                parsed_properties[f"{prop_name}_percent"] = raw_avg / 10.0
                            elif prop_name == "bdod":
                                parsed_properties["bulk_density_kg_dm3"] = raw_avg / 100.0
                            elif prop_name == "soc":
                                parsed_properties["soc_g_kg"] = raw_avg / 10.0

                    parsed_properties["is_fallback"] = False
                    result = {"latitude": lat, "longitude": lon, "soil_properties": parsed_properties}

                    # Reset circuit breaker on success
                    cls._consecutive_failures = 0

                    # Cache soil profile for 30 days (2,592,000 seconds)
                    CacheService.set(cache_key, result, expire_seconds=2592000)
                    cls._stale_cache[cache_key] = result
                    return result

            except (httpx.HTTPStatusError, httpx.RequestError, Exception) as e:
                logger.warning(f"[SoilGrids Attempt {attempt}/{max_attempts}] Query failed for ({grid_lat}, {grid_lon}): {type(e).__name__}")
                if attempt < max_attempts:
                    await asyncio.sleep(0.5)

        # 6. Handle Failure & Trigger Circuit Breaker
        cls._consecutive_failures += 1
        if cls._consecutive_failures >= 3:
            cls._circuit_breaker_until = time.time() + 900 # 15-minute circuit breaker
            logger.warning(f"[SoilGrids] 3 consecutive API failures reached. Entering 15-minute circuit breaker.")

        stale = cls._stale_cache.get(cache_key)
        if stale:
            return stale

        return {"latitude": lat, "longitude": lon, "soil_properties": cls.DEFAULT_SOIL_PROFILE}