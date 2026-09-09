# Screen-by-Screen Mobile Reference

> **Audience**: Flutter developers, QA engineers, and UX architects.  
> **Source Directory**: [`jaldrishti_mobile/lib/screens/`](file:///d:/jaldrishti/jaldrishti_mobile/lib/screens/)  
> **Testing Suite**: `flutter analyze` (0 errors)

---

## 1. Authentication & Onboarding Screens

### `LoginScreen` (`login_screen.dart`)
- **Purpose**: Authenticates registered farmers using phone number or username and password.
- **Backing Provider**: `AuthProvider`
- **API Calls**:
  - `POST /api/v1/auth/login`
  - `GET /api/v1/auth/me` (on success to populate profile)
- **Functional Status**: **Fully Functional**. Stores JWT tokens in `SharedPreferences`, initialises `FarmPlotProvider`, and navigates to `MainNavigationScreen`.

---

### `RegisterScreen` (`register_screen.dart`)
- **Purpose**: New farmer registration with phone number, username, and password.
- **Backing Provider**: `AuthProvider`
- **API Calls**:
  - `POST /api/v1/auth/register`
- **Functional Status**: **Fully Functional**. Automatically transitions newly registered farmers into `OnboardingSurveyScreen` to configure farm location and crops.

---

### `ForgotPasswordScreen` (`forgot_password_screen.dart`)
- **Purpose**: Two-step credential recovery via SMS OTP verification.
- **Backing Provider**: `AuthProvider`
- **API Calls**:
  - Step 1: `POST /api/v1/auth/forgot-password/request-otp` (sends `phone_or_username`)
  - Step 2: `POST /api/v1/auth/forgot-password/reset-password`
- **Functional Status**: **Fully Functional post-Phase 3 fix [F-04]**. Field name mismatch (`phone_number` $\to$ `phone_or_username`) resolved, enabling successful OTP generation and password reset.

---

### `OnboardingSurveyScreen` (`onboarding_survey_screen.dart`)
- **Purpose**: Multi-step survey capturing farmer name, district, geolocation (GPS or map picker), total farm size, crop type, and language preference.
- **Backing Provider**: `AuthProvider`
- **API Calls**:
  - `PUT /api/v1/auth/profile`
- **Functional Status**: **Fully Functional post-Phase 3 fix [F-03]**. HTTP verb corrected from `POST` to `PUT`, preventing 405 Method Not Allowed failures. Used both for initial onboarding and for profile editing via `ProfileScreen`.

---

## 2. Core Dashboard & Plot Management

### `HomeDashboardScreen` (`home_dashboard_screen.dart`)
- **Purpose**: Central operational hub. Displays current plot status, today's weather card, urgent pest banner, the primary Irrigation Recommendation Card ("Water Now" vs. "Smart Rain Hold" vs. "Soil Fine"), pump runtime dials, and quick log actions.
- **Backing Providers**: `FarmPlotProvider`, `IrrigationProvider`, `NotificationProvider`
- **API Calls**:
  - `GET /api/v1/plots/`
  - `POST /api/v1/irrigation/recommendation`
  - `POST /api/v1/irrigation/log` (quick pump run modal)
- **Functional Status**: **Fully Functional**. Caches last known telemetry to Hive on successful fetch, supporting offline cold starts.

---

### `AddEditFarmPlotScreen` (`add_edit_farm_plot_screen.dart`)
- **Purpose**: Register a new agricultural plot or update an existing plot's coordinates, pump horsepower, discharge rate (L/s), irrigation method, or soil type preset.
- **Backing Provider**: `FarmPlotProvider`
- **API Calls**:
  - `POST /api/v1/plots/` (creation mode)
  - `PUT /api/v1/plots/{plot_id}` (edit mode)
  - `DELETE /api/v1/plots/{plot_id}` (deletion mode)
- **Functional Status**: **Fully Functional**. Features integrated GPS coordinate fetching, soil texture dropdown presets, and automatic queueing in `OfflineSyncManager` when offline.

---

## 3. Analytics & Historical Insights

### `AnalyticsScreen` (`analytics_screen.dart`)
Organized as a 5-tab interface backed by `IrrigationProvider` and `FarmPlotProvider`.

| Tab File | Tab Title | Metrics Displayed | API Calls | Functional Status Post Phase 6 |
|:---------|:----------|:------------------|:----------|:-------------------------------|
| `smart_insights_tab.dart` | **Smart Insights** | Cumulative seasonal water saved (Liters), money saved (₹), avoided $\text{CO}_2$ (kg), and skipped run counts. | Uses active `IrrigationResponse` payload | **Fixed [F-23]**: Fabricated mock fallbacks (`?? 45000.0`) removed. Now renders an honest loading spinner, a calm zero-state (`0 kL saved (₹0)`), or actual verified ROI numbers. |
| `water_balance_tab.dart` | **Water Balance** | Root-zone depletion ($D_i$) gauge, Field Capacity, and Readily Available Water ($RAW$) stress threshold indicator. | Uses active `IrrigationResponse` payload | **Fully Functional**. Accurately reflects persistent daily mass balance. |
| `daily_trends_tab.dart` | **Daily Trends** | 7-day visual line charts of Reference $ET_o$ vs. Crop $ET_c$ and daily forecast precipitation bars. | Uses `daily_breakdown` from recommendation response | **Fully Functional**. Renders multi-day hydrological trends. |
| `weather_stats_tab.dart` | **Weather Stats** | Max/Min temperatures, relative humidity %, wind speed (km/h), and solar radiation ($MJ/m^2$). | Uses `weather_summary` from recommendation response | **Fully Functional**. Directly reflects Open-Meteo telemetry. |
| `history_logs_tab.dart` | **Irrigation History**| Chronological list of farmer-logged irrigation applications. | `GET /api/v1/irrigation/history/{plot_id}` | **Fully Functional**. Allows review of past water applications. |

---

## 4. Advisory & Conversational AI

### `PestAdvisoryScreen` (`pest_advisory_screen.dart`)
- **Purpose**: Displays real-time disease and insect vulnerability alerts for the active crop based on live satellite weather conditions.
- **Backing Provider**: `FarmPlotProvider` (reads active plot coordinates)
- **API Calls**:
  - `POST /api/v1/crops/pest-advisory`
- **Functional Status**: **Fully Functional post-Phase 2 fix [F-06]**. Authenticated Bearer token injected into header. Renders high/medium/low severity badges and IPM management tips.

---

### `ChatScreen` (`chat_screen.dart`)
- **Purpose**: Interactive voice and text agronomy companion powered by **JalSathi AI**. Features speech-to-text input, text-to-speech audio playback, and structured disease solution cards.
- **Backing Provider**: `ChatProvider`
- **API Calls**:
  - `POST /api/v1/chatbot/query`
- **Functional Status**: **Fully Functional post-Phase 5 rebuild**. Supports English, Bengali, and Hindi vernacular chat with multi-turn session persistence and chemical safety guardrails.

---

## 5. Profile & Settings

### `SettingsScreen` (`settings_screen.dart`)
- **Purpose**: Farmer profile settings, notification toggles, app language selector, and session logout.
- **Backing Providers**: `AuthProvider`, `ThemeProvider`, `NotificationProvider`
- **API Calls**:
  - `PUT /api/v1/auth/profile`
  - `POST /api/v1/auth/logout`
- **Functional Status Post Phase 6**:
  - **"Update Name" Modal [F-18]**: Fully wired to `AuthProvider.updateProfile()`, sending `PUT /api/v1/auth/profile`. Shows loading indicator, error alerts, and triggers the centralized 401 interceptor if the token has expired.
  - **Language Selector Dialog [F-19]**: Connected to `ThemeProvider.setLocale()`. Persists choice in `SharedPreferences`.

---

### `ProfileScreen` (`profile_screen.dart`)
- **Purpose**: View farmer details, primary farm location, and agricultural scale.
- **Backing Provider**: `AuthProvider`
- **API Calls**:
  - Delegates profile editing to `OnboardingSurveyScreen(isEditMode: true)`.
- **Functional Status**: **Fully Functional**. Correctly routes profile edits through `PUT /api/v1/auth/profile`.
