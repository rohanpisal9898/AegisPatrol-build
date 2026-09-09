import 'package:latlong2/latlong.dart';
import 'journey_model.dart';

class PoliceJourneyModel {
  final String journeyId;
  final String civilianId;
  final String civilianName;
  final TravelMode travelMode;
  final String startLocationName;
  final String destinationName;
  final LatLng? startLocation;
  final LatLng? currentLocation;
  final LatLng? destination;
  final List<LatLng> routePoints;
  final JourneyStatus status;
  final RiskLevel riskLevel;
  final double riskScore;
  final DateTime? startedAt;
  final int elapsedMinutes;
  final int expectedDurationMinutes;
  final String? message;

  PoliceJourneyModel({
    required this.journeyId,
    required this.civilianId,
    required this.civilianName,
    this.travelMode = TravelMode.walk,
    this.startLocationName = 'Start Location',
    this.destinationName = 'Destination',
    this.startLocation,
    this.currentLocation,
    this.destination,
    this.routePoints = const [],
    this.status = JourneyStatus.active,
    this.riskLevel = RiskLevel.normal,
    this.riskScore = 3.2,
    this.startedAt,
    this.elapsedMinutes = 0,
    this.expectedDurationMinutes = 60,
    this.message,
  });

  double? get startLat => startLocation?.latitude;
  double? get startLng => startLocation?.longitude;
  double? get currentLat => currentLocation?.latitude;
  double? get currentLng => currentLocation?.longitude;
  double? get destLat => destination?.latitude;
  double? get destLng => destination?.longitude;

  factory PoliceJourneyModel.fromJson(Map<String, dynamic> json) {
    LatLng? parseLatLng(dynamic loc) {
      if (loc is Map<String, dynamic> && loc['lat'] != null && loc['lon'] != null) {
        return LatLng((loc['lat'] as num).toDouble(), (loc['lon'] as num).toDouble());
      }
      return null;
    }

    DateTime? parseDate(dynamic date) {
      if (date is String && date.isNotEmpty) {
        return DateTime.tryParse(date);
      }
      return null;
    }

    List<LatLng> parsedRoute = [];
    final rawRoute = json['route'];
    if (rawRoute is Map<String, dynamic> && rawRoute['coordinates'] is List) {
      for (var c in rawRoute['coordinates']) {
        if (c is List && c.length >= 2) {
          parsedRoute.add(LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()));
        }
      }
    }

    return PoliceJourneyModel(
      journeyId: json['journey_id'] ?? '',
      civilianId: json['civilian_id'] ?? '#0000',
      civilianName: json['civilian_name'] ?? 'Civilian User',
      travelMode: TravelMode.fromString(json['travel_mode']),
      startLocationName: json['start_location_name'] ?? 'Start Location',
      destinationName: json['destination_name'] ?? 'Destination',
      startLocation: parseLatLng(json['start_location']),
      currentLocation: parseLatLng(json['current_location']),
      destination: parseLatLng(json['destination']),
      routePoints: parsedRoute,
      status: JourneyStatus.fromString(json['status']),
      riskLevel: RiskLevel.fromString(json['risk_level']),
      riskScore: (json['risk_score'] as num?)?.toDouble() ?? 3.2,
      startedAt: parseDate(json['started_at']),
      elapsedMinutes: (json['elapsed_minutes'] as num?)?.toInt() ?? 0,
      expectedDurationMinutes: (json['expected_duration_minutes'] as num?)?.toInt() ?? 60,
      message: json['message'],
    );
  }
}
