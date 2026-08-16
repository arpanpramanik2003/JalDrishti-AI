import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/api_service.dart';
import '../core/services/offline_sync_manager.dart';
import '../models/farm_plot_model.dart';
import 'auth_provider.dart';
import 'irrigation_provider.dart';

class FarmPlotProvider extends ChangeNotifier {
  List<FarmPlotModel> _plots = [];
  FarmPlotModel? _selectedPlot;
  bool _isLoading = false;
  String? _errorMessage;

  // Conflict state for UI resolution
  bool _hasConflict = false;
  Map<String, dynamic>? _conflictDetails;

  List<FarmPlotModel> get plots => List.unmodifiable(_plots);
  FarmPlotModel? get selectedPlot => _selectedPlot;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasConflict => _hasConflict;
  Map<String, dynamic>? get conflictDetails => _conflictDetails;

  void clearConflict() {
    _hasConflict = false;
    _conflictDetails = null;
    notifyListeners();
  }

  // Fetch all farm plots of current user
  Future<void> fetchPlots({
    required AuthProvider auth,
    required IrrigationProvider irrigation,
  }) async {
    if (auth.token == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<dynamic> data = await ApiService.fetchPlots(auth.token!);
      _plots = data.map((json) => FarmPlotModel.fromJson(json)).toList();

      if (_plots.isNotEmpty) {
        int? targetId;
        // Preserve currently selected plot if it still exists
        if (_selectedPlot != null && _plots.any((p) => p.id == _selectedPlot!.id)) {
          targetId = _selectedPlot!.id;
        } else {
          // Check SharedPreferences for previously saved plot selection
          try {
            final prefs = await SharedPreferences.getInstance();
            final savedId = prefs.getInt('selected_plot_id');
            if (savedId != null && _plots.any((p) => p.id == savedId)) {
              targetId = savedId;
            }
          } catch (_) {}
        }

        final targetPlot = targetId != null
            ? _plots.firstWhere((p) => p.id == targetId)
            : _plots.firstWhere((p) => p.isPrimary, orElse: () => _plots.first);

        selectPlot(targetPlot, irrigation);
      } else {
        _selectedPlot = null;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Connection error fetching farm plots.';
      debugPrint('Fetch farm plots error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Select Active Plot and update IrrigationProvider calculation
  void selectPlot(FarmPlotModel plot, IrrigationProvider irrigation) async {
    _selectedPlot = plot;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('selected_plot_id', plot.id);
    } catch (_) {}

    // Atomic update to IrrigationProvider with plot & crop parameters
    irrigation.updatePlotAndCrop(
      plotId: plot.id,
      lat: plot.latitude,
      lon: plot.longitude,
      cropId: plot.cropId,
      sowingDate: plot.sowingDate,
      fieldName: plot.name,
      areaAcres: plot.areaAcres,
      pumpHp: plot.pumpHp,
      pumpFlowLps: plot.pumpFlowLps,
      irrigationMethod: plot.irrigationMethod,
      soilType: plot.soilType,
    );
  }

  // Create a New Farm Plot (Online & Offline Support)
  Future<bool> createPlot({
    required AuthProvider auth,
    required IrrigationProvider irrigation,
    required FarmPlotModel plotData,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (auth.token != null) {
        await ApiService.createPlot(plotData: plotData.toJson(), token: auth.token!);
        await fetchPlots(auth: auth, irrigation: irrigation);
        return true;
      }
      throw ApiException(0, 'Offline');
    } on ApiException catch (e) {
      if (e.statusCode == 0) {
        // Offline mode: queue locally and add to local state
        await OfflineSyncManager.queuePlotCreate(plotData.toJson());
        _plots = [..._plots, plotData];
        selectPlot(plotData, irrigation);
        return true;
      }
      _errorMessage = e.message;
      return false;
    } catch (e) {
      await OfflineSyncManager.queuePlotCreate(plotData.toJson());
      _plots = [..._plots, plotData];
      selectPlot(plotData, irrigation);
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update Existing Farm Plot (Online & Offline Support + 409 Conflict Handling)
  Future<bool> updatePlot({
    required AuthProvider auth,
    required IrrigationProvider irrigation,
    required int plotId,
    required FarmPlotModel plotData,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _hasConflict = false;
    _conflictDetails = null;
    notifyListeners();

    try {
      if (auth.token != null) {
        await ApiService.updatePlot(plotId: plotId, plotData: plotData.toJson(), token: auth.token!);
        await fetchPlots(auth: auth, irrigation: irrigation);
        return true;
      }
      throw ApiException(0, 'Offline');
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        // HTTP 409 Conflict: Plot modified elsewhere
        _hasConflict = true;
        _conflictDetails = {
          'plot_id': plotId,
          'local_plot': plotData,
          'message': e.message,
        };
        _errorMessage = 'Conflict: This farm plot was modified elsewhere on the server.';
        notifyListeners();
        return false;
      } else if (e.statusCode == 0) {
        // Offline mode: queue locally and update optimistic state
        await OfflineSyncManager.queuePlotUpdate(plotId: plotId, plotData: plotData.toJson());
        _plots = _plots.map((p) => p.id == plotId ? plotData : p).toList();
        if (_selectedPlot?.id == plotId) selectPlot(plotData, irrigation);
        return true;
      }
      _errorMessage = e.message;
      return false;
    } catch (e) {
      await OfflineSyncManager.queuePlotUpdate(plotId: plotId, plotData: plotData.toJson());
      _plots = _plots.map((p) => p.id == plotId ? plotData : p).toList();
      if (_selectedPlot?.id == plotId) selectPlot(plotData, irrigation);
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set Primary Farm Plot
  Future<bool> setPrimaryPlot({
    required AuthProvider auth,
    required IrrigationProvider irrigation,
    required int plotId,
  }) async {
    if (auth.token == null) return false;

    try {
      await ApiService.setPrimaryPlot(plotId: plotId, token: auth.token!);
      await fetchPlots(auth: auth, irrigation: irrigation);
      return true;
    } catch (e) {
      debugPrint('Set primary plot error: $e');
    }
    return false;
  }

  // Delete Farm Plot (Online & Offline Support)
  Future<bool> deletePlot({
    required AuthProvider auth,
    required IrrigationProvider irrigation,
    required int plotId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (auth.token != null) {
        await ApiService.deletePlot(plotId: plotId, token: auth.token!);
        await fetchPlots(auth: auth, irrigation: irrigation);
        return true;
      }
      throw ApiException(0, 'Offline');
    } on ApiException catch (e) {
      if (e.statusCode == 0) {
        await OfflineSyncManager.queuePlotDelete(plotId);
        _plots = _plots.where((p) => p.id != plotId).toList();
        if (_selectedPlot?.id == plotId && _plots.isNotEmpty) {
          selectPlot(_plots.first, irrigation);
        }
        return true;
      }
      _errorMessage = e.message;
      return false;
    } catch (e) {
      await OfflineSyncManager.queuePlotDelete(plotId);
      _plots = _plots.where((p) => p.id != plotId).toList();
      if (_selectedPlot?.id == plotId && _plots.isNotEmpty) {
        selectPlot(_plots.first, irrigation);
      }
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
