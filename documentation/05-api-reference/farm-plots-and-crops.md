# API Reference: Farm Plots & Crop Catalog Endpoints

> **Audience**: Mobile developers and backend integrators.  
> **Source Controllers**:  
> - [`app/api/v1/endpoints/farm_plots.py`](file:///d:/jaldrishti/jaldrishti-backend/app/api/v1/endpoints/farm_plots.py)  
> - [`app/api/v1/endpoints/crop_info.py`](file:///d:/jaldrishti/jaldrishti-backend/app/api/v1/endpoints/crop_info.py)  
> **Schemas**: [`app/schemas/farm_plot_schema.py`](file:///d:/jaldrishti/jaldrishti-backend/app/schemas/farm_plot_schema.py)

---

## 1. `GET /api/v1/plots/`
Retrieves all farm plots registered by the authenticated farmer, ordered by creation date.

- **Authentication**: `Bearer <access_token>` (`get_current_user`)
- **Query Parameters**: None
- **Response** (`200 OK` - `List[FarmPlotResponse]`):
  ```json
  [
    {
      "id": 12,
      "user_id": 42,
      "name": "North River Paddy",
      "location_name": "Burdwan, West Bengal",
      "latitude": 23.2324,
      "longitude": 87.8615,
      "crop_id": "paddy_rice",
      "sowing_date": "2026-07-01",
      "area_acres": 2.5,
      "is_primary": true,
      "pump_hp": 5.0,
      "pump_flow_lps": 5.0,
      "irrigation_method": "flood",
      "soil_type": "clay_loam",
      "created_at": "2026-07-01T08:00:00Z",
      "updated_at": "2026-07-01T08:00:00Z"
    }
  ]
  ```

---

## 2. `POST /api/v1/plots/`
Creates a new farm plot. Automatically creates an initial associated `soil_depletion_state` record.

- **Authentication**: `Bearer <access_token>` (`get_current_user`)
- **Request Body** (`FarmPlotCreate`):
  ```json
  {
    "name": "South Canal Wheat",
    "location_name": "Karnal, Haryana",
    "latitude": 29.6857,
    "longitude": 76.9905,
    "crop_id": "wheat",
    "sowing_date": "2026-11-15",
    "area_acres": 3.0,
    "is_primary": false,
    "pump_hp": 7.5,
    "pump_flow_lps": 6.5,
    "irrigation_method": "sprinkler",
    "soil_type": "loam"
  }
  ```
- **Response** (`201 Created` - `FarmPlotResponse`): Returns the newly created plot object including assigned `id`.

---

## 3. `PUT /api/v1/plots/{plot_id}`
Updates agronomic, hardware, or coordinate attributes of an existing plot. Enforces ownership check against `current_user.id`.

- **Authentication**: `Bearer <access_token>` (`get_current_user`)
- **Path Parameters**: `plot_id` (integer, required)
- **Request Body** (`FarmPlotUpdate`): Any subset of plot fields.
  ```json
  {
    "name": "South Canal Wheat (Expanded)",
    "area_acres": 4.0,
    "pump_hp": 10.0
  }
  ```
- **Response** (`200 OK` - `FarmPlotResponse`): Returns the updated plot object.
- **Error Codes**: `404 Not Found` if the plot does not exist or belongs to another user.

---

## 4. `DELETE /api/v1/plots/{plot_id}`
Deletes a plot and cascades deletion to all associated `irrigation_logs` and `soil_depletion_state` records.

- **Authentication**: `Bearer <access_token>` (`get_current_user`)
- **Path Parameters**: `plot_id` (integer, required)
- **Response** (`200 OK`):
  ```json
  {
    "message": "Farm plot and associated history successfully deleted."
  }
  ```

---

## 5. `PUT /api/v1/plots/{plot_id}/set-primary`
Designates a specific plot as the primary plot, toggling `is_primary=False` on all other plots owned by the farmer.

- **Authentication**: `Bearer <access_token>` (`get_current_user`)
- **Path Parameters**: `plot_id` (integer, required)
- **Response** (`200 OK` - `FarmPlotResponse`): Returns the updated primary plot.

---

## 6. `GET /api/v1/crops/all`
Returns the complete reference catalog of supported crops, phenological growth stage durations, crop coefficients ($K_c$), and default root depths.

- **Authentication**: None (Public reference taxonomy)
- **Response** (`200 OK`):
  ```json
  {
    "crops": {
      "paddy_rice": {
        "name": "Paddy Rice (Boro/Aman)",
        "scientific_name": "Oryza sativa",
        "category": "Cereal",
        "root_depth_m": 0.6,
        "depletion_fraction_p": 0.20,
        "stages": {
          "initial": { "duration_days": 20, "Kc": 1.05 },
          "crop_dev": { "duration_days": 30, "Kc": 1.20 },
          "mid_season": { "duration_days": 40, "Kc": 1.20 },
          "late_season": { "duration_days": 30, "Kc": 0.90 }
        }
      },
      "wheat": {
        "name": "Wheat",
        "scientific_name": "Triticum aestivum",
        "category": "Cereal",
        "root_depth_m": 1.0,
        "depletion_fraction_p": 0.55,
        "stages": {
          "initial": { "duration_days": 20, "Kc": 0.40 },
          "crop_dev": { "duration_days": 30, "Kc": 1.15 },
          "mid_season": { "duration_days": 40, "Kc": 1.15 },
          "late_season": { "duration_days": 30, "Kc": 0.40 }
        }
      }
    }
  }
  ```
