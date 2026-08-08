import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../core/services/fcm_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isCheckingAuth = true;
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _user;
  String? _token;

  bool get isAuthenticated => _isAuthenticated;
  bool get isCheckingAuth => _isCheckingAuth;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;
  String? get token => _token;

  AuthProvider() {
    _checkExistingToken();
  }

  // Check stored JWT token on app boot
  Future<void> _checkExistingToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('jwt_token');

      if (savedToken != null && savedToken.isNotEmpty) {
        _token = savedToken;
        final success = await _fetchCurrentUserProfile();
        if (success) {
          _isAuthenticated = true;
        } else {
          await prefs.remove('jwt_token');
          _token = null;
        }
      }
    } catch (e) {
      debugPrint('Auth Check Error: $e');
    } finally {
      _isCheckingAuth = false;
      notifyListeners();
    }
  }

  // Register New Farmer Account
  Future<bool> register({
    required String username,
    required String phoneNumber,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.registerEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username.trim(),
          'phone_number': phoneNumber.trim(),
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _token = data['access_token'];
        _user = UserModel.fromJson(data['user']);
        _isAuthenticated = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', _token!);
        FcmService.syncDeviceTokenWithBackend(_token!);
        return true;
      } else {
        _errorMessage = data['detail'] ?? 'Registration failed.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Cannot connect to JalDrishti server.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login (Username or Phone Number)
  Future<bool> login({
    required String loginIdentifier,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'login_identifier': loginIdentifier.trim(),
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _token = data['access_token'];
        _user = UserModel.fromJson(data['user']);
        _isAuthenticated = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', _token!);
        FcmService.syncDeviceTokenWithBackend(_token!);
        return true;
      } else {
        _errorMessage = data['detail'] ?? 'Invalid credentials.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Cannot connect to JalDrishti server.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Request Password Reset OTP SMS
  Future<Map<String, dynamic>?> requestPasswordResetOtp(String phoneOrUsername) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.requestOtpEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_or_username': phoneOrUsername.trim()}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        _errorMessage = data['detail'] ?? 'Failed to request OTP.';
        return null;
      }
    } catch (e) {
      _errorMessage = 'Cannot connect to JalDrishti server.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Verify OTP and Reset Password
  Future<bool> resetPasswordWithOtp({
    required String phoneOrUsername,
    required String otpCode,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.resetPasswordEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone_or_username': phoneOrUsername.trim(),
          'otp_code': otpCode.trim(),
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final data = jsonDecode(response.body);
        _errorMessage = data['detail'] ?? 'Failed to reset password.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error during password reset.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch Current User Details from /me
  Future<bool> _fetchCurrentUserProfile() async {
    if (_token == null) return false;

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.meEndpoint),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        _user = UserModel.fromJson(userData);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Request Phone Update OTP SMS
  Future<Map<String, dynamic>?> requestPhoneUpdateOtp(String newPhoneNumber) async {
    if (_token == null) return null;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.requestPhoneUpdateOtpEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({'new_phone_number': newPhoneNumber.trim()}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        _errorMessage = data['detail'] ?? 'Failed to request OTP.';
        return null;
      }
    } catch (e) {
      _errorMessage = 'Cannot connect to JalDrishti server.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Verify Phone Update OTP and Update Phone Number
  Future<bool> verifyPhoneUpdateOtp({
    required String newPhoneNumber,
    required String otpCode,
  }) async {
    if (_token == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.verifyPhoneUpdateOtpEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'new_phone_number': newPhoneNumber.trim(),
          'otp_code': otpCode.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        _user = UserModel.fromJson(userData);
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _errorMessage = data['detail'] ?? 'Invalid or expired OTP.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error verifying OTP.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update Farmer Profile (Onboarding Survey & Edits)
  Future<bool> updateProfile(UserProfileModel newProfile) async {
    if (_token == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse(ApiConstants.updateProfileEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode(newProfile.toJson()),
      );

      if (response.statusCode == 200) {
        final updatedProfileData = jsonDecode(response.body);
        final updatedProfile = UserProfileModel.fromJson(updatedProfileData);
        if (_user != null) {
          _user = UserModel(
            id: _user!.id,
            username: _user!.username,
            phoneNumber: _user!.phoneNumber,
            isActive: _user!.isActive,
            profile: updatedProfile,
          );
        }
        return true;
      } else {
        _errorMessage = 'Failed to update profile (${response.statusCode})';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error updating profile.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    _isAuthenticated = false;
    _user = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    notifyListeners();
  }
}
