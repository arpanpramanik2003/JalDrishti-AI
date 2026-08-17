from typing import List
from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.models.regional_tariff import RegionalTariff
from app.schemas.regional_tariff_schema import RegionalTariffResponse, RegionalTariffCreateUpdate
from app.services.regional_tariff_service import RegionalTariffService
from app.services.cache_service import CacheService
from app.core.config import settings

router = APIRouter()


def verify_admin_access(x_admin_key: str = Header(None, alias="X-Admin-API-Key")):
    if not x_admin_key or x_admin_key != settings.ADMIN_API_KEY:
        raise HTTPException(status_code=403, detail="Forbidden: Valid Admin API key required.")


@router.get("", response_model=List[RegionalTariffResponse])
def list_all_regional_tariffs(db: Session = Depends(get_db)):
    """
    Returns all state-wise and national default economic/emissions tariffs.
    """
    RegionalTariffService.seed_initial_tariffs_if_empty(db)
    return db.query(RegionalTariff).order_by(RegionalTariff.id.asc()).all()


@router.put("/{state_code}", response_model=RegionalTariffResponse)
def update_regional_tariff(
    state_code: str,
    payload: RegionalTariffCreateUpdate,
    db: Session = Depends(get_db),
    admin_auth: None = Depends(verify_admin_access)
):
    """
    Admin Policy Engine Endpoint: Dynamically tunes labor/electricity tariffs or CO2 factors for a target state.
    """
    code_upper = state_code.upper().strip()
    tariff = db.query(RegionalTariff).filter(RegionalTariff.state_code == code_upper).first()
    
    if not tariff:
        raise HTTPException(status_code=404, detail=f"Regional tariff profile for '{code_upper}' not found.")

    if payload.state_name is not None:
        tariff.state_name = payload.state_name.strip()
    if payload.diesel_tariff_inr_hr is not None:
        tariff.diesel_tariff_inr_hr = payload.diesel_tariff_inr_hr
    if payload.electric_tariff_inr_hr is not None:
        tariff.electric_tariff_inr_hr = payload.electric_tariff_inr_hr
    if payload.diesel_co2_kg_hr is not None:
        tariff.diesel_co2_kg_hr = payload.diesel_co2_kg_hr
    if payload.electric_co2_kg_hr is not None:
        tariff.electric_co2_kg_hr = payload.electric_co2_kg_hr
    if payload.attribution_notice is not None:
        tariff.attribution_notice = payload.attribution_notice.strip()

    db.commit()
    db.refresh(tariff)

    # Invalidate Redis cache
    r = CacheService._get_redis()
    if r:
        try:
            r.delete(f"tariff:{code_upper}")
        except Exception:
            pass

    return tariff
