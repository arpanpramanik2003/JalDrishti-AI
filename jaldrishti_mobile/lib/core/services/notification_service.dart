import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../main.dart';
import '../../screens/pest_advisory_screen.dart';
import '../../screens/analytics_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    try {

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
          if (response.payload != null && response.payload!.isNotEmpty) {
            try {
              final data = jsonDecode(response.payload!);
              final type = data['type']?.toString().toLowerCase();
              final navState = navigatorKey.currentState;
              if (navState != null) {
                if (type == 'weather' || type == 'pest') {
                  navState.push(MaterialPageRoute(builder: (_) => const PestAdvisoryScreen()));
                } else if (type == 'irrigation') {
                  navState.push(MaterialPageRoute(builder: (_) => const AnalyticsScreen()));
                }
              }
            } catch (e) {
              debugPrint('Error handling notification tap navigation: $e');
            }
          }
        },
      );

      // Request Android 13+ Notification Permission
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
    }
  }

  // Show immediate Push Notification
  Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await init();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'jaldrishti_irrigation_channel',
      'Irrigation & Field Alerts',
      channelDescription: 'Notifications for JalDrishti smart irrigation recommendations and weather alerts.',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF0284C7),
      styleInformation: BigTextStyleInformation(''),
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        platformDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }
}
