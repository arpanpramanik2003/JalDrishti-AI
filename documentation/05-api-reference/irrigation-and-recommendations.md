# API Reference: Irrigation & Recommendation Endpoints

> **Audience**: Mobile developers and backend integrators. For deep mathematical derivations, see [Scientific Reference](../02-scientific-reference/README.md). For end-to-end trace sequence diagrams, see [Request Lifecycle Walkthrough](../03-system-architecture/request-lifecycle-walkthrough.md).  
> **Source Controller**: [`app/api/v1/endpoints/irrigation.py`](file:///d:/jaldrishti/jaldrishti-backend/app/api/v1/endpoints/irrigation.py)  
> **Schemas**: [`app/schemas/irrigation_schema.py`](file:///d:/jaldrishti/jaldrishti-backend/app/schemas/irrigation_schema.py)

---

## 1. `POST /api/v1/irrigation/recommendation`
The core decision engine endpoint. Computes daily Reference Evapotranspiration ($ET_o$), evaluates dynamic growth stage $K_c(t)$, runs daily root-zone soil water mass balance against persistent depletion state ($D_i$), evaluates Smart Rain Hold forecast criteria, calculates pump duration, and returns cumulative seasonal ROI metrics.

- **Authentication**: `Bearer <access_token>` (`get_current_user`)
- **Request Body** (`IrrigationRequest`):
  ```json
  {
    "plot_id": 12,
    "crop_id": "paddy_rice",
    "sowing_date": "2026-07-01",
    "latitude": 23.2324,
    "longitude": 87.8615,
    "area_acres": 2.5,
    "pump_hp": 5.0,
    "pump_flow_lps": 5.0,
    "irrigation_method": "flood",
    "soil_type": "clay_loam",
    "field_name": "North River Paddy"
  }
  ```
- **Response** (`200 OK` - `IrrigationResponse`):
  ```json
  {
    "field_name": "North River Paddy",
    "crop_name": "Paddy Rice (Boro/Aman)",
    "sowing_date": "2026-07-01",
    "elapsed_days": 70,
    "current_growth_stage": "Mid-Season (Flowering/Yield Formation)",
    "dynamic_kc": 1.20,
    "effective_root_depth_m": 0.60,
    "total_available_water_mm": 72.4,
    "needs_irrigation_today": false,
    "recommended_water_mm": 0.0,
    "recommended_gross_water_mm": 0.0,
    "recommended_pump_hours": 0,
    "recommended_pump_minutes": 0,
    "irrigation_method_display": "Flood Irrigation (Surface)",
    "irrigation_efficiency_pct": 50,
    "soil_type_display": "Clay Loam (High Retention)",
    "soil_is_fallback": false,
    "status_summary": "RAIN_HOLD",
    "crop_lifecycle_status": "ACTIVE",
    "crop_status_message": null,
    "rain_hold_active": true,
    "rain_hold_message": "🌧️ SMART RAIN HOLD ACTIVE: Forecast predicts 6.2 mm rain in next 24h (12.4 mm over 48h). Skip irrigation today to prevent soil waterlogging and save ~₹240 in pumping costs!",
    "upcoming_rain_mm": 6.2,
    "upcoming_rain_24h_mm": 6.2,
    "upcoming_rain_48h_mm": 12.4,
    "estimated_cost_saved_inr": 240.0,
    "cumulative_savings": {
      "total_water_saved_liters": 136580.0,
      "total_money_saved_inr": 1080.0,
      "total_co2_avoided_kg": 36.4,
      "skipped_sessions_count": 3
    },
    "weather_summary": {
      "max_temp_c": 33.5,
      "min_temp_c": 26.0,
      "humidity_percent": 82.0,
      "wind_speed_kmh": 12.5,
      "precipitation_mm": 0.0
    },
    "daily_breakdown": [
      {
        "date": "2026-09-09",
        "eto_mm": 4.85,
        "etc_mm": 5.82,
        "rainfall_mm": 0.0,
        "irrigation_applied_mm": 0.0,
        "depletion_mm": 18.4,
        "raw_threshold_mm": 14.48,
        "max_temp_c": 33.5,
        "min_temp_c": 26.0,
        "humidity_percent": 82.0,
        "wind_speed_kmh": 12.5,
        "status": "RAIN_HOLD"
      }
    ]
  }
  ```

---

## 2. `POST /api/v1/irrigation/log`
Records an actual irrigation event performed by the farmer, directly reducing cumulative depletion ($D_i$) in subsequent mass balance runs.

- **Authentication**: `Bearer <access_token>` (`get_current_user`)
- **Request Body** (`IrrigationLogCreate`):
  ```json
  {
    "farm_plot_id": 12,
    "applied_mm": 25.0,
    "applied_date": "2026-09-09",
    "notes": "Ran 5 HP diesel pump for 3 hours"
  }
  ```
- **Response** (`201 Created` - `IrrigationLogResponse`):
  ```json
  {
    "id": 104,
    "farm_plot_id": 12,
    "applied_mm": 25.0,
    "applied_date": "2026-09-09",
    "notes": "Ran 5 HP diesel pump for 3 hours",
    "created_at": "2026-09-09T14:30:00Z"
  }
  ```

---

## 3. `GET /api/v1/irrigation/history/{plot_id}`
Returns historical logged irrigation events for a given plot, ordered chronologically.

- **Authentication**: `Bearer <access_token>` (`get_current_user`)
- **Path Parameters**: `plot_id` (integer, required)
- **Response** (`200 OK` - `List[IrrigationLogResponse]`):
  ```json
  [
    {
      "id": 104,
      "farm_plot_id": 12,
      "applied_mm": 25.0,
      "applied_date": "2026-09-09",
      "notes": "Ran 5 HP diesel pump for 3 hours",
      "created_at": "2026-09-09T14:30:00Z"
    },
    {
      "id": 98,
      "farm_plot_id": 12,
      "applied_mm": 30.0,
      "applied_date": "2026-08-28",
      "notes": "Flood canal release",
      "created_at": "2026-08-28T10:15:00Z"
    }
  ]
  ```
