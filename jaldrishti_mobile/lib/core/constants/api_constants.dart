import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;

class ApiConstants {
  // Live Production Backend Server on Render
  static const String productionBaseUrl = 'https://jaldrishti-ai.onrender.com/api/v1';

  // Local Development Backend Server (for USB / IDE debugging)
  static String get localBaseUrl {
    if (kIsWeb) return 'http://localhost:8000/api/v1';
    // Use your PC's local network IP so physical Android phones over USB / Wi-Fi can connect directly
    return 'http://10.249.147.69:8000/api/v1';
  }

  /// Initialize (No-op placeholder for app main startup compatibility)
  static Future<void> init() async {}

  /// Active Base URL:
  /// - Automatic Local USB / IDE Backend in kDebugMode (http://localhost:8000/api/v1)
  /// - Automatic Live Render Cloud in Release / Production (https://jaldrishti-ai.onrender.com/api/v1)
  static String get baseUrl {
    if (kDebugMode) {
      return localBaseUrl;
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