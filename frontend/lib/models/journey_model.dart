import 'package:latlong2/latlong.dart';

enum JourneyStatus {
  notStarted,
  planning,
  active,
  unusualActivity,
  safetyAlert,
  completed,
  cancelled;

  static JourneyStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'not_started':
        return JourneyStatus.notStarted;
      case 'planning':
        return JourneyStatus.planning;
      case 'active':
        return JourneyStatus.active;
      case 'unusual_activity':
      case 'unusual':
        return JourneyStatus.unusualActivity;
      case 'safety_alert':
        return JourneyStatus.safetyAlert;
      case 'completed':
        return JourneyStatus.completed;
      case 'cancelled':
        return JourneyStatus.cancelled;
      default:
        return JourneyStatus.notStarted;
    }
  }

  String toApiString() {
    switch (this) {
      case JourneyStatus.notStarted:
        return 'not_started';
      case JourneyStatus.planning:
        return 'planning';
      case JourneyStatus.active:
        return 'active';
      case JourneyStatus.unusualActivity:
        return 'unusual_activity';
      case JourneyStatus.safetyAlert:
        return 'safety_alert';
      case JourneyStatus.completed:
        return 'completed';
      case JourneyStatus.cancelled:
        return 'cancelled';
    }
  }
}

enum RiskLevel {
  normal,
  unusual,
  high;

  static RiskLevel fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'unusual':
        return RiskLevel.unusual;
      case 'high':
        return RiskLevel.high;
      case 'normal':
      default:
        return RiskLevel.normal;
    }
  }

  String toApiString() {
    switch (this) {
      case RiskLevel.normal:
        return 'normal';
      case RiskLevel.unusual:
        return 'unusual';
      case RiskLevel.high:
        return 'high';
    }
  }
}

enum TravelMode {
  walk,
  auto,
  bus,
  cab;

  static TravelMode fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'auto':
        return TravelMode.auto;
      case 'bus':
        return TravelMode.bus;
      case 'cab':
        return TravelMode.cab;
      case 'walk':
      default:
        return TravelMode.walk;
    }
  }

  String toApiString() {
    switch (this) {
      case TravelMode.walk:
        return 'walk';
      case TravelMode.auto:
        return 'auto';
      case TravelMode.bus:
        return 'bus';
      case TravelMode.cab:
        return 'cab';
    }
  }

  String get label {
    switch (this) {
      case TravelMode.walk:
        return 'Walk';
      case TravelMode.auto:
        return 'Auto';
      case TravelMode.bus:
        return 'Bus';
      case TravelMode.cab:
        return 'Cab';
    }
  }
}

class GeoPoint {
  final double lat;
  final double lon;

  const GeoPoint({required this.lat, required this.lon});

  LatLng toLatLng() => LatLng(lat, lon);

  factory GeoPoint.fromJson(Map<String, dynamic> json) {
    return GeoPoint(
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {'lat': lat, 'lon': lon};
}

class RouteData {
  final double distanceKm;
  final double durationMinutes;
  final List<LatLng> points;

  const RouteData({
    required this.distanceKm,
    required this.durationMinutes,
    required this.points,
  });

  factory RouteData.fromJson(Map<String, dynamic> json) {
    final rawCoords = json['coordinates'] as List<dynamic>? ?? [];
    final List<LatLng> parsedPoints = [];
    for (var c in rawCoords) {
      if (c is List && c.length >= 2) {
        // GeoJSON coordinate order is [lon, lat]
        parsedPoints.add(LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()));
      }
    }

    return RouteData(
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: (json['duration_minutes'] as num?)?.toDouble() ?? 0.0,
      points: parsedPoints,
    );
  }
}

class JourneyModel {
  final String id;
  final String userId;
  final JourneyStatus status;
  final TravelMode travelMode;
  final GeoPoint? startLocation;
  final String? startLocationName;
  final GeoPoint? currentLocation;
  final GeoPoint? destination;
  final String? destinationName;
  final RouteData? route;
  final double distanceKm;
  final int expectedDurationMinutes;
  final double? actualDurationMinutes;
  final double riskScore;
  final RiskLevel riskLevel;
  final String? message;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? createdAt;

  const JourneyModel({
    required this.id,
    required this.userId,
    required this.status,
    required this.travelMode,
    this.startLocation,
    this.startLocationName,
    this.currentLocation,
    this.destination,
    this.destinationName,
    this.route,
    required this.distanceKm,
    required this.expectedDurationMinutes,
    this.actualDurationMinutes,
    required this.riskScore,
    required this.riskLevel,
    this.message,
    this.startedAt,
    this.endedAt,
    this.createdAt,
  });

  factory JourneyModel.fromJson(Map<String, dynamic> json) {
    return JourneyModel(
      id: json['journey_id'] ?? json['id'] ?? '',
      userId: json['user_id'] ?? '',
      status: JourneyStatus.fromString(json['status']),
      travelMode: TravelMode.fromString(json['travel_mode']),
      startLocation: json['start_location'] != null
          ? GeoPoint.fromJson(json['start_location'])
          : null,
      startLocationName: json['start_location_name'],
      currentLocation: json['current_location'] != null
          ? GeoPoint.fromJson(json['current_location'])
          : null,
      destination: json['destination'] != null
          ? GeoPoint.fromJson(json['destination'])
          : null,
      destinationName: json['destination_name'],
      route: json['route'] != null ? RouteData.fromJson(json['route']) : null,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      expectedDurationMinutes: (json['expected_duration_minutes'] as num?)?.toInt() ?? 30,
      actualDurationMinutes: (json['actual_duration_minutes'] as num?)?.toDouble(),
      riskScore: (json['risk_score'] as num?)?.toDouble() ?? 0.0,
      riskLevel: RiskLevel.fromString(json['risk_level']),
      message: json['message'],
      startedAt: json['started_at'] != null ? DateTime.tryParse(json['started_at']) : null,
      endedAt: json['ended_at'] != null ? DateTime.tryParse(json['ended_at']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}
