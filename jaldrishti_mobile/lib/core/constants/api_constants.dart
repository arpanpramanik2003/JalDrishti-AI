import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConstants {
  // Live Production Backend Server default URL or build-time --dart-define override
  static const String envConfiguredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://jaldrishti-ai.onrender.com/api/v1',
  );

  // Default timeout duration for HTTP requests
  static const Duration httpTimeout = Duration(seconds: 45);

  static String _activeMode = 'cloud'; // Default to Cloud Render backend
  static String _customUrl = '';

  // Local Development Backend Server
  // - 10.0.2.2 for Android Studio Emulator
  // - 127.0.0.1 for Physical USB Debugging (via adb reverse) / Web / iOS Simulator
  static String get localBaseUrl {
    if (_customUrl.trim().isNotEmpty) return _customUrl.trim();
    if (kIsWeb) return 'http://localhost:8000/api/v1';
    return 'http://10.0.2.2:8000/api/v1';
  }

  /// Initialize backend settings from SharedPreferences on app boot
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _activeMode = prefs.getString('backend_mode') ?? 'cloud';
      _customUrl = prefs.getString('custom_backend_url') ?? '';
    } catch (_) {
      _activeMode = 'cloud';
    }
  }

  static String get activeMode => _activeMode;
  static String get customUrl => _customUrl;

  /// Update backend mode dynamically at runtime
  static Future<void> setBackendMode(String mode, {String? customUrl}) async {
    _activeMode = mode;
    if (customUrl != null) _customUrl = customUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('backend_mode', mode);
      if (customUrl != null) {
        await prefs.setString('custom_backend_url', customUrl);
      }
    } catch (_) {}
  }

  /// Active Base URL:
  /// - Cloud: envConfiguredBaseUrl
  /// - Local: localBaseUrl
  /// - Custom: user specified URL
  static String get baseUrl {
    if (_activeMode == 'local') {
      return localBaseUrl;
    } else if (_activeMode == 'custom' && _customUrl.trim().isNotEmpty) {
      return _customUrl.trim();
    }
    return envConfiguredBaseUrl;
  }

  static String get registerEndpoint => '$baseUrl/auth/register';
  static String get loginEndpoint => '$baseUrl/auth/login';
  static String get meEndpoint => '$baseUrl/auth/me';
  static String get updateProfileEndpoint => '$baseUrl/auth/profile';
  static String get updateFcmTokenEndpoint => '$baseUrl/auth/update-fcm-token';

  static String get requestOtpEndpoint => '$baseUrl/auth/forgot-password/request-otp';
  static String get resetPasswordEndpoint => '$baseUrl/auth/forgot-password/reset-password';

  static String get requestPhoneUpdateOtpEndpoint => '$baseUrl/auth/request-phone-update-otp';
  static String get verifyPhoneUpdateOtpEndpoint => '$baseUrl/auth/verify-phone-update-otp';

  static String get irrigationEndpoint => '$baseUrl/irrigation/recommendation';
  static String get chatbotEndpoint => '$baseUrl/chatbot/query';
}