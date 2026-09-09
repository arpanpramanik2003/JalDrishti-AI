# Table-by-Table Schema Reference

> **Audience**: Backend engineers, database administrators, and QA automation engineers.  
> **Source Verification**: Derived directly from SQLAlchemy model declarations in [`app/models/`](file:///d:/jaldrishti/jaldrishti-backend/app/models/).

---

## 1. `users` Table
- **Source Model**: `User` in [`app/models/user.py:6-20`](file:///d:/jaldrishti/jaldrishti-backend/app/models/user.py#L6-L20)
- **Purpose**: Core authentication, credentials, and notification push token registry.

| Column | Type | Nullable | Primary Key | Foreign Key | Indexes | Purpose / Business Logic |
|:-------|:-----|:---------|:------------|:------------|:--------|:-------------------------|
| `id` | `Integer` | No | Yes | None | PK index | Auto-incrementing user identity. |
| `username` | `String(50)` | No | No | None | Unique index | Unique handle or farmer display name. |
| `phone_number` | `String(20)` | No | No | None | Unique index | E.164 phone number used for login and OTP. |
| `hashed_password` | `String(255)` | No | No | None | None | Bcrypt password hash. |
| `is_active` | `Boolean` | Yes | No | None | None | Account status toggle (default: `True`). |
| `fcm_token` | `String(255)` | Yes | No | None | None | Firebase Cloud Messaging device registration token for push notifications. |
| `created_at` | `DateTime` | Yes | No | None | Indexed | UTC timestamp of account creation (default: `utcnow`). |
| `updated_at` | `DateTime` | Yes | No | None | None | UTC timestamp of last record update (onupdate: `utcnow`). |

---

## 2. `user_profiles` Table
- **Source Model**: `UserProfile` in [`app/models/user.py:22-39`](file:///d:/jaldrishti/jaldrishti-backend/app/models/user.py#L22-L39)
- **Purpose**: Farmer demographic details, default location, farm scale, and interface preferences.

| Column | Type | Nullable | Primary Key | Foreign Key | Indexes | Purpose / Business Logic |
|:-------|:-----|:---------|:------------|:------------|:--------|:-------------------------|
| `id` | `Integer` | No | Yes | None | PK index | Auto-incrementing profile identity. |
| `user_id` | `Integer` | No | No | `users.id` | Unique index | 1-to-1 foreign key to parent user account. |
| `first_name` | `String(50)` | Yes | No | None | None | Farmer first name. |
| `last_name` | `String(50)` | Yes | No | None | None | Farmer family name. |
| `location_name` | `String(100)`| Yes | No | None | None | Farmer village/district name (default: `"Kolkata, West Bengal"`). |
| `latitude` | `Float` | Yes | No | None | None | Default farm latitude (default: `22.5726`). |
| `longitude` | `Float` | Yes | No | None | None | Default farm longitude (default: `88.3639`). |
| `farm_area_acres`| `Float` | Yes | No | None | None | Total cumulative farm holding in acres (default: `2.5`). |
| `interested_crop`| `String(50)` | Yes | No | None | None | Primary crop of interest (default: `"paddy_rice"`). |
| `farming_experience`|`String(30)`| Yes | No | None | None | Experience level: `"Beginner"`, `"Intermediate"`, `"Expert"`. |
| `preferred_language`|`String(20)`| Yes | No | None | None | UI language: `"English"`, `"Bengali"`, `"Hindi"` (default: `"English"`). |

---

## 3. `password_resets` Table
- **Source Model**: `PasswordReset` in [`app/models/user.py:41-50`](file:///d:/jaldrishti/jaldrishti-backend/app/models/user.py#L41-L50)
- **Purpose**: Ephemeral OTP tracking for phone-based credential reset requests.

| Column | Type | Nullable | Primary Key | Foreign Key | Indexes | Purpose / Business Logic |
|:-------|:-----|:---------|:------------|:------------|:--------|:-------------------------|
| `id` | `Integer` | No | Yes | None | PK index | Auto-incrementing reset record identity. |
| `phone_number` | `String(20)` | No | No | None | Indexed | Target phone number receiving OTP. |
| `otp_code` | `String(10)` | No | No | None | None | 6-digit numeric verification code. |
| `expires_at` | `DateTime` | No | No | None | None | UTC expiry timestamp (typically 10 minutes from issue). |
| `is_used` | `Boolean` | Yes | No | None | None | Consumption flag to prevent replay attacks (default: `False`). |
| `created_at` | `DateTime` | Yes | No | None | None | UTC timestamp of request generation. |

---

## 4. `farm_plots` Table
- **Source Model**: `FarmPlot` in [`app/models/farm_plot.py:6-35`](file:///d:/jaldrishti/jaldrishti-backend/app/models/farm_plot.py#L6-L35)
- **Purpose**: Physical field plot definitions, geospatial coordinates, crop phenology, and pump hardware attributes.

| Column | Type | Nullable | Primary Key | Foreign Key | Indexes | Purpose / Business Logic |
|:-------|:-----|:---------|:------------|:------------|:--------|:-------------------------|
| `id` | `Integer` | No | Yes | None | PK index | Auto-incrementing plot identity. |
| `user_id` | `Integer` | No | No | `users.id` | Indexed | Foreign key linking plot to owner account. |
| `name` | `String(100)`| No | No | None | None | Field nickname (e.g., `"North River Plot"`). |
| `location_name` | `String(100)`| Yes | No | None | None | Textual location descriptor (default: `"Burdwan, West Bengal"`). |
| `latitude` | `Float` | No | No | None | None | Geospatial latitude in decimal degrees. |
| `longitude` | `Float` | No | No | None | None | Geospatial longitude in decimal degrees. |
| `crop_id` | `String(50)` | No | No | None | None | Crop identifier matching `crop_coefficients.json` (default: `"paddy_rice"`). |
| `sowing_date` | `Date` | No | No | None | None | Date crop was planted/sown. |
| `area_acres` | `Float` | No | No | None | None | Physical area of plot in acres (default: `2.5`). |
| `is_primary` | `Boolean` | Yes | No | None | None | Flag identifying primary plot on dashboard (default: `False`). |
| `pump_hp` | `Float` | No | No | None | None | Pump motor rating in horsepower (default: `5.0`). |
| `pump_flow_lps`| `Float` | No | No | None | None | Water delivery discharge in Liters per second (default: `5.0`). |
| `irrigation_method`|`String(30)`| No | No | None | None | Irrigation application system: `"drip"`, `"sprinkler"`, `"flood"`. |
| `soil_type` | `String(30)` | No | No | None | None | Soil texture profile key: `"sandy_loam"`, `"loam"`, `"clay_loam"`, etc. |
| `version` | `Integer` | No | No | None | None | Optimistic locking schema version (default: `1`). |
| `created_at` | `DateTime` | Yes | No | None | None | UTC timestamp of registration. |
| `updated_at` | `DateTime` | Yes | No | None | None | UTC timestamp of last plot modification. |

---

## 5. `irrigation_logs` Table
- **Source Model**: `IrrigationLog` in [`app/models/farm_plot.py:37-48`](file:///d:/jaldrishti/jaldrishti-backend/app/models/farm_plot.py#L37-L48)
- **Purpose**: Farmer-logged irrigation events recording applied water depth.

| Column | Type | Nullable | Primary Key | Foreign Key | Indexes | Purpose / Business Logic |
|:-------|:-----|:---------|:------------|:------------|:--------|:-------------------------|
| `id` | `Integer` | No | Yes | None | PK index | Auto-incrementing log identity. |
| `farm_plot_id` | `Integer` | No | No | `farm_plots.id`| Indexed | Foreign key linking log to specific farm plot. |
| `applied_mm` | `Float` | No | No | None | None | Depth of water applied to plot in millimeters. |
| `applied_date` | `Date` | No | No | None | Indexed | Calendar date of irrigation application. |
| `notes` | `String(200)`| Yes | No | None | None | Optional operational notes from farmer. |
| `created_at` | `DateTime` | Yes | No | None | None | UTC timestamp of record creation. |

---

## 6. `soil_depletion_state` Table (Phase 1 Fix)
- **Source Model**: `SoilDepletionState` in [`app/models/farm_plot.py:50-69`](file:///d:/jaldrishti/jaldrishti-backend/app/models/farm_plot.py#L50-L69)
- **Purpose**: Persistent seasonal root-zone soil water balance tracker, preventing rolling memory loss.

| Column | Type | Nullable | Primary Key | Foreign Key | Indexes | Purpose / Business Logic |
|:-------|:-----|:---------|:------------|:------------|:--------|:-------------------------|
| `farm_plot_id` | `Integer` | No | Yes | `farm_plots.id` (CASCADE)| PK & Index | 1-to-1 foreign key and primary key tied to parent plot. |
| `current_depletion_mm`| `Float` | No | No | None | None | Cumulative root-zone water depletion $D_i$ at end of today. |
| `yesterday_depletion_mm`|`Float` | No | No | None | None | Baseline depletion $D_{i-1}$ from yesterday used for idempotent recalculations. |
| `last_updated_date`| `Date` | No | No | None | None | Date of most recent daily balance execution. |
| `skipped_runs_count`| `Integer` | No | No | None | None | Total cumulative Rain Hold skipped irrigation runs credited. |
| `last_rain_hold_date`| `Date` | Yes | No | None | None | Calendar date of last Rain Hold increment, guarding against duplicate daily counts. |
| `created_at` | `DateTime` | Yes | No | None | None | UTC timestamp of initialization. |
| `updated_at` | `DateTime` | Yes | No | None | None | UTC timestamp of last balance update. |

---

## 7. `regional_tariffs` Table
- **Source Model**: `RegionalTariff` in [`app/models/regional_tariff.py:6-21`](file:///d:/jaldrishti/jaldrishti-backend/app/models/regional_tariff.py#L6-L21)
- **Purpose**: State-level agricultural power tariffs and national grid carbon emission factors.

| Column | Type | Nullable | Primary Key | Foreign Key | Indexes | Purpose / Business Logic |
|:-------|:-----|:---------|:------------|:------------|:--------|:-------------------------|
| `id` | `Integer` | No | Yes | None | PK index | Auto-incrementing tariff entry identity. |
| `state_code` | `String(10)` | No | No | None | Unique index | State postal abbreviation (e.g., `"WB"`, `"UP"`, `"PB"`, `"DEFAULT"`). |
| `state_name` | `String(100)`| No | No | None | None | Full state title (e.g., `"West Bengal"`, `"National Benchmark"`). |
| `diesel_tariff_inr_hr`|`Float` | No | No | None | None | Operating cost in ₹ per hour for diesel pumpset (default: `80.0`). |
| `electric_tariff_inr_hr`|`Float`| No | No | None | None | Subsidized power cost in ₹ per hour for electric pump (default: `25.0`). |
| `diesel_co2_kg_hr`| `Float` | No | No | None | None | Carbon emission factor in $\text{kg } CO_2/\text{hr}$ for diesel pump (default: `2.68`). |
| `electric_co2_kg_hr`|`Float` | No | No | None | None | Grid carbon emission factor in $\text{kg } CO_2/\text{hr}$ (default: `0.72`, CEA India). |
| `attribution_notice`|`String(255)`|No | No | None | None | Legal / data source citation string. |
| `updated_at` | `DateTime` | Yes | No | None | None | UTC timestamp of tariff adjustment. |

---

## 8. `chat_conversations` & `chat_messages` Tables
- **Source Model**: `ChatConversation` & `ChatMessage` in [`app/models/chat_history.py:6-29`](file:///d:/jaldrishti/jaldrishti-backend/app/models/chat_history.py#L6-L29)
- **Purpose**: Multi-turn chat session history and message audit log for JalSathi AI.

### `chat_conversations`
| Column | Type | Nullable | Primary Key | Foreign Key | Indexes | Purpose / Business Logic |
|:-------|:-----|:---------|:------------|:------------|:--------|:-------------------------|
| `id` | `Integer` | No | Yes | None | PK index | Auto-incrementing conversation identity. |
| `session_id` | `String(100)`| No | No | None | Unique index | UUID or client session tracking string. |
| `user_id` | `Integer` | No | No | `users.id` | Indexed | Owner user account identifier. |
| `created_at` | `DateTime` | Yes | No | None | None | UTC timestamp of session start. |
| `updated_at` | `DateTime` | Yes | No | None | None | UTC timestamp of last interaction. |

### `chat_messages`
| Column | Type | Nullable | Primary Key | Foreign Key | Indexes | Purpose / Business Logic |
|:-------|:-----|:---------|:------------|:------------|:--------|:-------------------------|
| `id` | `Integer` | No | Yes | None | PK index | Auto-incrementing message identity. |
| `conversation_id`| `Integer` | No | No | `chat_conversations.id` (CASCADE)| Indexed | Parent conversation session reference. |
| `role` | `String(20)` | No | No | None | None | Message sender role: `"user"` or `"assistant"`. |
| `content` | `Text` | No | No | None | None | Full text message body (vernacular or English). |
| `created_at` | `DateTime` | Yes | No | None | None | UTC timestamp of message generation. |

---

## 9. `document_embeddings` Table (Historical Architecture Note)
- **Source Model**: `DocumentEmbedding` in [`app/models/document_embedding.py:5-14`](file:///d:/jaldrishti/jaldrishti-backend/app/models/document_embedding.py#L5-L14)
- **Table Structure**: `id`, `doc_name`, `chunk_index`, `content`, `embedding` (`JSON`), `created_at`.
- **Operational Status**: Maintained in database schema for legacy compatibility. As of Phase 5 remediation ([`PHASE5_CHANGELOG.md`](file:///d:/jaldrishti/PHASE5_CHANGELOG.md)), vector search is executed directly against the local high-performance **ChromaDB 1.5.9 SQLite vector store** (`app/data/chroma_db`) using `all-MiniLM-L6-v2` dense embeddings, bypassing relational JSON serialization.
