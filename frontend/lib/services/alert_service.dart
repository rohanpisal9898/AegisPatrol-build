import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_endpoints.dart';
import '../models/alert_model.dart';
import 'api_service.dart';

class AlertService {
  final http.Client _client;

  AlertService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// Trigger SOS or Emergency Alert
  Future<ApiResponse<AlertModel>> createAlert({
    required String token,
    String? journeyId,
    String? district,
    required double lat,
    required double lon,
    String alertType = 'sos',
    String? message,
    double? riskScore,
  }) async {
    try {
      final body = {
        'lat': lat,
        'lon': lon,
        'alert_type': alertType,
        if (journeyId != null) 'journey_id': journeyId,
        if (district != null) 'district': district,
        if (message != null) 'message': message,
        if (riskScore != null) 'risk_score': riskScore,
      };

      final response = await _client.post(
        Uri.parse(ApiEndpoints.alerts),
        headers: _headers(token),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: true,
          data: AlertModel.fromJson(data),
          message: 'Alert sent successfully',
        );
      } else {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: false,
          message: data['message'] ?? 'Failed to send emergency alert',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error sending alert: $e',
      );
    }
  }

  /// Resolve alert
  Future<ApiResponse<bool>> resolveAlert({
    required String token,
    required String alertId,
    String? note,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiEndpoints.resolveAlert(alertId)),
        headers: _headers(token),
        body: jsonEncode({'note': note ?? 'Resolved'}),
      );

      return ApiResponse(
        success: response.statusCode == 200,
        data: response.statusCode == 200,
        message: 'Alert marked resolved',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  /// Mark journey user safe
  Future<ApiResponse<bool>> markJourneySafe({
    required String token,
    required String journeyId,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiEndpoints.markJourneySafe(journeyId)),
        headers: _headers(token),
      );

      return ApiResponse(
        success: response.statusCode == 200,
        data: response.statusCode == 200,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }
}
