class UserProfileModel {
  final String firstName;
  final String lastName;
  final String locationName;
  final double latitude;
  final double longitude;
  final double farmAreaAcres;
  final String interestedCrop;
  final String farmingExperience;
  final String preferredLanguage;

  UserProfileModel({
    required this.firstName,
    required this.lastName,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.farmAreaAcres,
    required this.interestedCrop,
    required this.farmingExperience,
    required this.preferredLanguage,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      firstName: json['first_name'] ?? 'Farmer',
      lastName: json['last_name'] ?? '',
      locationName: json['location_name'] ?? 'Kolkata, WB',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 22.5726,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 88.3639,
      farmAreaAcres: (json['farm_area_acres'] as num?)?.toDouble() ?? 2.5,
      interestedCrop: json['interested_crop'] ?? 'paddy_rice',
      farmingExperience: json['farming_experience'] ?? 'Intermediate',
      preferredLanguage: json['preferred_language'] ?? 'English',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'location_name': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'farm_area_acres': farmAreaAcres,
      'interested_crop': interestedCrop,
      'farming_experience': farmingExperience,
      'preferred_language': preferredLanguage,
    };
  }

  UserProfileModel copyWith({
    String? firstName,
    String? lastName,
    String? locationName,
    double? latitude,
    double? longitude,
    double? farmAreaAcres,
    String? interestedCrop,
    String? farmingExperience,
    String? preferredLanguage,
  }) {
    return UserProfileModel(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      farmAreaAcres: farmAreaAcres ?? this.farmAreaAcres,
      interestedCrop: interestedCrop ?? this.interestedCrop,
      farmingExperience: farmingExperience ?? this.farmingExperience,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }
}

class UserModel {
  final int id;
  final String username;
  final String phoneNumber;
  final bool isActive;
  final UserProfileModel? profile;

  UserModel({
    required this.id,
    required this.username,
    required this.phoneNumber,
    required this.isActive,
    this.profile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      isActive: json['is_active'] ?? true,
      profile: json['profile'] != null ? UserProfileModel.fromJson(json['profile']) : null,
    );
  }
}
