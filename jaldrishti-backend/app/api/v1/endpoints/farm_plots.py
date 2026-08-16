from datetime import date
from typing import List
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.models.user import User
from app.models.farm_plot import FarmPlot
from app.schemas.farm_plot_schema import FarmPlotCreate, FarmPlotUpdate, FarmPlotResponse
from app.core.security import get_current_user

router = APIRouter()

@router.get("/", response_model=List[FarmPlotResponse])
def get_user_farm_plots(
    limit: int = Query(20, ge=1, le=100, description="Page size limit"),
    offset: int = Query(0, ge=0, description="Page offset"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    plots = (
        db.query(FarmPlot)
        .filter(FarmPlot.user_id == current_user.id)
        .order_by(FarmPlot.is_primary.desc(), FarmPlot.id.asc())
        .offset(offset)
        .limit(limit)
        .all()
    )
    return plots


@router.post("/", response_model=FarmPlotResponse)
def create_farm_plot(
    payload: FarmPlotCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    existing_count = db.query(FarmPlot).filter(FarmPlot.user_id == current_user.id).count()
    
    # If first plot or requested as primary, mark others non-primary
    is_first_plot = (existing_count == 0)
    should_be_primary = payload.is_primary or is_first_plot

    if should_be_primary:
        db.query(FarmPlot).filter(FarmPlot.user_id == current_user.id).update({"is_primary": False})

    new_plot = FarmPlot(
        user_id=current_user.id,
        name=payload.name.strip(),
        location_name=payload.location_name.strip() if payload.location_name else "Farm Location",
        latitude=payload.latitude,
        longitude=payload.longitude,
        crop_id=payload.crop_id,
        sowing_date=payload.sowing_date,
        area_acres=payload.area_acres,
        is_primary=should_be_primary,
        pump_hp=payload.pump_hp if payload.pump_hp is not None else 5.0,
        pump_flow_lps=payload.pump_flow_lps if payload.pump_flow_lps is not None else 5.0,
        irrigation_method=payload.irrigation_method if payload.irrigation_method else "flood",
        soil_type=payload.soil_type if payload.soil_type else "clay_loam",
        version=1
    )
    
    db.add(new_plot)
    db.commit()
    db.refresh(new_plot)
    return new_plot


@router.put("/{plot_id}", response_model=FarmPlotResponse)
def update_farm_plot(
    plot_id: int,
    payload: FarmPlotUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    plot = db.query(FarmPlot).filter(FarmPlot.id == plot_id, FarmPlot.user_id == current_user.id).first()
    if not plot:
        raise HTTPException(status_code=404, detail="Farm plot not found")

    if payload.expected_version is not None:
        if plot.version != payload.expected_version:
            raise HTTPException(
                status_code=409,
                detail=f"Conflict: Farm plot was modified on another device (current version: {plot.version}, expected: {payload.expected_version}). Please refresh."
            )

    if payload.is_primary:
        db.query(FarmPlot).filter(FarmPlot.user_id == current_user.id).update({"is_primary": False})

    update_data = payload.model_dump(exclude_unset=True)
    update_data.pop("expected_version", None)

    for key, val in update_data.items():
        setattr(plot, key, val)

    plot.version += 1

    db.commit()
    db.refresh(plot)
    return plot


@router.delete("/{plot_id}")
def delete_farm_plot(
    plot_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    plot = db.query(FarmPlot).filter(FarmPlot.id == plot_id, FarmPlot.user_id == current_user.id).first()
    if not plot:
        raise HTTPException(status_code=404, detail="Farm plot not found")

    was_primary = plot.is_primary
    db.delete(plot)
    db.commit()

    # If primary plot was deleted, promote another plot to primary
    if was_primary:
        remaining_plot = db.query(FarmPlot).filter(FarmPlot.user_id == current_user.id).first()
        if remaining_plot:
            remaining_plot.is_primary = True
            db.commit()

    return {"message": "Farm plot deleted successfully"}


@router.put("/{plot_id}/set-primary", response_model=FarmPlotResponse)
def set_primary_farm_plot(
    plot_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    plot = db.query(FarmPlot).filter(FarmPlot.id == plot_id, FarmPlot.user_id == current_user.id).first()
    if not plot:
        raise HTTPException(status_code=404, detail="Farm plot not found")

    db.query(FarmPlot).filter(FarmPlot.user_id == current_user.id).update({"is_primary": False})
    plot.is_primary = True
    db.commit()
    db.refresh(plot)
    return plot
