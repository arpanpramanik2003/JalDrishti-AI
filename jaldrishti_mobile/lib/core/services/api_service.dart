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
  }) async {
    final response = await http.post(
      Uri.parse(ApiConstants.irrigationEndpoint),
      headers: {'Content-Type': 'application/json'},
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

  // Fetch Groq RAG Chatbot Response with Farmer Context
  static Future<String> askChatbot({
    required String query,
    required String language,
    String? farmerName,
    String? locationName,
    String? currentCrop,
    double? farmAreaAcres,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConstants.chatbotEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': query,
        'language': language,
        if (farmerName != null) 'farmer_name': farmerName,
        if (locationName != null) 'location_name': locationName,
        if (currentCrop != null) 'current_crop': currentCrop,
        if (farmAreaAcres != null) 'farm_area_acres': farmAreaAcres,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response'] ?? 'No response received.';
    } else {
      throw Exception('Chatbot service error: ${response.statusCode}');
    }
  }
}