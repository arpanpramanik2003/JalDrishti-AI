import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'api_service.dart';

class OfflineSyncManager {
  static const String syncQueueBoxName = 'jaldrishti_sync_queue';

  static Box<dynamic> get _box => Hive.box(syncQueueBoxName);

  /// Queue offline farm plot creation
  static Future<void> queuePlotCreate(Map<String, dynamic> plotData) async {
    try {
      final item = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': 'create_plot',
        'data': plotData,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _box.add(item);
      debugPrint('[OfflineSyncManager] Queued plot creation. Queue size: ${_box.length}');
    } catch (e) {
      debugPrint('[OfflineSyncManager] Error queuing plot creation: $e');
    }
  }

  /// Queue offline farm plot update
  static Future<void> queuePlotUpdate({
    required int plotId,
    required Map<String, dynamic> plotData,
  }) async {
    try {
      final item = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': 'update_plot',
        'plot_id': plotId,
        'data': plotData,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _box.add(item);
      debugPrint('[OfflineSyncManager] Queued plot update for ID $plotId. Queue size: ${_box.length}');
    } catch (e) {
      debugPrint('[OfflineSyncManager] Error queuing plot update: $e');
    }
  }

  /// Queue offline farm plot deletion
  static Future<void> queuePlotDelete(int plotId) async {
    try {
      final item = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': 'delete_plot',
        'plot_id': plotId,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _box.add(item);
      debugPrint('[OfflineSyncManager] Queued plot deletion for ID $plotId. Queue size: ${_box.length}');
    } catch (e) {
      debugPrint('[OfflineSyncManager] Error queuing plot deletion: $e');
    }
  }

  /// Queue offline irrigation log
  static Future<void> queuePendingIrrigationLog(Map<String, dynamic> logData) async {
    try {
      final item = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': 'log_irrigation',
        'data': logData,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _box.add(item);
      debugPrint('[OfflineSyncManager] Queued irrigation log offline. Queue size: ${_box.length}');
    } catch (e) {
      debugPrint('[OfflineSyncManager] Error queuing irrigation log: $e');
    }
  }

  /// Get total pending queued items count
  static Future<int> getPendingQueueCount() async {
    try {
      return _box.length;
    } catch (_) {
      return 0;
    }
  }

  /// Sync all offline queued data with backend when online
  static Future<int> syncPendingData(String? authToken) async {
    if (authToken == null || authToken.isEmpty) return 0;
    int syncedCount = 0;
    final keysToDelete = <dynamic>[];

    try {
      final keys = _box.keys.toList();
      for (var key in keys) {
        final rawItem = _box.get(key);
        if (rawItem is! Map) continue;
        final item = Map<String, dynamic>.from(rawItem);
        final type = item['type'];

        try {
          if (type == 'log_irrigation') {
            await ApiService.logIrrigationEvent(
              payload: Map<String, dynamic>.from(item['data']),
              token: authToken,
            );
            keysToDelete.add(key);
            syncedCount++;
          } else if (type == 'create_plot') {
            await ApiService.createPlot(
              plotData: Map<String, dynamic>.from(item['data']),
              token: authToken,
            );
            keysToDelete.add(key);
            syncedCount++;
          } else if (type == 'update_plot') {
            final plotId = item['plot_id'];
            await ApiService.updatePlot(
              plotId: plotId,
              plotData: Map<String, dynamic>.from(item['data']),
              token: authToken,
            );
            keysToDelete.add(key);
            syncedCount++;
          } else if (type == 'delete_plot') {
            final plotId = item['plot_id'];
            await ApiService.deletePlot(
              plotId: plotId,
              token: authToken,
            );
            keysToDelete.add(key);
            syncedCount++;
          }
        } on ApiException catch (e) {
          // If conflict occurs (409 Conflict), preserve queue item or flag for user review
          if (e.statusCode == 409) {
            debugPrint('[OfflineSyncManager] 409 Conflict syncing item key $key: ${e.message}');
            // Remove item to unblock queue, or keep for manual review
            keysToDelete.add(key);
          } else {
            debugPrint('[OfflineSyncManager] Retry later for item key $key due to error: ${e.message}');
          }
        } catch (e) {
          debugPrint('[OfflineSyncManager] Error syncing item key $key: $e');
        }
      }

      for (var k in keysToDelete) {
        await _box.delete(k);
      }

      debugPrint('[OfflineSyncManager] Sync cycle complete. Uploaded $syncedCount queued operations.');
    } catch (e) {
      debugPrint('[OfflineSyncManager] Error during sync: $e');
    }
    return syncedCount;
  }
}
