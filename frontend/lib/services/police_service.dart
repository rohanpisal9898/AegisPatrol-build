import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_endpoints.dart';
import '../models/police_journey_model.dart';
import '../models/police_station_model.dart';
import 'api_service.dart';

class PoliceService {
  final http.Client _client;

  PoliceService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetch active civilian journeys authorized for the logged-in police officer's district
  Future<ApiResponse<List<PoliceJourneyModel>>> getPoliceJourneys({
    required String token,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse(ApiEndpoints.policeJourneys),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        final items = list.map((j) => PoliceJourneyModel.fromJson(j)).toList();
        return ApiResponse(
          success: true,
          data: items,
        );
      } else if (response.statusCode == 401) {
        return ApiResponse(
          success: false,
          message: 'Session expired. Please log in again.',
          data: [],
        );
      } else if (response.statusCode == 403) {
        return ApiResponse(
          success: false,
          message: 'Access restricted to police accounts only.',
          data: [],
        );
      } else {
        try {
          final data = jsonDecode(response.body);
          return ApiResponse(
            success: false,
            message: data['detail'] ?? data['message'] ?? 'Failed to retrieve active police journeys',
            data: [],
          );
        } catch (_) {
          return ApiResponse(
            success: false,
            message: 'Server error (${response.statusCode}). Please try again.',
            data: [],
          );
        }
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Unable to connect to the server',
        data: [],
      );
    }
  }

  Future<ApiResponse<List<PoliceStationModel>>> getNearbyPolice({
    required String token,
    required double lat,
    required double lon,
    double radiusKm = 10.0,
  }) async {
    try {
      final url = ApiEndpoints.nearbyPolice(lat, lon, radiusKm: radiusKm);
      final response = await _client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        final stations = list.map((s) => PoliceStationModel.fromJson(s)).toList();
        return ApiResponse(
          success: true,
          data: stations,
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to find nearby police stations',
          data: [],
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error retrieving police stations: $e',
        data: [],
      );
    }
  }
}
