import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../core/services/offline_cache_service.dart';
import 'notification_provider.dart';

class IrrigationProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isLogging = false;
  bool _isOfflineMode = false;
  String? _errorMessage;
  Map<String, dynamic>? _irrigationData;
  List<Map<String, dynamic>> _availableCrops = [];
  double _todayLoggedMm = 0.0; // Track today's logged total mm for UI

  // Dynamic Farm Parameters
  int? _plotId;
  double _latitude = 22.5726;
  double _longitude = 88.3639;
  String _selectedCrop = 'paddy_rice';
  String _sowingDate = '2026-06-15';
  String _fieldName = 'Main Plot';
  double _areaAcres = 2.5;
  double _pumpHp = 5.0;
  double _pumpFlowLps = 5.0;
  String _irrigationMethod = 'flood';
  String _soilType = 'clay_loam';

  bool get isLoading => _isLoading;
  bool get isLogging => _isLogging;
  bool get isOfflineMode => _isOfflineMode;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get irrigationData => _irrigationData;
  List<Map<String, dynamic>> get availableCrops => _availableCrops;
  String get selectedCrop => _selectedCrop;
  double get latitude => _latitude;
  double get longitude => _longitude;
  double get todayLoggedMm => _todayLoggedMm;

  Future<void> fetchAvailableCrops() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/crops/all'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _availableCrops = List<Map<String, dynamic>>.from(data['crops']);
        _availableCrops.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching dynamic crop list: $e');
    }
  }

  Future<void> loadIrrigationData({NotificationProvider? notificationProvider}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.irrigationEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (_plotId != null) 'plot_id': _plotId,
          'latitude': _latitude,
          'longitude': _longitude,
          'crop_id': _selectedCrop,
          'sowing_date': _sowingDate,
          'field_name': _fieldName,
          'area_acres': _areaAcres,
          'pump_hp': _pumpHp,
          'pump_flow_lps': _pumpFlowLps,
          'irrigation_method': _irrigationMethod,
          'soil_type': _soilType,
        }),
      );

      if (response.statusCode == 200) {
        _irrigationData = jsonDecode(response.body);
        _isOfflineMode = false;

        // Cache recommendation data locally
        if (_plotId != null && _irrigationData != null) {
          await OfflineCacheService.cacheIrrigationData(_plotId!, _irrigationData!);
        }
      } else {
        _errorMessage = 'Backend Engine Error (${response.statusCode})';
      }
    } catch (e) {
      // Offline fallback: load cached recommendation data
      if (_plotId != null) {
        final cached = await OfflineCacheService.getCachedIrrigationData(_plotId!);
        if (cached != null) {
          _irrigationData = cached;
          _isOfflineMode = true;
          _errorMessage = null;
        } else {
          _errorMessage = 'Cannot connect to JalDrishti server (No cached data).';
        }
      } else {
        _errorMessage = 'Cannot connect to JalDrishti server at ${ApiConstants.baseUrl}';
      }
    } finally {
      _isLoading = false;
      notifyListeners();

      // Check if irrigation is required and push notification if enabled
      if (_irrigationData != null && _irrigationData!['needs_irrigation_today'] == true) {
        final hrs = _irrigationData!['recommended_pump_hours'] ?? 1;
        final mins = _irrigationData!['recommended_pump_minutes'] ?? 0;
        final recMm = (_irrigationData!['recommended_water_mm'] as num?)?.toDouble() ?? 0.0;

        if (notificationProvider != null) {
          notificationProvider.addNotification(
            title: '🌾 Irrigation Required: $_fieldName',
            body: 'Run your $_pumpHp HP pump for ${hrs}h ${mins}m (${recMm.toStringAsFixed(1)} mm depth) today.',
            type: 'irrigation',
          );
        }
      }
    }
  }

  void updatePlotAndCrop({
    int? plotId,
    required double lat,
    required double lon,
    required String cropId,
    required String sowingDate,
    required String fieldName,
    double areaAcres = 2.5,
    double pumpHp = 5.0,
    double pumpFlowLps = 5.0,
    String irrigationMethod = 'flood',
    String soilType = 'clay_loam',
  }) {
    _plotId = plotId;
    _latitude = lat;
    _longitude = lon;
    _selectedCrop = cropId;
    _sowingDate = sowingDate;
    _fieldName = fieldName;
    _areaAcres = areaAcres;
    _pumpHp = pumpHp;
    _pumpFlowLps = pumpFlowLps;
    _irrigationMethod = irrigationMethod;
    _soilType = soilType;
    _todayLoggedMm = 0.0;
    loadIrrigationData();
  }

  void updateFarmSetup({
    int? plotId,
    required double lat,
    required double lon,
    required String sowingDate,
    required String fieldName,
    double areaAcres = 2.5,
    double pumpHp = 5.0,
    double pumpFlowLps = 5.0,
    String irrigationMethod = 'flood',
    String soilType = 'clay_loam',
  }) {
    _plotId = plotId;
    _latitude = lat;
    _longitude = lon;
    _sowingDate = sowingDate;
    _fieldName = fieldName;
    _areaAcres = areaAcres;
    _pumpHp = pumpHp;
    _pumpFlowLps = pumpFlowLps;
    _irrigationMethod = irrigationMethod;
    _soilType = soilType;
    loadIrrigationData();
  }

  void updateCrop(String cropId) {
    _selectedCrop = cropId;
    loadIrrigationData();
  }

  Future<bool> logIrrigationEvent({
    required int plotId,
    required double appliedMm,
    String notes = '',
  }) async {
    _isLogging = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/irrigation/log'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'farm_plot_id': plotId,
          'applied_mm': appliedMm,
          'notes': notes,
        }),
      );

      if (response.statusCode == 200) {
        _todayLoggedMm += appliedMm; // Optimistically update the logged total
        notifyListeners(); // Immediate UI feedback
        await loadIrrigationData(); // Reload with updated water balance
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isLogging = false;
      notifyListeners();
    }
  }
}