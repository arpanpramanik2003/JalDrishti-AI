# State Management and Providers Reference

> **Audience**: Flutter application developers and mobile software architects.  
> **Source Directory**: [`jaldrishti_mobile/lib/providers/`](file:///d:/jaldrishti/jaldrishti_mobile/lib/providers/)  
> **Framework**: `package:provider/provider.dart` (ChangeNotifier architecture)

---

## 1. Provider Ecosystem Architecture

JalDrishti employs a decoupled ChangeNotifier architecture. Each provider owns a dedicated operational domain, coordinates with `ApiService` for remote network I/O, caches data in `Hive`, and notifies subscribed UI widgets of state changes:

```
                          +-------------------+
                          |    MaterialApp    |
                          +---------+---------+
                                    |
          +-------------------------+-------------------------+
          |                         |                         |
+---------v---------+     +---------v---------+     +---------v---------+
|   ThemeProvider   |     |   AuthProvider    |     | FarmPlotProvider  |
| - Dark/Light mode |     | - JWT Tokens      |     | - Plot Collection |
| - Active Locale   |     | - UserProfile     |     | - Selected Plot   |
+-------------------+     +---------+---------+     +---------+---------+
                                    |                         |
          +-------------------------+                         |
          |                                                   |
+---------v---------+     +-------------------+     +---------v---------+
| IrrigationProvider|     |   ChatProvider    |     |NotificationProv.  |
| - Advisory Data   |     | - Chat Messages   |     | - FCM Push Feed   |
| - Daily Breakdown |     | - Voice TTS/STT   |     | - Alert Settings  |
+-------------------+     +-------------------+     +-------------------+
```

---

## 2. Comprehensive Provider Specifications

### 1. `AuthProvider` (`auth_provider.dart`)
- **State Owned**:
  - `User? _user`: Active authenticated user entity with embedded `UserProfileModel`.
  - `String? _token`: Active HS256 JWT access token.
  - `String? _refreshToken`: Long-lived refresh token for token rotation.
  - `bool _isLoading`: Authentication transaction state flag.
  - `String? _errorMessage`: Last surfaced network or validation error.
- **Triggers for `notifyListeners()`**:
  - `login()`: Invoked on credential submission, token storage, and failure.
  - `register()`: Invoked during onboarding account creation.
  - `logout()`: Clears tokens, in-memory user objects, and resets auth state.
  - `updateProfile()`: Invoked when profile attributes are updated via `PUT /api/v1/auth/profile`.
- **Phase 3 Interceptor Integration**:
  Exposes `refreshSession()` which calls `POST /api/v1/auth/refresh`. Bound to `ApiService.onTokenRefreshNeeded` to perform silent token rotation during background HTTP 401 recovery. Exposes `forceLogout()` bound to `ApiService.onForceLogout`.

---

### 2. `FarmPlotProvider` (`farm_plot_provider.dart`)
- **State Owned**:
  - `List<FarmPlotModel> _plots`: Complete list of plots owned by the farmer.
  - `FarmPlotModel? _selectedPlot`: The active plot driving dashboard analytics.
  - `bool _isLoading`: Network fetch state.
- **Triggers for `notifyListeners()`**:
  - `fetchPlots()`: Populates plot list from backend (or loads Hive cache if offline).
  - `selectPlot()`: Switches the active dashboard plot context.
  - `createPlot()`, `updatePlot()`, `deletePlot()`: Modifies plot list and triggers re-rendering.
  - `setPrimaryPlot()`: Toggles the default primary plot marker.

---

### 3. `IrrigationProvider` (`irrigation_provider.dart`)
- **State Owned**:
  - `IrrigationResponseModel? _recommendation`: Current decision engine response (ETo, ETc, pump hours, rain hold, ROI).
  - `List<IrrigationLogModel> _logs`: Historical irrigation records for the active plot.
  - `bool _isLoading`: Hydrological computation network spinner.
- **Triggers for `notifyListeners()`**:
  - `fetchRecommendation(FarmPlotModel plot)`: Dispatches `POST /api/v1/irrigation/recommendation`. Updates dashboard cards and analytics tabs.
  - `logIrrigationEvent(...)`: Dispatches `POST /api/v1/irrigation/log` and refreshes recommendation.
  - `fetchHistory(int plotId)`: Populates historical log entries.

---

### 4. `ChatProvider` (`chat_provider.dart`)
- **State Owned**:
  - `List<ChatMessageModel> _messages`: Chronological chat turn history for the active session.
  - `String _sessionId`: UUID tracking current multi-turn dialogue.
  - `bool _isSending`: Network generation spinner.
  - `bool _isListening`: Speech-to-Text microphone recording status.
  - `bool _isSpeaking`: Text-to-Speech audio playback status.
- **Triggers for `notifyListeners()`**:
  - `sendMessage(String query)`: Optimistically adds user bubble, sends payload to `POST /api/v1/chatbot/query`, appends assistant reply, and triggers optional voice playback.
  - `clearChat()`: Resets conversation messages and generates a new session UUID.

---

### 5. `NotificationProvider` (`notification_provider.dart`)
- **State Owned**:
  - `List<NotificationModel> _notifications`: In-app alert feed (weather warnings, pest outbreaks, rain hold notices).
  - `bool _pushEnabled`: Farmer preference toggle for FCM push notifications.
  - `int _unreadCount`: Unread badge count displayed on bottom navigation bar.
- **Triggers for `notifyListeners()`**:
  - `addNotification()`: Appends an incoming background push notification.
  - `markAsRead()`, `markAllAsRead()`: Decrements unread counter and saves to Hive.
  - `togglePushNotifications()`: Updates remote FCM token preferences.

---

### 6. `ThemeProvider` (`theme_provider.dart`)
- **State Owned**:
  - `ThemeMode _themeMode`: Light, dark, or system mode setting.
  - `Locale _locale`: Active language locale (`Locale('en')`, `Locale('bn')`, `Locale('hi')`).
- **Triggers for `notifyListeners()`**:
  - `setThemeMode(ThemeMode mode)`: Updates UI brightness and saves to `SharedPreferences`.
  - `setLocale(Locale locale)` **[Phase 6 Fix [F-19]]**: Changes active application language, triggers rebuild of `MaterialApp`, and persists preference in `SharedPreferences`.
