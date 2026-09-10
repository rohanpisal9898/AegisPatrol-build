import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'journey_model.dart';
import 'police_journey_model.dart';

enum RiskBand {
  critical, // 81 - 100 (Deep Red)
  high,     // 61 - 80  (Red-Orange)
  moderate, // 41 - 60  (Amber/Yellow)
  low,      // 21 - 40  (Green)
  veryLow,  // 1 - 20   (Desaturated Soft Green)
}

extension RiskBandExtension on RiskBand {
  String get label {
    switch (this) {
      case RiskBand.critical:
        return 'Critical';
      case RiskBand.high:
        return 'High Risk';
      case RiskBand.moderate:
        return 'Moderate';
      case RiskBand.low:
        return 'Low';
      case RiskBand.veryLow:
        return 'Very Low';
    }
  }

  Color get color {
    switch (this) {
      case RiskBand.critical:
        return const Color(0xFFEA3F4F);
      case RiskBand.high:
        return const Color(0xFFF95738);
      case RiskBand.moderate:
        return const Color(0xFFF4A51C);
      case RiskBand.low:
        return const Color(0xFF18B875);
      case RiskBand.veryLow:
        return const Color(0xFF2E7D32);
    }
  }

  Color get fillColor {
    switch (this) {
      case RiskBand.critical:
        return const Color(0xFFEA3F4F).withValues(alpha: 0.42);
      case RiskBand.high:
        return const Color(0xFFF95738).withValues(alpha: 0.38);
      case RiskBand.moderate:
        return const Color(0xFFF4A51C).withValues(alpha: 0.32);
      case RiskBand.low:
        return const Color(0xFF18B875).withValues(alpha: 0.26);
      case RiskBand.veryLow:
        return const Color(0xFF2E7D32).withValues(alpha: 0.20);
    }
  }

  Color get badgeBg {
    switch (this) {
      case RiskBand.critical:
        return const Color(0xFFFEE2E2);
      case RiskBand.high:
        return const Color(0xFFFFEDD5);
      case RiskBand.moderate:
        return const Color(0xFFFEF3C7);
      case RiskBand.low:
      case RiskBand.veryLow:
        return const Color(0xFFD1FAE5);
    }
  }

  Color get badgeText {
    switch (this) {
      case RiskBand.critical:
        return const Color(0xFFDC2626);
      case RiskBand.high:
        return const Color(0xFFC2410C);
      case RiskBand.moderate:
        return const Color(0xFFD97706);
      case RiskBand.low:
      case RiskBand.veryLow:
        return const Color(0xFF059669);
    }
  }
}

class RiskFactors {
  final double theft;           // 0.0 - 1.0
  final double assault;         // 0.0 - 1.0
  final double vandalism;       // 0.0 - 1.0
  final double trafficViolation; // 0.0 - 1.0
  final double drugActivity;    // 0.0 - 1.0
  final double womenSafetyRisk; // 0.0 - 1.0
  final double crowdDensity;    // 0.0 - 1.0
  final double poorLighting;    // 0.0 - 1.0
  final bool cctvAnomaly;

  const RiskFactors({
    this.theft = 0.4,
    this.assault = 0.3,
    this.vandalism = 0.2,
    this.trafficViolation = 0.4,
    this.drugActivity = 0.2,
    this.womenSafetyRisk = 0.5,
    this.crowdDensity = 0.6,
    this.poorLighting = 0.4,
    this.cctvAnomaly = false,
  });

  RiskFactors copyWith({
    double? theft,
    double? assault,
    double? vandalism,
    double? trafficViolation,
    double? drugActivity,
    double? womenSafetyRisk,
    double? crowdDensity,
    double? poorLighting,
    bool? cctvAnomaly,
  }) {
    return RiskFactors(
      theft: theft ?? this.theft,
      assault: assault ?? this.assault,
      vandalism: vandalism ?? this.vandalism,
      trafficViolation: trafficViolation ?? this.trafficViolation,
      drugActivity: drugActivity ?? this.drugActivity,
      womenSafetyRisk: womenSafetyRisk ?? this.womenSafetyRisk,
      crowdDensity: crowdDensity ?? this.crowdDensity,
      poorLighting: poorLighting ?? this.poorLighting,
      cctvAnomaly: cctvAnomaly ?? this.cctvAnomaly,
    );
  }
}

class HexCell {
  final String id;
  final String h3Index;
  final String name;
  final String shortCode;
  final LatLng center;
  final List<LatLng> polygonPoints;
  final double riskScore; // 1 - 100
  final String zoneType;
  final String latDegStr;
  final String lngDegStr;
  final Map<int, double> neighborScores; // 6 neighboring hexagon scores
  final RiskFactors riskFactors;
  final List<String> whyPriorityReasons;
  final String coverage; // 'Low', 'Moderate', 'Adequate', 'Good'
  final String recommendation;
  final bool isAccidentCorridor;
  final bool isWomenSafetyPriority;
  final int incidentCount;
  final int cctvCount;
  final int activeUnitsCount;
  final DateTime lastUpdated;

  HexCell({
    required this.id,
    required this.h3Index,
    required this.name,
    required this.shortCode,
    required this.center,
    required this.polygonPoints,
    required this.riskScore,
    this.zoneType = 'Residential + Commercial',
    required this.latDegStr,
    required this.lngDegStr,
    required this.neighborScores,
    required this.riskFactors,
    required this.whyPriorityReasons,
    this.coverage = 'Moderate',
    this.recommendation = 'Maintain / increase presence',
    this.isAccidentCorridor = false,
    this.isWomenSafetyPriority = false,
    this.incidentCount = 5,
    this.cctvCount = 18,
    this.activeUnitsCount = 2,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  RiskBand get riskBand {
    if (riskScore >= 81) return RiskBand.critical;
    if (riskScore >= 61) return RiskBand.high;
    if (riskScore >= 41) return RiskBand.moderate;
    if (riskScore >= 21) return RiskBand.low;
    return RiskBand.veryLow;
  }

  double get displayScore10 => (riskScore / 10.0).clamp(1.0, 10.0);

  HexCell copyWith({
    double? riskScore,
    RiskFactors? riskFactors,
    List<String>? whyPriorityReasons,
    String? coverage,
    String? recommendation,
    int? incidentCount,
    int? activeUnitsCount,
    Map<int, double>? neighborScores,
  }) {
    return HexCell(
      id: id,
      h3Index: h3Index,
      name: name,
      shortCode: shortCode,
      center: center,
      polygonPoints: polygonPoints,
      riskScore: riskScore ?? this.riskScore,
      zoneType: zoneType,
      latDegStr: latDegStr,
      lngDegStr: lngDegStr,
      neighborScores: neighborScores ?? this.neighborScores,
      riskFactors: riskFactors ?? this.riskFactors,
      whyPriorityReasons: whyPriorityReasons ?? this.whyPriorityReasons,
      coverage: coverage ?? this.coverage,
      recommendation: recommendation ?? this.recommendation,
      isAccidentCorridor: isAccidentCorridor,
      isWomenSafetyPriority: isWomenSafetyPriority,
      incidentCount: incidentCount ?? this.incidentCount,
      cctvCount: cctvCount,
      activeUnitsCount: activeUnitsCount ?? this.activeUnitsCount,
      lastUpdated: DateTime.now(),
    );
  }

  String get sectorName => name;
  List<LatLng> get polygonVertices => polygonPoints;

  /// Mathematical Hexagon Generator (radius in meters, converts to exact LatLng coordinates)
  static List<LatLng> generateHexVertices(LatLng center, double radiusMeters) {
    const double metersPerDegreeLat = 111320.0;
    final double metersPerDegreeLon = 111320.0 * math.cos(center.latitude * math.pi / 180.0);

    final List<LatLng> vertices = [];
    for (int i = 0; i < 6; i++) {
      // 60 degrees * i + 30 degrees for pointy-topped hexagon
      final double angle = (60.0 * i + 30.0) * math.pi / 180.0;
      final double dx = radiusMeters * math.cos(angle);
      final double dy = radiusMeters * math.sin(angle);

      final double lat = center.latitude + (dy / metersPerDegreeLat);
      final double lon = center.longitude + (dx / metersPerDegreeLon);
      vertices.add(LatLng(lat, lon));
    }
    return vertices;
  }
}

class PatrolAssignment {
  final int rank;
  final String sectorName;
  final String districtName;
  final double riskScore; // out of 10 e.g. 9.1
  final String coverage;   // 'Low', 'Moderate', 'Adequate', 'Good'
  final String recommendation;
  final List<String> whyReasons;
  final LatLng location;
  final String hexId;

  const PatrolAssignment({
    required this.rank,
    required this.sectorName,
    required this.districtName,
    required this.riskScore,
    required this.coverage,
    required this.recommendation,
    required this.whyReasons,
    required this.location,
    required this.hexId,
  });

  Color get coverageColor {
    switch (coverage.toLowerCase()) {
      case 'low':
        return const Color(0xFFEF4444);
      case 'moderate':
        return const Color(0xFFF59E0B);
      case 'adequate':
        return const Color(0xFFF4A51C);
      case 'good':
      default:
        return const Color(0xFF10B981);
    }
  }

  Color get riskBadgeColor {
    if (riskScore >= 8.5) return const Color(0xFFEF4444);
    if (riskScore >= 7.0) return const Color(0xFFF97316);
    if (riskScore >= 5.5) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  Color get riskBadgeBg {
    if (riskScore >= 8.5) return const Color(0xFFFEE2E2);
    if (riskScore >= 7.0) return const Color(0xFFFFEDD5);
    if (riskScore >= 5.5) return const Color(0xFFFEF3C7);
    return const Color(0xFFD1FAE5);
  }

  Color get rankCircleColor {
    switch (rank) {
      case 1:
        return const Color(0xFFEF4444);
      case 2:
        return const Color(0xFFF97316);
      case 3:
        return const Color(0xFFF59E0B);
      case 4:
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF64748B);
    }
  }
}

enum AlertSeverity {
  critical,
  high,
  medium,
  resolved,
}

enum AlertIconCategory {
  womenSafety,
  accident,
  cctv,
  crowd,
  routeDeviation,
  resolvedCheck,
  theft,
  vandalism,
}

class PatrolAlert {
  final String id;
  final AlertSeverity severity;
  final AlertIconCategory iconCategory;
  final String title;
  final String locationName;
  final String timeAgo;
  final String description;
  final String status; // 'Active', 'Acknowledged', 'Resolved'
  final LatLng position;
  final String sectorId;

  const PatrolAlert({
    required this.id,
    required this.severity,
    required this.iconCategory,
    required this.title,
    required this.locationName,
    required this.timeAgo,
    required this.description,
    this.status = 'Active',
    required this.position,
    required this.sectorId,
  });

  bool get isCritical => severity == AlertSeverity.critical;
  String get sectorName => locationName;

  Color get severityBadgeColor {
    switch (severity) {
      case AlertSeverity.critical:
        return const Color(0xFFDC2626);
      case AlertSeverity.high:
        return const Color(0xFFEA580C);
      case AlertSeverity.medium:
        return const Color(0xFFD97706);
      case AlertSeverity.resolved:
        return const Color(0xFF059669);
    }
  }

  Color get severityBadgeBg {
    switch (severity) {
      case AlertSeverity.critical:
        return const Color(0xFFFEE2E2);
      case AlertSeverity.high:
        return const Color(0xFFFFEDD5);
      case AlertSeverity.medium:
        return const Color(0xFFFEF3C7);
      case AlertSeverity.resolved:
        return const Color(0xFFD1FAE5);
    }
  }

  Color get iconColor {
    switch (severity) {
      case AlertSeverity.critical:
        return const Color(0xFFEF4444);
      case AlertSeverity.high:
        return const Color(0xFFF97316);
      case AlertSeverity.medium:
        return const Color(0xFFF59E0B);
      case AlertSeverity.resolved:
        return const Color(0xFF10B981);
    }
  }

  Color get iconBgColor {
    switch (severity) {
      case AlertSeverity.critical:
        return const Color(0xFFFEE2E2);
      case AlertSeverity.high:
        return const Color(0xFFFFEDD5);
      case AlertSeverity.medium:
        return const Color(0xFFFEF3C7);
      case AlertSeverity.resolved:
        return const Color(0xFFD1FAE5);
    }
  }

  IconData get icon {
    switch (iconCategory) {
      case AlertIconCategory.womenSafety:
        return Icons.person_rounded;
      case AlertIconCategory.accident:
        return Icons.directions_car_rounded;
      case AlertIconCategory.cctv:
        return Icons.videocam_rounded;
      case AlertIconCategory.crowd:
        return Icons.groups_rounded;
      case AlertIconCategory.routeDeviation:
        return Icons.alt_route_rounded;
      case AlertIconCategory.resolvedCheck:
        return Icons.check_circle_rounded;
      case AlertIconCategory.theft:
        return Icons.warning_amber_rounded;
      case AlertIconCategory.vandalism:
        return Icons.shield_outlined;
    }
  }

  PatrolAlert copyWith({
    String? status,
    AlertSeverity? severity,
    String? timeAgo,
  }) {
    return PatrolAlert(
      id: id,
      severity: severity ?? this.severity,
      iconCategory: iconCategory,
      title: title,
      locationName: locationName,
      timeAgo: timeAgo ?? this.timeAgo,
      description: description,
      status: status ?? this.status,
      position: position,
      sectorId: sectorId,
    );
  }
}

enum SafeJourneyStatus {
  normal,
  attention,
  highRisk,
}

class SafeJourneyItem {
  final String id;
  final String civilianName;
  final String startLocation;
  final String destination;
  final String travelMode; // 'Cab', 'Auto', 'Walk', 'Metro'
  final String eta;
  final int durationMinutes;
  final int elapsedMinutes;
  final SafeJourneyStatus status;
  final double riskScore;
  final String statusReason;
  final LatLng currentPos;
  final LatLng destPos;
  final List<LatLng> routePoints;
  final String? district;

  const SafeJourneyItem({
    required this.id,
    required this.civilianName,
    required this.startLocation,
    required this.destination,
    required this.travelMode,
    required this.eta,
    required this.durationMinutes,
    this.elapsedMinutes = 12,
    required this.status,
    required this.riskScore,
    required this.statusReason,
    required this.currentPos,
    required this.destPos,
    required this.routePoints,
    this.district,
  });

  factory SafeJourneyItem.fromPoliceJourneyModel(PoliceJourneyModel m) {
    SafeJourneyStatus st = SafeJourneyStatus.normal;
    if (m.riskLevel == RiskLevel.high || m.status == JourneyStatus.safetyAlert) {
      st = SafeJourneyStatus.highRisk;
    } else if (m.riskLevel == RiskLevel.unusual || m.status == JourneyStatus.unusualActivity) {
      st = SafeJourneyStatus.attention;
    }

    final currentPos = m.currentLocation ?? m.startLocation ?? const LatLng(19.0596, 72.8368);
    final destPos = m.destination ?? currentPos;
    final routePoints = m.routePoints.isNotEmpty ? m.routePoints : [currentPos, destPos];

    final now = DateTime.now();
    final remainingMinutes = (m.expectedDurationMinutes - m.elapsedMinutes).clamp(1, 180);
    final etaTime = now.add(Duration(minutes: remainingMinutes));
    final etaHour = etaTime.hour % 12 == 0 ? 12 : etaTime.hour % 12;
    final etaAmPm = etaTime.hour >= 12 ? 'PM' : 'AM';
    final etaStr = '${etaHour.toString().padLeft(2, '0')}:${etaTime.minute.toString().padLeft(2, '0')} $etaAmPm';

    String modeStr = 'Walk';
    if (m.travelMode == TravelMode.cab) {
      modeStr = 'Cab';
    } else if (m.travelMode == TravelMode.bus) {
      modeStr = 'Bus';
    } else if (m.travelMode == TravelMode.auto) {
      modeStr = 'Auto';
    }

    final shortId = m.civilianId.isNotEmpty && m.civilianId.startsWith('#')
        ? m.civilianId
        : (m.journeyId.length >= 4 ? '#${m.journeyId.substring(m.journeyId.length - 4).toUpperCase()}' : '#0000');

    return SafeJourneyItem(
      id: 'Journey $shortId',
      civilianName: m.civilianName,
      startLocation: m.startLocationName,
      destination: m.destinationName,
      travelMode: modeStr,
      eta: etaStr,
      durationMinutes: m.expectedDurationMinutes,
      elapsedMinutes: m.elapsedMinutes,
      status: st,
      riskScore: m.riskScore,
      statusReason: m.message ??
          (st == SafeJourneyStatus.highRisk
              ? 'SOS Assistance Active'
              : (st == SafeJourneyStatus.attention
                  ? 'Route deviation / unusual stop detected'
                  : 'On track with steady progress')),
      currentPos: currentPos,
      destPos: destPos,
      routePoints: routePoints,
      district: m.district,
    );
  }

  Color get statusBadgeBg {
    switch (status) {
      case SafeJourneyStatus.normal:
        return const Color(0xFFD1FAE5);
      case SafeJourneyStatus.attention:
        return const Color(0xFFFEF3C7);
      case SafeJourneyStatus.highRisk:
        return const Color(0xFFFEE2E2);
    }
  }

  Color get statusBadgeColor {
    switch (status) {
      case SafeJourneyStatus.normal:
        return const Color(0xFF059669);
      case SafeJourneyStatus.attention:
        return const Color(0xFFD97706);
      case SafeJourneyStatus.highRisk:
        return const Color(0xFFDC2626);
    }
  }

  IconData get travelModeIcon {
    switch (travelMode.toLowerCase()) {
      case 'cab':
        return Icons.local_taxi_rounded;
      case 'auto':
        return Icons.electric_rickshaw_rounded;
      case 'metro':
        return Icons.subway_rounded;
      default:
        return Icons.directions_walk_rounded;
    }
  }

  SafeJourneyItem copyWith({
    SafeJourneyStatus? status,
    String? statusReason,
    double? riskScore,
    LatLng? currentPos,
    String? district,
  }) {
    return SafeJourneyItem(
      id: id,
      civilianName: civilianName,
      startLocation: startLocation,
      destination: destination,
      travelMode: travelMode,
      eta: eta,
      durationMinutes: durationMinutes,
      elapsedMinutes: elapsedMinutes,
      status: status ?? this.status,
      riskScore: riskScore ?? this.riskScore,
      statusReason: statusReason ?? this.statusReason,
      currentPos: currentPos ?? this.currentPos,
      destPos: destPos,
      routePoints: routePoints,
      district: district ?? this.district,
    );
  }
}

enum PatrolUnitState {
  onRoute,
  atLocation,
  available,
}

class PatrolUnit {
  final String id;
  final String officerName;
  final String sectorName;
  final int speedKmH;
  final PatrolUnitState state;
  final LatLng position;
  final int batteryLevel;

  const PatrolUnit({
    required this.id,
    required this.officerName,
    required this.sectorName,
    required this.speedKmH,
    required this.state,
    required this.position,
    this.batteryLevel = 88,
  });

  String get stateLabel {
    switch (state) {
      case PatrolUnitState.onRoute:
        return 'On Route';
      case PatrolUnitState.atLocation:
        return 'At Location';
      case PatrolUnitState.available:
        return 'Available';
    }
  }

  Color get stateColor {
    switch (state) {
      case PatrolUnitState.onRoute:
        return const Color(0xFF10B981);
      case PatrolUnitState.atLocation:
        return const Color(0xFF3B82F6);
      case PatrolUnitState.available:
        return const Color(0xFF64748B);
    }
  }

  Color get stateBg {
    switch (state) {
      case PatrolUnitState.onRoute:
        return const Color(0xFF0F392B);
      case PatrolUnitState.atLocation:
        return const Color(0xFF143054);
      case PatrolUnitState.available:
        return const Color(0xFF1E293B);
    }
  }

  PatrolUnit copyWith({
    PatrolUnitState? state,
    int? speedKmH,
    LatLng? position,
    String? sectorName,
  }) {
    return PatrolUnit(
      id: id,
      officerName: officerName,
      sectorName: sectorName ?? this.sectorName,
      speedKmH: speedKmH ?? this.speedKmH,
      state: state ?? this.state,
      position: position ?? this.position,
      batteryLevel: batteryLevel,
    );
  }
}

class PatrolStop {
  final int index;
  final String name;
  final String riskTag;
  final double distanceKm;
  final LatLng position;

  const PatrolStop({
    required this.index,
    required this.name,
    required this.riskTag,
    required this.distanceKm,
    required this.position,
  });
}

class PatrolRouteInfo {
  final String mode; // 'safe' or 'quickest'
  final double distanceKm;
  final int estTimeMinutes;
  final LatLng startLocation;
  final LatLng endLocation;
  final String startName;
  final String endName;
  final int highRiskAreas;
  final int mediumRiskAreas;
  final int lowRiskAreas;
  final List<PatrolStop> stops;
  final List<LatLng> polylinePoints;
  final bool avoidHighRiskZones;
  final bool preferMainRoads;
  final bool includePoliceCheckpoints;

  const PatrolRouteInfo({
    required this.mode,
    required this.distanceKm,
    required this.estTimeMinutes,
    required this.startLocation,
    required this.endLocation,
    required this.startName,
    required this.endName,
    required this.highRiskAreas,
    required this.mediumRiskAreas,
    required this.lowRiskAreas,
    required this.stops,
    required this.polylinePoints,
    this.avoidHighRiskZones = true,
    this.preferMainRoads = true,
    this.includePoliceCheckpoints = false,
  });

  PatrolRouteInfo copyWith({
    String? mode,
    double? distanceKm,
    int? estTimeMinutes,
    LatLng? startLocation,
    LatLng? endLocation,
    String? startName,
    String? endName,
    List<PatrolStop>? stops,
    List<LatLng>? polylinePoints,
    bool? avoidHighRiskZones,
    bool? preferMainRoads,
    bool? includePoliceCheckpoints,
    int? highRiskAreas,
    int? mediumRiskAreas,
    int? lowRiskAreas,
  }) {
    return PatrolRouteInfo(
      mode: mode ?? this.mode,
      distanceKm: distanceKm ?? this.distanceKm,
      estTimeMinutes: estTimeMinutes ?? this.estTimeMinutes,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      startName: startName ?? this.startName,
      endName: endName ?? this.endName,
      highRiskAreas: highRiskAreas ?? this.highRiskAreas,
      mediumRiskAreas: mediumRiskAreas ?? this.mediumRiskAreas,
      lowRiskAreas: lowRiskAreas ?? this.lowRiskAreas,
      stops: stops ?? this.stops,
      polylinePoints: polylinePoints ?? this.polylinePoints,
      avoidHighRiskZones: avoidHighRiskZones ?? this.avoidHighRiskZones,
      preferMainRoads: preferMainRoads ?? this.preferMainRoads,
      includePoliceCheckpoints: includePoliceCheckpoints ?? this.includePoliceCheckpoints,
    );
  }
}
