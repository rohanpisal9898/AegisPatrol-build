import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_endpoints.dart';
import '../models/user_model.dart';

class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final String? token;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.token,
  });
}

class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Civilian Signup
  Future<ApiResponse<UserModel>> civilianSignup({
    required String name,
    required String phone,
    required String password,
    required String district,
  }) async {
    return _signup(
      endpoint: ApiEndpoints.civilianSignup,
      name: name,
      phone: phone,
      password: password,
      district: district,
    );
  }

  /// Civilian Login
  Future<ApiResponse<UserModel>> civilianLogin({
    required String phone,
    required String password,
  }) async {
    return _login(
      endpoint: ApiEndpoints.civilianLogin,
      phone: phone,
      password: password,
    );
  }

  /// Police Signup
  Future<ApiResponse<UserModel>> policeSignup({
    required String name,
    required String phone,
    required String password,
    required String district,
  }) async {
    return _signup(
      endpoint: ApiEndpoints.policeSignup,
      name: name,
      phone: phone,
      password: password,
      district: district,
    );
  }

  /// Police Login
  Future<ApiResponse<UserModel>> policeLogin({
    required String phone,
    required String password,
  }) async {
    return _login(
      endpoint: ApiEndpoints.policeLogin,
      phone: phone,
      password: password,
    );
  }

  /// Generic signup helper
  Future<ApiResponse<UserModel>> _signup({
    required String endpoint,
    required String name,
    required String phone,
    required String password,
    required String district,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(endpoint),
        headers: _headers(),
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'password': password,
          'district': district,
        }),
      );

      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        final user = UserModel.fromJson(body['user']);
        return ApiResponse(
          success: true,
          message: body['message'] ?? 'Signup successful',
          data: user,
        );
      } else {
        return ApiResponse(
          success: false,
          message: body['message'] ?? 'Signup failed',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error. Please check your connection.',
      );
    }
  }

  /// Generic login helper
  Future<ApiResponse<UserModel>> _login({
    required String endpoint,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(endpoint),
        headers: _headers(),
        body: jsonEncode({
          'phone': phone,
          'password': password,
        }),
      );

      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        final user = UserModel.fromJson(body['user']);
        final token = body['access_token'] as String?;
        return ApiResponse(
          success: true,
          data: user,
          token: token,
        );
      } else {
        return ApiResponse(
          success: false,
          message: body['message'] ?? 'Invalid phone number or password',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error. Please check your connection.',
      );
    }
  }

  /// Get current user profile
  Future<ApiResponse<UserModel>> getMe(String token) async {
    try {
      final response = await _client.get(
        Uri.parse(ApiEndpoints.me),
        headers: _headers(token: token),
      );

      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        final user = UserModel.fromJson(body['user']);
        return ApiResponse(
          success: true,
          data: user,
        );
      } else {
        return ApiResponse(
          success: false,
          message: body['message'] ?? 'Failed to fetch user profile',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error. Please check your connection.',
      );
    }
  }

  /// Logout
  Future<void> logout(String token) async {
    try {
      await _client.post(
        Uri.parse(ApiEndpoints.logout),
        headers: _headers(token: token),
      );
    } catch (_) {
      // Ignore network errors during logout
    }
  }
}
