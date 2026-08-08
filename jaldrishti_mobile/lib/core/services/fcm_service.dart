import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'notification_service.dart';

// Background message handler (Must be a top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint('[FCM Background] Handling background message ID: ${message.messageId}');
  } catch (e) {
    debugPrint('[FCM Background] Error initializing Firebase in background: $e');
  }
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  bool _isInitialized = false;

  /// Initialize Firebase Messaging & Listeners
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize Firebase App
      await Firebase.initializeApp();
      debugPrint('[FCM] Firebase App initialized successfully.');

      // 2. Set background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Request Notification Permissions (Android 13+ & iOS)
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('[FCM] User notification permission status: ${settings.authorizationStatus}');

      // 4. Foreground Notification Presentation Options
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 5. Listen for Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM Foreground] Received message: ${message.notification?.title}');
        final title = message.notification?.title ?? 'JalDrishti Alert';
        final body = message.notification?.body ?? 'New weather advisory received.';

        // Delegate to local notification service for heads-up banner
        NotificationService().showNotification(
          title: title,
          body: body,
          payload: jsonEncode(message.data),
        );
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('[FCM Notice] Firebase Messaging not initialized yet: $e. (Requires google-services.json configuration)');
    }
  }

  /// Syncs FCM Device Token with Backend Database for targeted user push notifications
  static Future<void> syncDeviceTokenWithBackend(String authToken) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      debugPrint('[FCM] Current FCM Device Token: ${token.substring(0, 15)}...');

      final response = await http.post(
        Uri.parse(ApiConstants.updateFcmTokenEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'fcm_token': token}),
      );

      if (response.statusCode == 200) {
        debugPrint('[FCM] Successfully registered device token with backend database.');
      } else {
        debugPrint('[FCM] Failed to sync device token: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[FCM] Token sync notice: $e');
    }
  }
}
