import json
import os
import logging
from typing import Dict, Any, List
from fastapi import HTTPException

logger = logging.getLogger("jaldrishti.crop_config")

class CropConfigService:
    _CROP_CONFIG_CACHE: Dict[str, Any] = {}

    @classmethod
    def _load_all_configs(cls) -> Dict[str, Any]:
        """
        Reads crop_coefficients.json once into memory. Returns cached dictionary on subsequent calls.
        """
        if not cls._CROP_CONFIG_CACHE:
            crop_db_path = os.path.abspath(
                os.path.join(os.path.dirname(__file__), '..', 'engine', 'crop_coefficients.json')
            )
            if not os.path.exists(crop_db_path):
                logger.error(f"[CropConfigService] Database file missing at {crop_db_path}")
                raise HTTPException(status_code=500, detail="Crop database file not found")
            
            with open(crop_db_path, 'r', encoding='utf-8') as f:
                cls._CROP_CONFIG_CACHE = json.load(f)
            logger.info(f"[CropConfigService] Successfully loaded {len(cls._CROP_CONFIG_CACHE)} crop configurations into memory cache.")
        return cls._CROP_CONFIG_CACHE

    @classmethod
    def get_crop_config(cls, crop_id: str) -> Dict[str, Any]:
        """
        Retrieves crop configuration dictionary for a given crop_id from in-memory cache.
        """
        configs = cls._load_all_configs()
        if crop_id not in configs:
            raise HTTPException(status_code=404, detail=f"Crop '{crop_id}' not found")
        return configs[crop_id]

    @classmethod
    def get_all_crops(cls) -> List[Dict[str, Any]]:
        """
        Returns all supported crops sorted alphabetically from in-memory cache.
        """
        configs = cls._load_all_configs()
        crop_list = []
        for crop_id, details in configs.items():
            crop_list.append({
                "id": crop_id,
                "name": details.get("name", crop_id),
                "season": details.get("season", "All-Season"),
                "root_depth_m": details.get("root_depth_m", 0.5),
                "depletion_fraction_p": details.get("depletion_fraction_p", 0.5)
            })
        crop_list.sort(key=lambda x: x["name"])
        return crop_list
