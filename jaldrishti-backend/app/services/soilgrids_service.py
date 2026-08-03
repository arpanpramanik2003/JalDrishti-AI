import httpx
from app.core.config import settings
from app.services.cache_service import CacheService

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

    @staticmethod
    async def fetch_soil_profile(lat: float, lon: float, custom_soil_type: str = None) -> dict:
        """
        Queries SoilGrids v2.0 REST API with Redis caching or returns selected custom soil texture preset.
        """
        if custom_soil_type and custom_soil_type in SoilGridsService.SOIL_TYPE_PRESETS:
            preset_props = SoilGridsService.get_preset_soil_profile(custom_soil_type)
            return {"latitude": lat, "longitude": lon, "soil_properties": preset_props}

        grid_lat = round(lat, 2)
        grid_lon = round(lon, 2)
        cache_key = f"soil:{grid_lat}:{grid_lon}"

        cached_data = CacheService.get(cache_key)
        if cached_data:
            return cached_data

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
        
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
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

                # Cache soil profile for 7 days (604800 seconds)
                CacheService.set(cache_key, result, expire_seconds=604800)
                return result
                
        except (httpx.HTTPStatusError, httpx.RequestError) as e:
            print(f"⚠️ SoilGrids API unreachable ({type(e).__name__}). Using regional fallback data.")
            return {"latitude": lat, "longitude": lon, "soil_properties": SoilGridsService.DEFAULT_SOIL_PROFILE}