class FarmPlotModel {
  final int id;
  final int userId;
  final String name;
  final String locationName;
  final double latitude;
  final double longitude;
  final String cropId;
  final String sowingDate;
  final double areaAcres;
  final bool isPrimary;

  // New Production Attributes
  final double pumpHp;
  final double pumpFlowLps;
  final String irrigationMethod;
  final String soilType;

  FarmPlotModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.cropId,
    required this.sowingDate,
    required this.areaAcres,
    required this.isPrimary,
    this.pumpHp = 5.0,
    this.pumpFlowLps = 5.0,
    this.irrigationMethod = 'flood',
    this.soilType = 'clay_loam',
  });

  factory FarmPlotModel.fromJson(Map<String, dynamic> json) {
    return FarmPlotModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? 'Farm Plot',
      locationName: json['location_name'] ?? 'Burdwan, WB',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 22.5726,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 88.3639,
      cropId: json['crop_id'] ?? 'paddy_rice',
      sowingDate: json['sowing_date'] ?? DateTime.now().toIso8601String().split('T')[0],
      areaAcres: (json['area_acres'] as num?)?.toDouble() ?? 2.5,
      isPrimary: json['is_primary'] ?? false,
      pumpHp: (json['pump_hp'] as num?)?.toDouble() ?? 5.0,
      pumpFlowLps: (json['pump_flow_lps'] as num?)?.toDouble() ?? 5.0,
      irrigationMethod: json['irrigation_method'] ?? 'flood',
      soilType: json['soil_type'] ?? 'clay_loam',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'location_name': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'crop_id': cropId,
      'sowing_date': sowingDate,
      'area_acres': areaAcres,
      'is_primary': isPrimary,
      'pump_hp': pumpHp,
      'pump_flow_lps': pumpFlowLps,
      'irrigation_method': irrigationMethod,
      'soil_type': soilType,
    };
  }
}
