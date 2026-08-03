import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class OfflineSyncManager {
  static const String _pendingLogsKey = 'pending_offline_irrigation_logs';
  static const String _pendingPlotsKey = 'pending_offline_farm_plots';

  /// Save irrigation log locally when network is offline
  static Future<void> queuePendingIrrigationLog(Map<String, dynamic> logData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> currentQueue = prefs.getStringList(_pendingLogsKey) ?? [];
      currentQueue.add(jsonEncode(logData));
      await prefs.setStringList(_pendingLogsKey, currentQueue);
      debugPrint('[OfflineSyncManager] Log queued offline. Total pending: ${currentQueue.length}');
    } catch (e) {
      debugPrint('[OfflineSyncManager] Error queuing log: $e');
    }
  }

  /// Get total pending queued items count
  static Future<int> getPendingQueueCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logs = prefs.getStringList(_pendingLogsKey) ?? [];
      final plots = prefs.getStringList(_pendingPlotsKey) ?? [];
      return logs.length + plots.length;
    } catch (_) {
      return 0;
    }
  }

  /// Sync all offline queued data with backend when online
  static Future<int> syncPendingData(String? authToken) async {
    int syncedCount = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> pendingLogs = prefs.getStringList(_pendingLogsKey) ?? [];

      if (pendingLogs.isEmpty) return 0;

      List<String> remainingLogs = [];

      for (String itemStr in pendingLogs) {
        try {
          final payload = jsonDecode(itemStr);
          final response = await http.post(
            Uri.parse('${ApiConstants.baseUrl}/irrigation/log'),
            headers: {
              'Content-Type': 'application/json',
              if (authToken != null) 'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode(payload),
          );

          if (response.statusCode == 200) {
            syncedCount++;
          } else {
            remainingLogs.add(itemStr);
          }
        } catch (_) {
          remainingLogs.add(itemStr);
        }
      }

      await prefs.setStringList(_pendingLogsKey, remainingLogs);
      debugPrint('[OfflineSyncManager] Sync completed! Successfully uploaded $syncedCount items.');
    } catch (e) {
      debugPrint('[OfflineSyncManager] Error during sync: $e');
    }
    return syncedCount;
  }
}
