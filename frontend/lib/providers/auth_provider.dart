import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../core/storage/secure_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;

  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedRoleFlow; // 'civilian' or 'police' (transient during auth flow)

  AuthProvider({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedRoleFlow => _selectedRoleFlow;
  bool get isAuthenticated => _token != null && _currentUser != null;

  void setSelectedRoleFlow(String? role) {
    _selectedRoleFlow = role;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Check stored session on startup
  Future<bool> checkSession() async {
    _isLoading = true;
    notifyListeners();

    final savedToken = await SecureStorageService.getToken();
    final savedUser = await SecureStorageService.getUser();

    if (savedToken != null && savedUser != null) {
      _token = savedToken;
      _currentUser = savedUser;
      
      // Optionally verify with /auth/me in background
      _apiService.getMe(savedToken).then((response) {
        if (response.success && response.data != null) {
          _currentUser = response.data;
          SecureStorageService.saveUser(response.data!);
          notifyListeners();
        }
      }).catchError((_) {});

      _isLoading = false;
      notifyListeners();
      return true;
    }

    _token = null;
    _currentUser = null;
    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Civilian Signup
  Future<bool> civilianSignup({
    required String name,
    required String phone,
    required String password,
    required String district,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _apiService.civilianSignup(
      name: name,
      phone: phone,
      password: password,
      district: district,
    );

    if (res.success && res.data != null) {
      // Automatically login after signup
      final loginRes = await _apiService.civilianLogin(
        phone: phone,
        password: password,
      );

      if (loginRes.success && loginRes.data != null && loginRes.token != null) {
        _token = loginRes.token;
        _currentUser = loginRes.data;
        await SecureStorageService.saveToken(_token!);
        await SecureStorageService.saveUser(_currentUser!);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    }

    _errorMessage = res.message ?? 'Civilian registration failed';
    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Civilian Login
  Future<bool> civilianLogin({
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _apiService.civilianLogin(
      phone: phone,
      password: password,
    );

    if (res.success && res.data != null && res.token != null) {
      _token = res.token;
      _currentUser = res.data;
      await SecureStorageService.saveToken(_token!);
      await SecureStorageService.saveUser(_currentUser!);
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _errorMessage = res.message ?? 'Invalid phone number or password';
    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Police Signup
  Future<bool> policeSignup({
    required String name,
    required String phone,
    required String password,
    required String district,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _apiService.policeSignup(
      name: name,
      phone: phone,
      password: password,
      district: district,
    );

    if (res.success && res.data != null) {
      // Automatically login after signup
      final loginRes = await _apiService.policeLogin(
        phone: phone,
        password: password,
      );

      if (loginRes.success && loginRes.data != null && loginRes.token != null) {
        _token = loginRes.token;
        _currentUser = loginRes.data;
        await SecureStorageService.saveToken(_token!);
        await SecureStorageService.saveUser(_currentUser!);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    }

    _errorMessage = res.message ?? 'Police registration failed';
    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Police Login
  Future<bool> policeLogin({
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _apiService.policeLogin(
      phone: phone,
      password: password,
    );

    if (res.success && res.data != null && res.token != null) {
      _token = res.token;
      _currentUser = res.data;
      await SecureStorageService.saveToken(_token!);
      await SecureStorageService.saveUser(_currentUser!);
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _errorMessage = res.message ?? 'Invalid phone number or password';
    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Logout
  Future<void> logout() async {
    if (_token != null) {
      _apiService.logout(_token!).catchError((_) {});
    }
    await SecureStorageService.clearSession();
    _token = null;
    _currentUser = null;
    _selectedRoleFlow = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Ensures an active authenticated session for the specified role.
  /// Falls back to verified online database demo credentials if unauthenticated.
  Future<bool> ensureRoleSession(String role) async {
    if (_token != null && _currentUser != null && _currentUser!.role == role) {
      return true;
    }

    await checkSession();
    if (_token != null && _currentUser != null && _currentUser!.role == role) {
      return true;
    }

    if (role == 'civilian' || role == 'citizen') {
      return await civilianLogin(phone: '9876543210', password: 'password123');
    } else {
      return await policeLogin(phone: '9876543211', password: 'password123');
    }
  }
}

