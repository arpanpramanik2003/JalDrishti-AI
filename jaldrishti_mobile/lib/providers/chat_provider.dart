import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/chat_message.dart';
import '../core/services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isSending = false;
  String _selectedLanguage = 'English'; // Options: English, Bengali, Hindi

  // Text-To-Speech (TTS) Engine
  final FlutterTts _tts = FlutterTts();
  String? _currentlySpeakingId;

  // Speech-To-Text (STT) Engine
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  bool _sttAvailable = false;
  String _recognizedText = '';
  double _soundLevel = 0.0;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isSending => _isSending;
  String get selectedLanguage => _selectedLanguage;

  String? get currentlySpeakingId => _currentlySpeakingId;
  bool get isListening => _isListening;
  bool get sttAvailable => _sttAvailable;
  String get recognizedText => _recognizedText;
  double get soundLevel => _soundLevel;

  ChatProvider() {
    _initTts();
    _initStt();
  }

  void _initTts() {
    _tts.setCompletionHandler(() {
      _currentlySpeakingId = null;
      notifyListeners();
    });
    _tts.setErrorHandler((msg) {
      _currentlySpeakingId = null;
      notifyListeners();
    });
  }

  Future<void> _initStt() async {
    try {
      _sttAvailable = await _speechToText.initialize(
        onError: (val) {
          _isListening = false;
          notifyListeners();
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            notifyListeners();
          }
        },
      );
    } catch (_) {
      _sttAvailable = false;
    }
    notifyListeners();
  }

  void setLanguage(String lang) {
    _selectedLanguage = lang;
    stopSpeaking();
    notifyListeners();
  }

  // --------------------------------------------------------
  // Text To Speech (Audio Voice Output)
  // --------------------------------------------------------
  Future<void> speakMessage(ChatMessage message) async {
    if (_currentlySpeakingId == message.id) {
      await stopSpeaking();
      return;
    }

    await stopSpeaking();
    _currentlySpeakingId = message.id;
    notifyListeners();

    String langCode = 'en-US';
    if (_selectedLanguage == 'Bengali') {
      langCode = 'bn-IN';
    } else if (_selectedLanguage == 'Hindi') {
      langCode = 'hi-IN';
    }

    await _tts.setLanguage(langCode);
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.45); // Natural relaxed speed for farmers

    // Clean markdown characters before passing to speech synthesizer
    final cleanText = message.text
        .replaceAll(RegExp(r'[\*\#\_\`\-]'), '')
        .replaceAll(RegExp(r'\n+'), '. ');

    await _tts.speak(cleanText);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
    _currentlySpeakingId = null;
    notifyListeners();
  }

  // --------------------------------------------------------
  // Speech To Text (Microphone Voice Input)
  // --------------------------------------------------------
  Future<void> startListening(Function(String text) onSpeechResult) async {
    if (!_sttAvailable) {
      await _initStt();
    }

    if (!_sttAvailable) return;

    _isListening = true;
    _recognizedText = '';
    notifyListeners();

    String localeId = 'en_IN';
    if (_selectedLanguage == 'Bengali') {
      localeId = 'bn_IN';
    } else if (_selectedLanguage == 'Hindi') {
      localeId = 'hi_IN';
    }

    await _speechToText.listen(
      listenOptions: stt.SpeechListenOptions(
        localeId: localeId,
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        onDevice: false,
      ),
      onResult: (val) {
        _recognizedText = val.recognizedWords;
        onSpeechResult(_recognizedText);
        notifyListeners();
      },
      onSoundLevelChange: (level) {
        _soundLevel = level;
        notifyListeners();
      },
    );
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    _isListening = false;
    _soundLevel = 0.0;
    notifyListeners();
  }

  String? _sessionId;
  String? get sessionId => _sessionId;

  // --------------------------------------------------------
  // Chat Messaging Logic
  // --------------------------------------------------------
  Future<void> sendMessage({
    required String text,
    String? authToken,
    String? farmerName,
    String? locationName,
    String? currentCrop,
    double? farmAreaAcres,
    double? latitude,
    double? longitude,
  }) async {
    if (text.trim().isEmpty) return;

    stopSpeaking();

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
      final resData = await ApiService.askChatbot(
        query: text.trim(),
        language: _selectedLanguage,
        authToken: authToken,
        sessionId: _sessionId,
        farmerName: farmerName,
        locationName: locationName,
        currentCrop: currentCrop,
        farmAreaAcres: farmAreaAcres,
        latitude: latitude,
        longitude: longitude,
      );

      _sessionId = resData['session_id'] ?? _sessionId;
      final responseText = resData['response'] ?? 'No response received.';

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
    stopSpeaking();
    _sessionId = null;
    _messages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _tts.stop();
    _speechToText.stop();
    super.dispose();
  }
}