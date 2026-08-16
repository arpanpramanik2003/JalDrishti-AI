import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class ApiService {
  // Fetch Irrigation Recommendation from FastAPI Backend
  static Future<Map<String, dynamic>> fetchIrrigationRecommendation({
    required double lat,
    required double lon,
    required String cropId,
    String growthStage = 'mid_season',
    String? authToken,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConstants.irrigationEndpoint),
      headers: {
        'Content-Type': 'application/json',
        if (authToken != null && authToken.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'latitude': lat,
        'longitude': lon,
        'crop_id': cropId,
        'growth_stage': growthStage,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load irrigation data: ${response.statusCode}');
    }
  }

  // Fetch Groq RAG Chatbot Response with Farmer Context & Weather Telemetry
  static Future<Map<String, dynamic>> askChatbot({
    required String query,
    required String language,
    String? authToken,
    String? sessionId,
    String? farmerName,
    String? locationName,
    String? currentCrop,
    double? farmAreaAcres,
    double? latitude,
    double? longitude,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConstants.chatbotEndpoint),
      headers: {
        'Content-Type': 'application/json',
        if (authToken != null && authToken.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'query': query,
        'language': language,
        if (sessionId != null && sessionId.isNotEmpty) 'session_id': sessionId,
        'farmer_name': ?farmerName,
        'location_name': ?locationName,
        'current_crop': ?currentCrop,
        'farm_area_acres': ?farmAreaAcres,
        'latitude': ?latitude,
        'longitude': ?longitude,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Chatbot service error: ${response.statusCode} - ${response.body}');
    }
  }
}