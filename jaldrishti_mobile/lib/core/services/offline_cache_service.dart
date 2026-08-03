import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineCacheService {
  static const String _keyIrrigationCachePrefix = 'cache_irrigation_plot_';
  static const String _keyPlotsListCache = 'cache_plots_list';
  static const String _keyNotificationSettings = 'cache_notification_settings';
  static const String _keyNotificationFeed = 'cache_notification_feed';

  // Save Irrigation Recommendation Data for a specific plot
  static Future<void> cacheIrrigationData(int plotId, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_keyIrrigationCachePrefix$plotId', jsonEncode(data));
      await prefs.setString('${_keyIrrigationCachePrefix}last_updated', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error caching irrigation data: $e');
    }
  }

  // Load Cached Irrigation Recommendation Data for a plot
  static Future<Map<String, dynamic>?> getCachedIrrigationData(int plotId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString('$_keyIrrigationCachePrefix$plotId');
      if (rawJson != null && rawJson.isNotEmpty) {
        return jsonDecode(rawJson) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error reading cached irrigation data: $e');
    }
    return null;
  }

  // Save Plots List JSON
  static Future<void> cachePlotsList(List<dynamic> plotsJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPlotsListCache, jsonEncode(plotsJson));
    } catch (e) {
      debugPrint('Error caching plots list: $e');
    }
  }

  // Get Cached Plots List
  static Future<List<dynamic>?> getCachedPlotsList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_keyPlotsListCache);
      if (rawJson != null && rawJson.isNotEmpty) {
        return jsonDecode(rawJson) as List<dynamic>;
      }
    } catch (e) {
      debugPrint('Error reading cached plots list: $e');
    }
    return null;
  }

  // Save Notification Feed History
  static Future<void> saveNotificationFeed(List<Map<String, dynamic>> feed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyNotificationFeed, jsonEncode(feed));
    } catch (e) {
      debugPrint('Error saving notification feed: $e');
    }
  }

  // Load Notification Feed History
  static Future<List<Map<String, dynamic>>> loadNotificationFeed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_keyNotificationFeed);
      if (rawJson != null && rawJson.isNotEmpty) {
        final List<dynamic> list = jsonDecode(rawJson);
        return list.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (e) {
      debugPrint('Error loading notification feed: $e');
    }
    return [];
  }

  // Save Notification Settings (Toggles)
  static Future<void> saveNotificationSettings(Map<String, bool> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyNotificationSettings, jsonEncode(settings));
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
    }
  }

  // Load Notification Settings
  static Future<Map<String, bool>> loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_keyNotificationSettings);
      if (rawJson != null && rawJson.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(rawJson);
        return decoded.map((key, value) => MapEntry(key, value as bool));
      }
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }
    return {
      'irrigationAlerts': true,
      'weatherAlerts': true,
      'pumpReminders': true,
    };
  }
}
