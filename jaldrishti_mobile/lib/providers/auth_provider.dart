import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/services/api_service.dart';
import '../core/services/fcm_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();

  bool _isAuthenticated = false;
  bool _isCheckingAuth = true;
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _user;
  String? _token;
  String? _refreshToken;

  bool get isAuthenticated => _isAuthenticated;
  bool get isCheckingAuth => _isCheckingAuth;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;
  String? get token => _token;
  String? get refreshToken => _refreshToken;

  AuthProvider() {
    _registerApiCallbacks();
    _checkExistingToken();
  }

  void _registerApiCallbacks() {
    ApiService.onTokenRefreshNeeded = _silentRefreshForInterceptor;
    ApiService.onForceLogout = _handleForcedLogout;
  }

  Future<String?> _silentRefreshForInterceptor() async {
    final success = await refreshSession();
    return success ? _token : null;
  }

  Future<void> _handleForcedLogout() async {
    await _clearSecureTokens();
    notifyListeners();
  }

  // Check stored secure JWT token on app boot
  Future<void> _checkExistingToken() async {
    try {
      // Migrate / clean legacy plaintext SharedPreferences token if present
      try {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.containsKey('jwt_token')) {
          await prefs.remove('jwt_token');
        }
      } catch (_) {}

      final savedToken = await _storage.read(key: 'jwt_token');
      final savedRefresh = await _storage.read(key: 'refresh_token');

      if (savedToken != null && savedToken.isNotEmpty) {
        _token = savedToken;
        _refreshToken = savedRefresh;
        bool success = await _fetchCurrentUserProfile();
        
        // If access token expired, attempt auto-refresh via refresh token
        if (!success && savedRefresh != null && savedRefresh.isNotEmpty) {
          success = await refreshSession();
        }

        if (success) {
          _isAuthenticated = true;
        } else {
          await _clearSecureTokens();
        }
      }
    } catch (e) {
      debugPrint('Auth Check Error: $e');
    } finally {
      _isCheckingAuth = false;
      notifyListeners();
    }
  }

  Future<void> _clearSecureTokens() async {
    _token = null;
    _refreshToken = null;
    _isAuthenticated = false;
    _user = null;
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'refresh_token');
  }

  // Refresh Session via Refresh Token
  Future<bool> refreshSession() async {
    final refToken = _refreshToken ?? await _storage.read(key: 'refresh_token');
    if (refToken == null || refToken.isEmpty) return false;

    try {
      final data = await ApiService.refreshToken(refToken);
      _token = data['access_token'];
      _refreshToken = data['refresh_token'];
      _user = UserModel.fromJson(data['user']);
      
      await _storage.write(key: 'jwt_token', value: _token!);
      await _storage.write(key: 'refresh_token', value: _refreshToken!);
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Refresh session error: $e');
      await _clearSecureTokens();
    }
    return false;
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
      final data = await ApiService.register(
        username: username.trim(),
        phoneNumber: phoneNumber.trim(),
        password: password,
      );

      _token = data['access_token'];
      _refreshToken = data['refresh_token'];
      _user = UserModel.fromJson(data['user']);
      _isAuthenticated = true;

      await _storage.write(key: 'jwt_token', value: _token!);
      if (_refreshToken != null) {
        await _storage.write(key: 'refresh_token', value: _refreshToken!);
      }
      FcmService.syncDeviceTokenWithBackend(_token!);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
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
      final data = await ApiService.login(
        loginIdentifier: loginIdentifier.trim(),
        password: password,
      );

      _token = data['access_token'];
      _refreshToken = data['refresh_token'];
      _user = UserModel.fromJson(data['user']);
      _isAuthenticated = true;

      await _storage.write(key: 'jwt_token', value: _token!);
      if (_refreshToken != null) {
        await _storage.write(key: 'refresh_token', value: _refreshToken!);
      }
      FcmService.syncDeviceTokenWithBackend(_token!);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Cannot connect to JalDrishti server.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Request Password Reset OTP SMS
  Future<Map<String, dynamic>?> requestPasswordResetOtp(String phoneNumber) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await ApiService.requestPasswordResetOtp(phoneNumber.trim());
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return null;
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
    required String phoneNumber,
    required String otpCode,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiService.resetPassword(
        phoneNumber: phoneNumber.trim(),
        otpCode: otpCode.trim(),
        newPassword: newPassword,
      );
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
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
      final userData = await ApiService.fetchProfile(_token!);
      _user = UserModel.fromJson(userData);
      return true;
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
      return await ApiService.requestPhoneUpdateOtp(newPhoneNumber: newPhoneNumber.trim(), token: _token!);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return null;
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
      final userData = await ApiService.verifyPhoneUpdateOtp(
        newPhoneNumber: newPhoneNumber.trim(),
        otpCode: otpCode.trim(),
        token: _token!,
      );
      _user = UserModel.fromJson(userData);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
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
      final updatedProfileData = await ApiService.updateProfile(
        profileData: newProfile.toJson(),
        token: _token!,
      );
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
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
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
    if (_token != null) {
      await ApiService.logout(_token!);
    }
    await _clearSecureTokens();
    notifyListeners();
  }
}
