# Entity-Relationship Diagram (ERD)

> **Audience**: Database administrators, backend developers, and data architects.  
> **Source Verification**: Derived directly from SQLAlchemy models in [`app/models/user.py`](file:///d:/jaldrishti/jaldrishti-backend/app/models/user.py), [`app/models/farm_plot.py`](file:///d:/jaldrishti/jaldrishti-backend/app/models/farm_plot.py), [`app/models/regional_tariff.py`](file:///d:/jaldrishti/jaldrishti-backend/app/models/regional_tariff.py), and [`app/models/chat_history.py`](file:///d:/jaldrishti/jaldrishti-backend/app/models/chat_history.py).

---

## 1. Complete System ERD

The following diagram captures the complete, corrected schema of the JalDrishti relational database.

> [!NOTE]
> **Audit Corrections Incorporated**:
> 1. Restored the **four tables omitted from legacy diagrams**: `password_resets`, `regional_tariffs`, `chat_conversations`, and `chat_messages`.
> 2. Added the **Phase 1 persistent depletion table**: `soil_depletion_state`.
> 3. Verified all field names, primary keys, and foreign keys against the active Python code.

```mermaid
erDiagram
    users ||--o| user_profiles : "has profile (1:1)"
    users ||--o{ farm_plots : "owns (1:N)"
    users ||--o{ chat_conversations : "participates in (1:N)"
    farm_plots ||--o{ irrigation_logs : "records (1:N)"
    farm_plots ||--o| soil_depletion_state : "tracks (1:1)"
    chat_conversations ||--o{ chat_messages : "contains (1:N)"

    users {
        int id PK
        string username UK
        string phone_number UK
        string hashed_password
        boolean is_active
        string fcm_token
        datetime created_at
        datetime updated_at
    }

    user_profiles {
        int id PK
        int user_id FK, UK
        string first_name
        string last_name
        string location_name
        float latitude
        float longitude
        float farm_area_acres
        string interested_crop
        string farming_experience
        string preferred_language
    }

    password_resets {
        int id PK
        string phone_number
        string otp_code
        datetime expires_at
        boolean is_used
        datetime created_at
    }

    farm_plots {
        int id PK
        int user_id FK
        string name
        string location_name
        float latitude
        float longitude
        string crop_id
        date sowing_date
        float area_acres
        boolean is_primary
        float pump_hp
        float pump_flow_lps
        string irrigation_method
        string soil_type
        int version
        datetime created_at
        datetime updated_at
    }

    irrigation_logs {
        int id PK
        int farm_plot_id FK
        float applied_mm
        date applied_date
        string notes
        datetime created_at
    }

    soil_depletion_state {
        int farm_plot_id PK, FK
        float current_depletion_mm
        float yesterday_depletion_mm
        date last_updated_date
        int skipped_runs_count
        date last_rain_hold_date
        datetime created_at
        datetime updated_at
    }

    regional_tariffs {
        int id PK
        string state_code UK
        string state_name
        float diesel_tariff_inr_hr
        float electric_tariff_inr_hr
        float diesel_co2_kg_hr
        float electric_co2_kg_hr
        string attribution_notice
        datetime updated_at
    }

    chat_conversations {
        int id PK
        string session_id UK
        int user_id FK
        datetime created_at
        datetime updated_at
    }

    chat_messages {
        int id PK
        int conversation_id FK
        string role
        text content
        datetime created_at
    }
```

---

## 2. Table Relationship Matrix

| Parent Table | Relationship | Child Table | Foreign Key | Cascade Behavior | Business Rule |
|:-------------|:-------------|:------------|:------------|:-----------------|:--------------|
| `users` | 1-to-1 | `user_profiles` | `user_profiles.user_id` | `cascade="all, delete-orphan"` | Every farmer has exactly one profile specifying personal and regional defaults. |
| `users` | 1-to-Many | `farm_plots` | `farm_plots.user_id` | Enforced at DB level | A farmer can own and manage multiple distinct agricultural plots. |
| `users` | 1-to-Many | `chat_conversations` | `chat_conversations.user_id` | Enforced at DB level | Farmer chat sessions are tied to the user account for persistent history. |
| `farm_plots` | 1-to-Many | `irrigation_logs` | `irrigation_logs.farm_plot_id` | `cascade="all, delete-orphan"` | Each plot accumulates historical irrigation applications logged by the farmer. |
| `farm_plots` | 1-to-1 | `soil_depletion_state` | `soil_depletion_state.farm_plot_id` | `ondelete="CASCADE"` | Exactly one persistent soil moisture tracker exists per plot. Deleting the plot purges the tracker. |
| `chat_conversations` | 1-to-Many | `chat_messages` | `chat_messages.conversation_id` | `cascade="all, delete-orphan"` | Individual conversation rounds are ordered chronologically by `created_at ASC`. |
| Standalone | N/A | `password_resets` | None (keyed by `phone_number`) | Retained until expiry | Transient OTP storage for phone-based credential recovery. |
| Standalone | N/A | `regional_tariffs` | None (keyed by `state_code`) | Managed by Admin | Looked up via geospatial coordinates or location text to apply localized economic factors. |
