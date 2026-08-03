import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../core/services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isSending = false;
  String _selectedLanguage = 'English'; // Options: English, Bengali, Hindi

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isSending => _isSending;
  String get selectedLanguage => _selectedLanguage;

  void setLanguage(String lang) {
    _selectedLanguage = lang;
    notifyListeners();
  }

  Future<void> sendMessage({
    required String text,
    String? farmerName,
    String? locationName,
    String? currentCrop,
    double? farmAreaAcres,
  }) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
      language: _selectedLanguage,
    );

    _messages.add(userMessage);
    _isSending = true;
    notifyListeners();

    try {
      final responseText = await ApiService.askChatbot(
        query: text.trim(),
        language: _selectedLanguage,
        farmerName: farmerName,
        locationName: locationName,
        currentCrop: currentCrop,
        farmAreaAcres: farmAreaAcres,
      );

      final botMessage = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
        language: _selectedLanguage,
      );

      _messages.add(botMessage);
    } catch (e) {
      final errorMessage = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: '❌ Could not reach JalSathi AI. Please check your internet or server connection.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(errorMessage);
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  void clearChat() {
    _messages.clear();
    notifyListeners();
  }
}