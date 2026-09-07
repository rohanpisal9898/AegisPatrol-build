import 'package:latlong2/latlong.dart';
import '../models/journey_model.dart';

class DemoStepInfo {
  final int stepIndex;
  final String title;
  final LatLng position;
  final double riskScore;
  final RiskLevel riskLevel;
  final JourneyStatus status;
  final String message;
  final double distanceKm;
  final String eta;
  final int timeRemainingMinutes;

  const DemoStepInfo({
    required this.stepIndex,
    required this.title,
    required this.position,
    required this.riskScore,
    required this.riskLevel,
    required this.status,
    required this.message,
    required this.distanceKm,
    required this.eta,
    required this.timeRemainingMinutes,
  });
}

class DemoSimulationService {
  // Predefined demo route coordinates (Bandra -> Khar -> Santacruz -> Vile Parle -> Andheri)
  static const LatLng startLocation = LatLng(19.0596, 72.8368); // Bandra West
  static const LatLng destinationLocation = LatLng(19.1197, 72.8467); // Andheri East

  static final List<LatLng> demoRoutePolyline = [
    const LatLng(19.0596, 72.8368), // Bandra
    const LatLng(19.0650, 72.8380),
    const LatLng(19.0700, 72.8395), // Khar
    const LatLng(19.0780, 72.8405),
    const LatLng(19.0880, 72.8420), // Santacruz
    const LatLng(19.0960, 72.8435), // Vile Parle
    const LatLng(19.1020, 72.8445), // Check-in point
    const LatLng(19.1120, 72.8455),
    const LatLng(19.1197, 72.8467), // Andheri East
  ];

  static final List<DemoStepInfo> demoSteps = [
    const DemoStepInfo(
      stepIndex: 0,
      title: 'Step 1: Safe Journey Started (6.8 km left)',
      position: LatLng(19.0596, 72.8368),
      riskScore: 3.2,
      riskLevel: RiskLevel.normal,
      status: JourneyStatus.active,
      message: 'You’re on a safe route. We’ll monitor your journey in real-time.',
      distanceKm: 6.8,
      eta: '10:59 PM',
      timeRemainingMinutes: 28,
    ),
    const DemoStepInfo(
      stepIndex: 1,
      title: 'Step 2: En Route Monitoring (4.8 km left)',
      position: LatLng(19.0780, 72.8405),
      riskScore: 3.6,
      riskLevel: RiskLevel.normal,
      status: JourneyStatus.active,
      message: 'You’re on a safe route.',
      distanceKm: 4.8,
      eta: '10:59 PM',
      timeRemainingMinutes: 20,
    ),
    const DemoStepInfo(
      stepIndex: 2,
      title: 'Step 3: Safety Check-in Prompt (2.8 km left)',
      position: LatLng(19.0960, 72.8435),
      riskScore: 7.2,
      riskLevel: RiskLevel.high,
      status: JourneyStatus.safetyAlert,
      message: 'We noticed an unexpected stop near your route.',
      distanceKm: 2.8,
      eta: '10:59 PM',
      timeRemainingMinutes: 12,
    ),
    const DemoStepInfo(
      stepIndex: 3,
      title: 'Step 4: Safe Route Resumed (1.1 km left)',
      position: LatLng(19.1120, 72.8455),
      riskScore: 3.4,
      riskLevel: RiskLevel.normal,
      status: JourneyStatus.active,
      message: 'You’re on a safe route.',
      distanceKm: 1.1,
      eta: '10:59 PM',
      timeRemainingMinutes: 5,
    ),
    const DemoStepInfo(
      stepIndex: 4,
      title: 'Step 5: Journey Complete (0.0 km left)',
      position: LatLng(19.1197, 72.8467),
      riskScore: 3.0,
      riskLevel: RiskLevel.normal,
      status: JourneyStatus.completed,
      message: 'You’ve reached safely.',
      distanceKm: 0.0,
      eta: '10:59 PM',
      timeRemainingMinutes: 0,
    ),
  ];
}
