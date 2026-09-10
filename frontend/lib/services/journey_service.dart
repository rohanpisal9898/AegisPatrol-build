import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../core/constants/api_endpoints.dart';
import '../models/journey_model.dart';
import '../models/risk_model.dart';
import 'api_service.dart';

class JourneyService {
  final http.Client _client;

  JourneyService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// Get current active journey for authenticated civilian (if any)
  Future<ApiResponse<JourneyModel>> getActiveJourney({
    required String token,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiEndpoints.journeys}/active'),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final bodyText = response.body.trim();
        if (bodyText.isEmpty || bodyText == 'null') {
          return ApiResponse(success: true, data: null);
        }
        final data = jsonDecode(bodyText);
        if (data == null) {
          return ApiResponse(success: true, data: null);
        }
        return ApiResponse(
          success: true,
          data: JourneyModel.fromJson(data),
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'No active journey found',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network connection failed: $e',
      );
    }
  }

  /// Start a new journey
  Future<ApiResponse<JourneyModel>> startJourney({
    required String token,
    required TravelMode travelMode,
    LatLng? startLocation,
    String? startLocationName,
    LatLng? destination,
    String? destinationName,
    int expectedDurationMinutes = 30,
  }) async {
    try {
      final body = {
        'travel_mode': travelMode.toApiString(),
        'expected_duration_minutes': expectedDurationMinutes,
        if (startLocationName != null) 'start_location_name': startLocationName,
        if (destinationName != null) 'destination_name': destinationName,
        if (startLocation != null)
          'current_location': {
            'lat': startLocation.latitude,
            'lon': startLocation.longitude,
          },
        if (destination != null)
          'destination': {
            'lat': destination.latitude,
            'lon': destination.longitude,
          },
      };

      final response = await _client.post(
        Uri.parse(ApiEndpoints.startJourney),
        headers: _headers(token),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: true,
          data: JourneyModel.fromJson(data),
        );
      } else {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: false,
          message: data['message'] ?? 'Failed to start journey (${response.statusCode})',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network connection failed: $e',
      );
    }
  }

  /// Update journey location and receive mock risk evaluation
  Future<ApiResponse<RiskEvaluationResult>> updateLocation({
    required String token,
    required String journeyId,
    required double lat,
    required double lon,
    int? stepIndex,
  }) async {
    try {
      final body = {
        'lat': lat,
        'lon': lon,
        if (stepIndex != null) 'step_index': stepIndex,
      };

      final response = await _client.post(
        Uri.parse(ApiEndpoints.journeyLocation(journeyId)),
        headers: _headers(token),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: true,
          data: RiskEvaluationResult.fromJson(data),
        );
      } else {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: false,
          message: data['message'] ?? 'Failed to update location',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network connection error: $e',
      );
    }
  }

  /// End active journey
  Future<ApiResponse<Map<String, dynamic>>> endJourney({
    required String token,
    required String journeyId,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiEndpoints.endJourney(journeyId)),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: true,
          data: data,
        );
      } else {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: false,
          message: data['message'] ?? 'Failed to end journey',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network connection error: $e',
      );
    }
  }

  /// Get single journey details
  Future<ApiResponse<JourneyModel>> getJourney({
    required String token,
    required String journeyId,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse(ApiEndpoints.getJourney(journeyId)),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: true,
          data: JourneyModel.fromJson(data),
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Journey not found',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network connection error: $e',
      );
    }
  }

  /// Fetch user journey history
  Future<ApiResponse<List<JourneyModel>>> listJourneys({
    required String token,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse(ApiEndpoints.journeys),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        final items = list.map((j) => JourneyModel.fromJson(j)).toList();
        return ApiResponse(
          success: true,
          data: items,
        );
      } else {
        String msg = 'No journeys found';
        try {
          final data = jsonDecode(response.body);
          if (data is Map && (data['detail'] != null || data['message'] != null)) {
            msg = data['detail'] ?? data['message'];
          }
        } catch (_) {}
        return ApiResponse(
          success: false,
          message: msg,
          data: [],
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
        data: [],
      );
    }
  }

}
