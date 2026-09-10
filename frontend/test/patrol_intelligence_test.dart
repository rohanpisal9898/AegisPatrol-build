import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:aegispatrol/models/patrol_domain_models.dart';
import 'package:aegispatrol/providers/patrol_intelligence_provider.dart';

void main() {
  group('PatrolIntelligenceProvider Unit Tests', () {
    late PatrolIntelligenceProvider provider;

    setUp(() {
      provider = PatrolIntelligenceProvider();
    });

    test('Initial state generates H3 hex cells and assignments for Mumbai', () {
      expect(provider.hexCells.length, greaterThanOrEqualTo(7));
      expect(provider.assignments.length, greaterThanOrEqualTo(4));
      expect(provider.alerts.length, greaterThanOrEqualTo(5));
      expect(provider.safeJourneys.length, greaterThanOrEqualTo(4));
      expect(provider.patrolUnits.length, greaterThanOrEqualTo(3));

      // Check priority #1 assignment is Andheri East
      final topPriority = provider.topPriorityAssignment;
      expect(topPriority, isNotNull);
      expect(topPriority!.sectorName, 'Andheri East');
      expect(topPriority.rank, 1);
      expect(topPriority.riskScore, 9.1);

      // Verify Hex cell has valid 6 vertices generated
      final andheriCell = provider.hexCells.firstWhere((c) => c.id == 'hex_andheri_east');
      expect(andheriCell.polygonVertices.length, 6);
      expect(andheriCell.riskBand, RiskBand.critical);
      expect(andheriCell.neighborScores.length, 6);
    });

    test('Filter crime type works across hex cells', () {
      expect(provider.selectedCrimeFilter, 'All');
      provider.setCrimeFilter('Theft');
      expect(provider.selectedCrimeFilter, 'Theft');
      
      // Reset filter
      provider.setCrimeFilter('All');
      expect(provider.selectedCrimeFilter, 'All');
    });

    test('Selecting hex cell updates selectedHexCell', () {
      final cell = provider.hexCells.first;
      provider.selectHexCell(cell);
      expect(provider.selectedHexCell?.id, cell.id);

      provider.selectHexCell(null);
      expect(provider.selectedHexCell, isNull);
    });

    test('Route planner switches between safe and quickest modes', () {
      expect(provider.activeRoute.mode, 'safe');
      provider.setRouteMode('quickest');
      expect(provider.activeRoute.mode, 'quickest');
      expect(provider.activeRoute.distanceKm, 5.4);

      provider.setRouteMode('safe');
      expect(provider.activeRoute.mode, 'safe');
      expect(provider.activeRoute.distanceKm, 6.8);
    });

    test('Reporting an incident increases sector risk, adds alert, and prompts patrol reroute when live', () {
      final kurlaCellBefore = provider.hexCells.firstWhere((c) => c.id == 'hex_kurla');
      final kurlaScoreBefore = kurlaCellBefore.riskScore;
      final initialAlertsCount = provider.alerts.length;

      // Start live patrol first so reroute can be suggested
      provider.startLivePatrol();
      expect(provider.isLivePatrolActive, isTrue);

      provider.reportIncident(
        category: 'Assault',
        locationName: 'Kurla Station East',
        severity: 'Critical',
        description: 'Emergency assault reported near station east side',
        position: const LatLng(19.0728, 72.8794),
        sectorId: 'hex_kurla',
      );

      final kurlaCellAfter = provider.hexCells.firstWhere((c) => c.id == 'hex_kurla');
      expect(kurlaCellAfter.riskScore, greaterThan(kurlaScoreBefore));
      expect(provider.alerts.length, initialAlertsCount + 1);
      expect(provider.alerts.first.locationName, 'Kurla Station East');
      expect(provider.alerts.first.isCritical, isTrue);

      // Verify reactive reroute recommendation flag is raised
      expect(provider.hasRerouteSuggestion, isTrue);
      expect(provider.rerouteTargetSector, contains('Kurla Station East'));

      provider.endLivePatrol();
    });

    test('Trigger demo scenario CCTV Anomaly updates Andheri sector', () {
      provider.startLivePatrol();
      provider.triggerDemoScenario('cctv_andheri');

      final andheriCell = provider.hexCells.firstWhere((c) => c.id == 'hex_andheri_east');
      expect(andheriCell.riskScore, greaterThanOrEqualTo(95));
      expect(provider.hasRerouteSuggestion, isTrue);
      expect(provider.rerouteTargetSector, contains('Sector 7A'));
      provider.endLivePatrol();
    });

    test('Trigger demo scenario SOS Trigger escalates journey and raises critical alert', () {
      provider.triggerDemoScenario('sos_jogeshwari');

      expect(provider.alerts.any((a) => a.title.contains('SOS Escalated')), isTrue);
      final journey = provider.safeJourneys.firstWhere((j) => j.id == 'Journey #2487');
      expect(journey.status, SafeJourneyStatus.highRisk);
    });

    test('Accept reroute re-plans the route and dismisses banner', () {
      provider.startLivePatrol();
      provider.triggerDemoScenario('cctv_andheri');
      expect(provider.hasRerouteSuggestion, isTrue);

      provider.acceptReroute();
      expect(provider.hasRerouteSuggestion, isFalse);
      expect(provider.rerouteTargetSector, isNull);
      provider.endLivePatrol();
    });

    test('Dismiss reroute clears banner without modifying route', () {
      provider.startLivePatrol();
      provider.triggerDemoScenario('cctv_andheri');
      expect(provider.hasRerouteSuggestion, isTrue);

      provider.dismissReroute();
      expect(provider.hasRerouteSuggestion, isFalse);
      provider.endLivePatrol();
    });

    test('Acknowledge and Resolve alerts works properly', () {
      final alertId = provider.alerts.first.id;

      provider.acknowledgeAlert(alertId);
      final acknowledgedAlert = provider.alerts.firstWhere((a) => a.id == alertId);
      expect(acknowledgedAlert.status, 'Acknowledged');

      provider.resolveAlert(alertId);
      final resolvedAlert = provider.alerts.firstWhere((a) => a.id == alertId);
      expect(resolvedAlert.status, 'Resolved');
    });

    test('H3 Hex vertices generator creates closed 6-sided polygon', () {
      const center = LatLng(19.0760, 72.8777);
      final vertices = HexCell.generateHexVertices(center, 900.0);
      expect(vertices.length, 6);
      
      // All vertices should be close to center within ~1km
      for (final vertex in vertices) {
        expect((vertex.latitude - center.latitude).abs(), lessThan(0.02));
        expect((vertex.longitude - center.longitude).abs(), lessThan(0.02));
      }
    });
  });
}

