import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConstants {
  static const String _prefKey = 'custom_api_base_url';

  // Support environment configuration via --dart-define=API_BASE_URL=http://...
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String _customBaseUrl = '';

  /// Initialize stored custom base URL from SharedPreferences
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _customBaseUrl = prefs.getString(_prefKey) ?? '';
    } catch (_) {
      // Fallback silently if storage unavailable
    }
  }

  /// Dynamic platform-aware default URL
  static String get defaultBaseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (!kIsWeb && Platform.isAndroid) {
      // 127.0.0.1 is used for physical Android devices via USB 'adb reverse tcp:8000 tcp:8000'
      // 10.0.2.2 is host loopback for Android Virtual Device (Emulator)
      return 'http://127.0.0.1:8000/api/v1';
    }
    return 'http://127.0.0.1:8000/api/v1';
  }

  /// Active Base URL (custom saved > default platform)
  static String get baseUrl {
    if (_customBaseUrl.isNotEmpty) {
      return _customBaseUrl;
    }
    return defaultBaseUrl;
  }

  /// Format & save custom Base URL or Host IP
  static Future<void> setBaseUrl(String input) async {
    String formatted = input.trim();
    if (formatted.isNotEmpty) {
      // 1. Ensure scheme (http:// or https://)
      if (!formatted.startsWith('http://') && !formatted.startsWith('https://')) {
        formatted = 'http://$formatted';
      }

      // 2. Format port & path
      Uri? parsedUri = Uri.tryParse(formatted);
      if (parsedUri != null) {
        String host = parsedUri.host;
        int port = parsedUri.port;
        String scheme = parsedUri.scheme.isNotEmpty ? parsedUri.scheme : 'http';
        String path = parsedUri.path;

        // If port is default or not explicitly specified
        if (!formatted.contains(':$port') && !formatted.contains(':8000') && !formatted.contains(':80') && !formatted.contains(':443')) {
          if (host.isNotEmpty) {
            if (path.isEmpty || path == '/') {
              path = '/api/v1';
            }
            formatted = '$scheme://$host:8000$path';
          }
        }
      }

      // 3. Ensure path ends with /api/v1
      if (!formatted.contains('/api/v1')) {
        if (formatted.endsWith('/')) {
          formatted = '${formatted}api/v1';
        } else {
          formatted = '$formatted/api/v1';
        }
      }
    }

    _customBaseUrl = formatted;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (formatted.isEmpty) {
        await prefs.remove(_prefKey);
      } else {
        await prefs.setString(_prefKey, formatted);
      }
    } catch (_) {}
  }

  static Future<void> resetToDefault() async {
    await setBaseUrl('');
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