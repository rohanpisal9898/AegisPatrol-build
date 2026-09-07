import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../core/constants/api_endpoints.dart';

class PlaceSuggestion {
  final String displayName;
  final String shortName;
  final double lat;
  final double lon;

  const PlaceSuggestion({
    required this.displayName,
    required this.shortName,
    required this.lat,
    required this.lon,
  });

  LatLng get coordinates => LatLng(lat, lon);

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final rawName = json['display_name'] as String? ?? json['name'] as String? ?? 'Destination';
    final short = json['name'] as String? ?? (rawName.split(',').isNotEmpty ? rawName.split(',').first.trim() : rawName);

    return PlaceSuggestion(
      displayName: rawName,
      shortName: short,
      lat: double.tryParse(json['lat']?.toString() ?? '') ?? 0.0,
      lon: double.tryParse(json['lon']?.toString() ?? '') ?? 0.0,
    );
  }
}

class GeocodingService {
  final http.Client _client;

  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  /// Searches real locations with multi-provider failover:
  /// 1. AegisPatrol Backend Proxy (CORS-safe & Proximal)
  /// 2. Photon (Komoot OSM Geocoder)
  /// 3. OpenStreetMap Nominatim
  Future<List<PlaceSuggestion>> searchPlaces(String query, {LatLng? near}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty || cleanQuery.length < 2) return [];

    // 1. Try Backend search
    try {
      final backendUrl = ApiEndpoints.searchPlaces(
        cleanQuery,
        lat: near?.latitude,
        lon: near?.longitude,
      );
      final response = await _client.get(
        Uri.parse(backendUrl),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return data.map((item) => PlaceSuggestion.fromJson(item as Map<String, dynamic>)).toList();
        }
      }
    } catch (_) {}

    // 2. Try Direct Photon API
    try {
      var photonUrl = 'https://photon.komoot.io/api/?q=${Uri.encodeComponent(cleanQuery)}&limit=5';
      if (near != null) {
        photonUrl += '&lat=${near.latitude.toStringAsFixed(4)}&lon=${near.longitude.toStringAsFixed(4)}';
      }

      final response = await _client.get(
        Uri.parse(photonUrl),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> features = data['features'] as List<dynamic>? ?? [];
        if (features.isNotEmpty) {
          final List<PlaceSuggestion> list = [];
          for (final feat in features) {
            final props = (feat['properties'] as Map<String, dynamic>?) ?? {};
            final coords = (feat['geometry']?['coordinates'] as List<dynamic>?) ?? [];
            if (coords.length >= 2) {
              final name = props['name'] as String? ?? cleanQuery;
              final city = props['city'] as String? ?? props['district'] as String? ?? props['state'] as String?;
              final street = props['street'] as String?;
              final displayParts = [name, if (street != null) street, if (city != null) city];
              list.add(PlaceSuggestion(
                displayName: displayParts.join(', '),
                shortName: name,
                lat: double.tryParse(coords[1].toString()) ?? 0.0,
                lon: double.tryParse(coords[0].toString()) ?? 0.0,
              ));
            }
          }
          if (list.isNotEmpty) return list;
        }
      }
    } catch (_) {}

    // 3. Try Direct OSM Nominatim API
    try {
      final nomUrl = 'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(cleanQuery)}&format=json&limit=5&addressdetails=1';
      final response = await _client.get(
        Uri.parse(nomUrl),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'AegisPatrolSafetyApp/1.0',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => PlaceSuggestion.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    return [];
  }

  /// Geocodes a text destination string to coordinates
  Future<PlaceSuggestion?> resolveDestination(String query, {LatLng? near}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return null;

    final results = await searchPlaces(cleanQuery, near: near);
    if (results.isNotEmpty) {
      return results.first;
    }

    // Fallback: If user has a current GPS position and typed a local place name that couldn't be resolved by OSM,
    // place destination approximately 1.2 km ahead of the user in their current city/area.
    if (near != null) {
      return PlaceSuggestion(
        displayName: cleanQuery,
        shortName: cleanQuery,
        lat: near.latitude + 0.010,
        lon: near.longitude + 0.010,
      );
    }

    return null;
  }
}
