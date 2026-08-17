import logging
from typing import Optional, Dict
from sqlalchemy.orm import Session
from app.models.regional_tariff import RegionalTariff
from app.services.cache_service import CacheService

logger = logging.getLogger("jaldrishti.tariffs")


class RegionalTariffService:
    INITIAL_SEED_TARIFFS = [
        {
            "state_code": "WB",
            "state_name": "West Bengal",
            "diesel_tariff_inr_hr": 80.0,
            "electric_tariff_inr_hr": 25.0,
            "diesel_co2_kg_hr": 2.68,
            "electric_co2_kg_hr": 0.72,
            "attribution_notice": "Calculated using West Bengal state agricultural tariff (~₹25/hr grid) & CEA India grid emission factor (0.72 kg CO2/hr)."
        },
        {
            "state_code": "PB",
            "state_name": "Punjab",
            "diesel_tariff_inr_hr": 95.0,
            "electric_tariff_inr_hr": 30.0,
            "diesel_co2_kg_hr": 2.68,
            "electric_co2_kg_hr": 0.75,
            "attribution_notice": "Calculated using Punjab agricultural tariff (~₹30/hr grid) & CEA India grid emission factor."
        },
        {
            "state_code": "UP",
            "state_name": "Uttar Pradesh",
            "diesel_tariff_inr_hr": 85.0,
            "electric_tariff_inr_hr": 22.0,
            "diesel_co2_kg_hr": 2.68,
            "electric_co2_kg_hr": 0.78,
            "attribution_notice": "Calculated using UP state agricultural tariff (~₹22/hr grid) & CEA India grid emission factor."
        },
        {
            "state_code": "MH",
            "state_name": "Maharashtra",
            "diesel_tariff_inr_hr": 90.0,
            "electric_tariff_inr_hr": 28.0,
            "diesel_co2_kg_hr": 2.68,
            "electric_co2_kg_hr": 0.70,
            "attribution_notice": "Calculated using Maharashtra agricultural tariff (~₹28/hr grid) & CEA India grid emission factor."
        },
        {
            "state_code": "BR",
            "state_name": "Bihar",
            "diesel_tariff_inr_hr": 85.0,
            "electric_tariff_inr_hr": 20.0,
            "diesel_co2_kg_hr": 2.68,
            "electric_co2_kg_hr": 0.74,
            "attribution_notice": "Calculated using Bihar agricultural tariff (~₹20/hr grid) & CEA India grid emission factor."
        },
        {
            "state_code": "DEFAULT",
            "state_name": "National Benchmark",
            "diesel_tariff_inr_hr": 80.0,
            "electric_tariff_inr_hr": 25.0,
            "diesel_co2_kg_hr": 2.68,
            "electric_co2_kg_hr": 0.72,
            "attribution_notice": "Calculated using national average agricultural labor/fuel tariff (~₹80/hr) & CEA India grid factor."
        }
    ]

    @classmethod
    def seed_initial_tariffs_if_empty(cls, db: Session):
        try:
            count = db.query(RegionalTariff).count()
            if count == 0:
                logger.info("[Tariff Service] Seeding initial state regional tariffs into database...")
                for item in cls.INITIAL_SEED_TARIFFS:
                    rec = RegionalTariff(**item)
                    db.add(rec)
                db.commit()
        except Exception as e:
            logger.warning(f"[Tariff Service] Error seeding initial tariffs: {e}")

    @classmethod
    def resolve_state_code(cls, location_name: Optional[str], lat: float, lon: float) -> str:
        """
        Parses location text or lat/lon coordinates to determine state code.
        """
        if location_name:
            loc_lower = location_name.lower()
            if "bengal" in loc_lower or "wb" in loc_lower or "burdwan" in loc_lower or "kolkata" in loc_lower or "hooghly" in loc_lower:
                return "WB"
            if "punjab" in loc_lower or "pb" in loc_lower or "ludhiana" in loc_lower or "amritsar" in loc_lower:
                return "PB"
            if "pradesh" in loc_lower or "up" in loc_lower or "lucknow" in loc_lower or "kanpur" in loc_lower:
                return "UP"
            if "maharashtra" in loc_lower or "mh" in loc_lower or "pune" in loc_lower or "mumbai" in loc_lower or "nagpur" in loc_lower:
                return "MH"
            if "bihar" in loc_lower or "br" in loc_lower or "patna" in loc_lower:
                return "BR"

        # Geo-bounding box fallback for Indian agricultural hubs
        if 21.0 <= lat <= 27.5 and 85.5 <= lon <= 89.9:
            return "WB"
        if 29.5 <= lat <= 32.5 and 73.8 <= lon <= 76.9:
            return "PB"
        if 23.8 <= lat <= 30.5 and 77.0 <= lon <= 84.5:
            return "UP"
        if 15.6 <= lat <= 22.0 and 72.6 <= lon <= 80.9:
            return "MH"
        if 24.2 <= lat <= 27.5 and 83.3 <= lon <= 88.3:
            return "BR"

        return "DEFAULT"

    @classmethod
    def get_tariff_for_plot(
        cls,
        db: Session,
        location_name: Optional[str],
        lat: float,
        lon: float
    ) -> RegionalTariff:
        """
        Retrieves active RegionalTariff profile for given location.
        """
        cls.seed_initial_tariffs_if_empty(db)
        state_code = cls.resolve_state_code(location_name, lat, lon)
        
        # Check Redis Cache
        cache_key = f"tariff:{state_code}"
        cached = CacheService.get(cache_key)
        if cached and isinstance(cached, dict):
            # Construct transient object
            return RegionalTariff(**cached)

        tariff = db.query(RegionalTariff).filter(RegionalTariff.state_code == state_code).first()
        if not tariff:
            tariff = db.query(RegionalTariff).filter(RegionalTariff.state_code == "DEFAULT").first()

        if tariff:
            tariff_dict = {
                "id": tariff.id,
                "state_code": tariff.state_code,
                "state_name": tariff.state_name,
                "diesel_tariff_inr_hr": tariff.diesel_tariff_inr_hr,
                "electric_tariff_inr_hr": tariff.electric_tariff_inr_hr,
                "diesel_co2_kg_hr": tariff.diesel_co2_kg_hr,
                "electric_co2_kg_hr": tariff.electric_co2_kg_hr,
                "attribution_notice": tariff.attribution_notice
            }
            CacheService.set(cache_key, tariff_dict, expire_seconds=86400)

        return tariff
