import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConstants {
  // Live Production Backend Server on Render
  static const String productionBaseUrl = 'https://jaldrishti-ai.onrender.com/api/v1';

  // Local Network IP for USB / LAN debugging
  static const String defaultLocalIp = '10.249.147.69';

  // Default timeout duration for HTTP requests (45s to accommodate Render cold boot)
  static const Duration httpTimeout = Duration(seconds: 45);

  static String _activeMode = 'cloud'; // Default to Cloud Render backend
  static String _customUrl = '';

  // Local Development Backend Server
  static String get localBaseUrl {
    if (kIsWeb) return 'http://localhost:8000/api/v1';
    return 'http://$defaultLocalIp:8000/api/v1';
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
  /// - Cloud: https://jaldrishti-ai.onrender.com/api/v1
  /// - Local: http://10.249.147.69:8000/api/v1
  /// - Custom: user specified URL
  static String get baseUrl {
    if (_activeMode == 'local') {
      return localBaseUrl;
    } else if (_activeMode == 'custom' && _customUrl.trim().isNotEmpty) {
      return _customUrl.trim();
    }
    return productionBaseUrl;
  }

  static String get registerEndpoint => '$baseUrl/auth/register';
  static String get loginEndpoint => '$baseUrl/auth/login';
  static String get meEndpoint => '$baseUrl/auth/me';
  static String get updateProfileEndpoint => '$baseUrl/auth/profile';

  static String get requestOtpEndpoint => '$baseUrl/auth/forgot-password/request-otp';
  static String get resetPasswordEndpoint => '$baseUrl/auth/forgot-password/reset-password';

  static String get requestPhoneUpdateOtpEndpoint => '$baseUrl/auth/request-phone-update-otp';
  static String get verifyPhoneUpdateOtpEndpoint => '$baseUrl/auth/verify-phone-update-otp';

  static String get irrigationEndpoint => '$baseUrl/irrigation/recommendation';
  static String get chatbotEndpoint => '$baseUrl/chatbot/query';
}