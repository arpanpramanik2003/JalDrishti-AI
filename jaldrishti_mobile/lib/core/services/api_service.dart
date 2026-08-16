import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic body;

  ApiException(this.statusCode, this.message, {this.body});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  // Core Helper: Send HTTP Request with Headers, Token Injection, and Timeout
  static Future<dynamic> _sendRequest(
    String method,
    String url, {
    String? token,
    Map<String, dynamic>? body,
    Map<String, String>? customHeaders,
  }) async {
    final uri = Uri.parse(url);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      ...?customHeaders,
    };

    http.Response response;
    try {
      final bodyJson = body != null ? jsonEncode(body) : null;
      switch (method.toUpperCase()) {
        case 'POST':
          response = await http.post(uri, headers: headers, body: bodyJson).timeout(ApiConstants.httpTimeout);
          break;
        case 'PUT':
          response = await http.put(uri, headers: headers, body: bodyJson).timeout(ApiConstants.httpTimeout);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers).timeout(ApiConstants.httpTimeout);
          break;
        case 'GET':
        default:
          response = await http.get(uri, headers: headers).timeout(ApiConstants.httpTimeout);
          break;
      }
    } catch (e) {
      debugPrint('Network error during $method $url: $e');
      throw ApiException(0, 'Cannot connect to JalDrishti server.');
    }

    dynamic decodedData;
    if (response.body.isNotEmpty) {
      try {
        decodedData = jsonDecode(response.body);
      } catch (_) {
        decodedData = response.body;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decodedData;
    } else {
      String detailMsg = 'Server returned HTTP ${response.statusCode}';
      if (decodedData is Map && decodedData.containsKey('detail')) {
        detailMsg = decodedData['detail'].toString();
      }
      throw ApiException(response.statusCode, detailMsg, body: decodedData);
    }
  }

  // =========================================================================
  // AUTHENTICATION ENDPOINTS
  // =========================================================================

  static Future<Map<String, dynamic>> register({
    required String username,
    required String phoneNumber,
    required String password,
  }) async {
    return await _sendRequest('POST', ApiConstants.registerEndpoint, body: {
      'username': username,
      'phone_number': phoneNumber,
      'password': password,
    });
  }

  static Future<Map<String, dynamic>> login({
    required String loginIdentifier,
    required String password,
  }) async {
    return await _sendRequest('POST', ApiConstants.loginEndpoint, body: {
      'login_identifier': loginIdentifier,
      'password': password,
    });
  }

  static Future<Map<String, dynamic>> fetchProfile(String token) async {
    return await _sendRequest('GET', ApiConstants.meEndpoint, token: token);
  }

  static Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    return await _sendRequest('POST', '${ApiConstants.baseUrl}/auth/refresh', body: {
      'refresh_token': refreshToken,
    });
  }

  static Future<void> logout(String token) async {
    try {
      await _sendRequest('POST', '${ApiConstants.baseUrl}/auth/logout', token: token);
    } catch (e) {
      debugPrint('Logout backend error: $e');
    }
  }

  static Future<Map<String, dynamic>> requestPasswordResetOtp(String phoneNumber) async {
    return await _sendRequest('POST', ApiConstants.requestOtpEndpoint, body: {
      'phone_number': phoneNumber,
    });
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String phoneNumber,
    required String otpCode,
    required String newPassword,
  }) async {
    return await _sendRequest('POST', ApiConstants.resetPasswordEndpoint, body: {
      'phone_number': phoneNumber,
      'otp_code': otpCode,
      'new_password': newPassword,
    });
  }

  static Future<Map<String, dynamic>> requestPhoneUpdateOtp({
    required String newPhoneNumber,
    required String token,
  }) async {
    return await _sendRequest('POST', ApiConstants.requestPhoneUpdateOtpEndpoint, token: token, body: {
      'new_phone_number': newPhoneNumber,
    });
  }

  static Future<Map<String, dynamic>> verifyPhoneUpdateOtp({
    required String newPhoneNumber,
    required String otpCode,
    required String token,
  }) async {
    return await _sendRequest('POST', ApiConstants.verifyPhoneUpdateOtpEndpoint, token: token, body: {
      'new_phone_number': newPhoneNumber,
      'otp_code': otpCode,
    });
  }

  static Future<Map<String, dynamic>> updateProfile({
    required Map<String, dynamic> profileData,
    required String token,
  }) async {
    return await _sendRequest('POST', ApiConstants.updateProfileEndpoint, token: token, body: profileData);
  }

  static Future<void> updateFcmToken({
    required String fcmToken,
    required String token,
  }) async {
    await _sendRequest('POST', ApiConstants.updateFcmTokenEndpoint, token: token, body: {
      'fcm_token': fcmToken,
    });
  }

  // =========================================================================
  // FARM PLOT ENDPOINTS
  // =========================================================================

  static Future<List<dynamic>> fetchPlots(String token, {int limit = 50, int offset = 0}) async {
    final url = '${ApiConstants.baseUrl}/plots/?limit=$limit&offset=$offset';
    final res = await _sendRequest('GET', url, token: token);
    return res is List ? res : [];
  }

  static Future<Map<String, dynamic>> createPlot({
    required Map<String, dynamic> plotData,
    required String token,
  }) async {
    return await _sendRequest('POST', '${ApiConstants.baseUrl}/plots/', token: token, body: plotData);
  }

  static Future<Map<String, dynamic>> updatePlot({
    required int plotId,
    required Map<String, dynamic> plotData,
    required String token,
  }) async {
    return await _sendRequest('PUT', '${ApiConstants.baseUrl}/plots/$plotId', token: token, body: plotData);
  }

  static Future<Map<String, dynamic>> setPrimaryPlot({
    required int plotId,
    required String token,
  }) async {
    return await _sendRequest('PUT', '${ApiConstants.baseUrl}/plots/$plotId/set-primary', token: token);
  }

  static Future<void> deletePlot({
    required int plotId,
    required String token,
  }) async {
    await _sendRequest('DELETE', '${ApiConstants.baseUrl}/plots/$plotId', token: token);
  }

  // =========================================================================
  // IRRIGATION & CROP ENDPOINTS
  // =========================================================================

  static Future<List<dynamic>> fetchCrops() async {
    final res = await _sendRequest('GET', '${ApiConstants.baseUrl}/crops/all');
    return res is List ? res : [];
  }

  static Future<Map<String, dynamic>> fetchIrrigationRecommendation({
    required Map<String, dynamic> payload,
    String? token,
  }) async {
    return await _sendRequest('POST', ApiConstants.irrigationEndpoint, token: token, body: payload);
  }

  static Future<Map<String, dynamic>> logIrrigationEvent({
    required Map<String, dynamic> payload,
    required String token,
  }) async {
    return await _sendRequest('POST', '${ApiConstants.baseUrl}/irrigation/log', token: token, body: payload);
  }

  static Future<List<dynamic>> fetchIrrigationHistory({
    required int plotId,
    required String token,
    int limit = 50,
    int offset = 0,
  }) async {
    final url = '${ApiConstants.baseUrl}/irrigation/history/$plotId?limit=$limit&offset=$offset';
    final res = await _sendRequest('GET', url, token: token);
    return res is List ? res : [];
  }

  // =========================================================================
  // CHATBOT & PEST ADVISORY ENDPOINTS
  // =========================================================================

  static Future<Map<String, dynamic>> askChatbot({
    required Map<String, dynamic> payload,
    String? token,
  }) async {
    return await _sendRequest('POST', ApiConstants.chatbotEndpoint, token: token, body: payload);
  }

  static Future<Map<String, dynamic>> fetchPestAdvisory({
    required Map<String, dynamic> payload,
    String? token,
  }) async {
    return await _sendRequest('POST', '${ApiConstants.baseUrl}/crops/pest-advisory', token: token, body: payload);
  }
}