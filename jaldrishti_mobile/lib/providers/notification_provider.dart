import 'package:flutter/material.dart';
import '../core/services/notification_service.dart';
import '../core/services/offline_cache_service.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String timestamp;
  final String type; // 'irrigation', 'weather', 'pump'
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'timestamp': timestamp,
        'type': type,
        'isRead': isRead,
      };

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
        id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: json['title'] ?? '',
        body: json['body'] ?? '',
        timestamp: json['timestamp'] ?? '',
        type: json['type'] ?? 'irrigation',
        isRead: json['isRead'] ?? false,
      );
}

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _feed = [];
  bool _irrigationAlertsEnabled = true;
  bool _weatherAlertsEnabled = true;
  bool _pumpRemindersEnabled = true;

  List<NotificationModel> get feed => List.unmodifiable(_feed);
  int get unreadCount => _feed.where((n) => !n.isRead).length;

  bool get irrigationAlertsEnabled => _irrigationAlertsEnabled;
  bool get weatherAlertsEnabled => _weatherAlertsEnabled;
  bool get pumpRemindersEnabled => _pumpRemindersEnabled;

  NotificationProvider() {
    _initNotificationProvider();
  }

  Future<void> _initNotificationProvider() async {
    // 1. Initialize Native Push Notification Service
    await NotificationService().init();

    // 2. Load Notification Settings
    final settings = await OfflineCacheService.loadNotificationSettings();
    _irrigationAlertsEnabled = settings['irrigationAlerts'] ?? true;
    _weatherAlertsEnabled = settings['weatherAlerts'] ?? true;
    _pumpRemindersEnabled = settings['pumpReminders'] ?? true;

    // 3. Load Notification Feed History
    final feedData = await OfflineCacheService.loadNotificationFeed();
    _feed = feedData.map((item) => NotificationModel.fromJson(item)).toList();
    notifyListeners();
  }

  // Toggle Notification Setting
  Future<void> toggleSetting(String key, bool val) async {
    if (key == 'irrigationAlerts') _irrigationAlertsEnabled = val;
    if (key == 'weatherAlerts') _weatherAlertsEnabled = val;
    if (key == 'pumpReminders') _pumpRemindersEnabled = val;
    notifyListeners();

    await OfflineCacheService.saveNotificationSettings({
      'irrigationAlerts': _irrigationAlertsEnabled,
      'weatherAlerts': _weatherAlertsEnabled,
      'pumpReminders': _pumpRemindersEnabled,
    });
  }

  // Add Notification to Feed & Trigger Push Notification
  Future<void> addNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    // Check if alerts are enabled for this type
    if (type == 'irrigation' && !_irrigationAlertsEnabled) return;
    if (type == 'weather' && !_weatherAlertsEnabled) return;
    if (type == 'pump' && !_pumpRemindersEnabled) return;

    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} - ${now.day}/${now.month}";

    final newNotification = NotificationModel(
      id: now.millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: timeStr,
      type: type,
      isRead: false,
    );

    // Prevent exact duplicate notifications
    if (_feed.isNotEmpty && _feed.first.title == title && _feed.first.body == body) {
      return;
    }

    _feed.insert(0, newNotification);
    notifyListeners();

    // Persist Feed History
    await OfflineCacheService.saveNotificationFeed(_feed.map((n) => n.toJson()).toList());

    // Trigger Device Push Notification
    await NotificationService().showNotification(
      id: now.millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
    );
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    for (var n in _feed) {
      n.isRead = true;
    }
    notifyListeners();
    await OfflineCacheService.saveNotificationFeed(_feed.map((n) => n.toJson()).toList());
  }

  // Clear Feed
  Future<void> clearFeed() async {
    _feed.clear();
    notifyListeners();
    await OfflineCacheService.saveNotificationFeed([]);
  }
}
