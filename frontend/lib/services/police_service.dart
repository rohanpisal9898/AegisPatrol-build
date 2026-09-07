import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_endpoints.dart';
import '../models/police_station_model.dart';
import 'api_service.dart';

class PoliceService {
  final http.Client _client;

  PoliceService({http.Client? client}) : _client = client ?? http.Client();

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
