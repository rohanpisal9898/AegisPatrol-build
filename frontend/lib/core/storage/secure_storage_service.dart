import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/user_model.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static const String _keyToken = 'auth_jwt_token';
  static const String _keyUser = 'auth_user_data';

  /// Save JWT token
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  /// Retrieve JWT token
  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  /// Save User data JSON
  static Future<void> saveUser(UserModel user) async {
    await _storage.write(key: _keyUser, value: jsonEncode(user.toJson()));
  }

  /// Retrieve User data
  static Future<UserModel?> getUser() async {
    final raw = await _storage.read(key: _keyUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static const String _keyAppMode = 'app_user_mode'; // 'citizen' or 'patrol'
  static const String _keyOnboardingDone = 'app_onboarding_done';

  /// Save selected App Mode ('citizen' or 'patrol')
  static Future<void> saveAppMode(String mode) async {
    await _storage.write(key: _keyAppMode, value: mode);
    await _storage.write(key: _keyOnboardingDone, value: 'true');
  }

  /// Retrieve current App Mode
  static Future<String?> getAppMode() async {
    return await _storage.read(key: _keyAppMode);
  }

  /// Check whether first-launch onboarding has been completed
  static Future<bool> isOnboardingCompleted() async {
    final flag = await _storage.read(key: _keyOnboardingDone);
    return flag == 'true';
  }

  /// Clear App Mode preference and reset onboarding without clearing user session
  static Future<void> clearAppMode() async {
    await _storage.delete(key: _keyAppMode);
    await _storage.delete(key: _keyOnboardingDone);
  }

  /// Clear session
  static Future<void> clearSession() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUser);
  }
}
