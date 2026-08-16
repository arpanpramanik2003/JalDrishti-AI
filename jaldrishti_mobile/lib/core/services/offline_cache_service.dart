import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineCacheService {
  static const String cacheBoxName = 'jaldrishti_cache';
  static const String _keyIrrigationCachePrefix = 'cache_irrigation_plot_';
  static const String _keyPlotsListCache = 'cache_plots_list';
  static const String _keyNotificationSettings = 'cache_notification_settings';
  static const String _keyNotificationFeed = 'cache_notification_feed';

  static Box<dynamic> get _box => Hive.box(cacheBoxName);

  /// Migrate legacy SharedPreferences data to Hive on initial boot
  static Future<void> migrateSharedPreferencesToHive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_keyPlotsListCache)) {
        final rawPlots = prefs.getString(_keyPlotsListCache);
        if (rawPlots != null && rawPlots.isNotEmpty) {
          await _box.put(_keyPlotsListCache, jsonDecode(rawPlots));
        }
        await prefs.remove(_keyPlotsListCache);
      }
      if (prefs.containsKey(_keyNotificationFeed)) {
        final rawFeed = prefs.getString(_keyNotificationFeed);
        if (rawFeed != null && rawFeed.isNotEmpty) {
          await _box.put(_keyNotificationFeed, jsonDecode(rawFeed));
        }
        await prefs.remove(_keyNotificationFeed);
      }
      if (prefs.containsKey(_keyNotificationSettings)) {
        final rawSettings = prefs.getString(_keyNotificationSettings);
        if (rawSettings != null && rawSettings.isNotEmpty) {
          await _box.put(_keyNotificationSettings, jsonDecode(rawSettings));
        }
        await prefs.remove(_keyNotificationSettings);
      }
    } catch (e) {
      debugPrint('[OfflineCacheService] Migration notice: $e');
    }
  }

  // Save Irrigation Recommendation Data for a specific plot
  static Future<void> cacheIrrigationData(int plotId, Map<String, dynamic> data) async {
    try {
      await _box.put('$_keyIrrigationCachePrefix$plotId', data);
      await _box.put('${_keyIrrigationCachePrefix}last_updated', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error caching irrigation data to Hive: $e');
    }
  }

  // Load Cached Irrigation Recommendation Data for a plot
  static Future<Map<String, dynamic>?> getCachedIrrigationData(int plotId) async {
    try {
      final data = _box.get('$_keyIrrigationCachePrefix$plotId');
      if (data != null) {
        return Map<String, dynamic>.from(data);
      }
    } catch (e) {
      debugPrint('Error reading cached irrigation data from Hive: $e');
    }
    return null;
  }

  // Save Plots List JSON
  static Future<void> cachePlotsList(List<dynamic> plotsJson) async {
    try {
      await _box.put(_keyPlotsListCache, plotsJson);
    } catch (e) {
      debugPrint('Error caching plots list to Hive: $e');
    }
  }

  // Get Cached Plots List
  static Future<List<dynamic>?> getCachedPlotsList() async {
    try {
      final data = _box.get(_keyPlotsListCache);
      if (data is List) {
        return List<dynamic>.from(data);
      }
    } catch (e) {
      debugPrint('Error reading cached plots list from Hive: $e');
    }
    return null;
  }

  // Save Notification Feed History
  static Future<void> saveNotificationFeed(List<Map<String, dynamic>> feed) async {
    try {
      await _box.put(_keyNotificationFeed, feed);
    } catch (e) {
      debugPrint('Error saving notification feed to Hive: $e');
    }
  }

  // Load Notification Feed History
  static Future<List<Map<String, dynamic>>> loadNotificationFeed() async {
    try {
      final data = _box.get(_keyNotificationFeed);
      if (data is List) {
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (e) {
      debugPrint('Error loading notification feed from Hive: $e');
    }
    return [];
  }

  // Save Notification Settings
  static Future<void> saveNotificationSettings(Map<String, bool> settings) async {
    try {
      await _box.put(_keyNotificationSettings, settings);
    } catch (e) {
      debugPrint('Error saving notification settings to Hive: $e');
    }
  }

  // Load Notification Settings
  static Future<Map<String, bool>> loadNotificationSettings() async {
    try {
      final data = _box.get(_keyNotificationSettings);
      if (data is Map) {
        return data.map((key, value) => MapEntry(key.toString(), value as bool));
      }
    } catch (e) {
      debugPrint('Error loading notification settings from Hive: $e');
    }
    return {
      'irrigationAlerts': true,
      'weatherAlerts': true,
      'pumpReminders': true,
    };
  }
}
