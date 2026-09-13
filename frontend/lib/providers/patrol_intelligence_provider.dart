import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/patrol_domain_models.dart';

class PatrolIntelligenceProvider extends ChangeNotifier {
  // Theme mode: Default to Dark (Reference A Command Centre) with toggle to Light (Reference B)
  bool _isDarkMode = true;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setTheme(bool dark) {
    _isDarkMode = dark;
    notifyListeners();
  }

  // City Selector
  String _selectedCity = 'Mumbai';
  String get selectedCity => _selectedCity;
  final List<String> supportedCities = const ['Mumbai', 'Delhi', 'Bengaluru', 'Hyderabad', 'Pune'];

  void selectCity(String city) {
    _selectedCity = city;
    notifyListeners();
  }

  // Active Crime Category Filter on Map
  String _activeCategoryFilter = 'All';
  String get activeCategoryFilter => _activeCategoryFilter;
  String get selectedCrimeFilter => _activeCategoryFilter;
  void setCrimeFilter(String cat) => setCategoryFilter(cat);
  final List<String> crimeCategories = const ['All', 'Theft', 'Assault', 'Traffic', 'Vandalism'];

  void setCategoryFilter(String category) {
    _activeCategoryFilter = category;
    notifyListeners();
  }

  // Hexagonal Geospatial Risk Grid
  late List<HexCell> _hexCells;
  List<HexCell> get hexCells => _hexCells;

  HexCell? _selectedHexCell;
  HexCell? get selectedHexCell => _selectedHexCell;

  void selectHexCell(HexCell? cell) {
    _selectedHexCell = cell;
    notifyListeners();
  }

  // Assignments List
  late List<PatrolAssignment> _assignments;
  List<PatrolAssignment> get assignments => _assignments;
  PatrolAssignment? get topPriorityAssignment => _assignments.isNotEmpty ? _assignments.first : null;
  String _assignmentsTab = 'Priority List'; // 'Priority List' or 'Recent Updates'
  String get assignmentsTab => _assignmentsTab;

  void setAssignmentsTab(String tab) {
    _assignmentsTab = tab;
    notifyListeners();
  }

  // Alerts List
  late List<PatrolAlert> _alerts;
  List<PatrolAlert> get alerts => _alerts;
  String _activeAlertTab = 'All'; // 'All', 'Critical', 'High', 'Medium', 'Resolved'
  String get activeAlertTab => _activeAlertTab;

  void setAlertTab(String tab) {
    _activeAlertTab = tab;
    notifyListeners();
  }

  void setAlerts(List<PatrolAlert> alerts) {
    _alerts = alerts;
    notifyListeners();
  }

  void mergeLiveAlerts(List<PatrolAlert> liveAlerts) {
    final Map<String, PatrolAlert> alertMap = {};
    for (final a in liveAlerts) {
      alertMap[a.id] = a;
    }
    for (final a in _alerts) {
      if (!alertMap.containsKey(a.id)) {
        alertMap[a.id] = a;
      }
    }
    final merged = alertMap.values.toList();
    merged.sort((a, b) {
      if (a.status == 'Active' && b.status != 'Active') return -1;
      if (a.status != 'Active' && b.status == 'Active') return 1;
      if (a.isCritical && !b.isCritical) return -1;
      if (!a.isCritical && b.isCritical) return 1;
      return 0;
    });
    _alerts = merged;
    notifyListeners();
  }

  // Safe Journeys List
  late List<SafeJourneyItem> _safeJourneys;
  List<SafeJourneyItem> get safeJourneys => _safeJourneys;

  void setSafeJourneys(List<SafeJourneyItem> items) {
    _safeJourneys = items;
    notifyListeners();
  }

  // Patrol Units
  late List<PatrolUnit> _patrolUnits;
  List<PatrolUnit> get patrolUnits => _patrolUnits;

  // Patrol Route Planning & Live Patrol
  late PatrolRouteInfo _activeRoute;
  PatrolRouteInfo get activeRoute => _activeRoute;

  bool _isLivePatrolActive = false;
  bool get isLivePatrolActive => _isLivePatrolActive;

  int _currentPatrolStep = 0;
  Timer? _patrolSimulationTimer;

  bool _hasPendingReroute = false;
  bool get hasPendingReroute => _hasPendingReroute;
  bool get hasRerouteSuggestion => _hasPendingReroute;
  String _rerouteReason = '';
  String get rerouteReason => _rerouteReason;
  String? get rerouteTargetSector => _rerouteReason.isNotEmpty ? _rerouteReason : null;

  void acceptReroute() => applyReroute();
  void dismissReroute() => dismissPendingReroute();
  void dismissPendingReroute() {
    _hasPendingReroute = false;
    _rerouteReason = '';
    notifyListeners();
  }

  // Dispatch Summary Stats
  int get totalIncidentsToday => 48 + (_alerts.where((a) => a.id.startsWith('new_')).length);
  int get criticalIncidentsCount => _alerts.where((a) => a.severity == AlertSeverity.critical).length;
  int get highIncidentsCount => _alerts.where((a) => a.severity == AlertSeverity.high).length;
  int get mediumIncidentsCount => _alerts.where((a) => a.severity == AlertSeverity.medium).length;
  int get lowIncidentsCount => 12;

  PatrolIntelligenceProvider() {
    _initializeBaselineData();
  }

  @override
  void dispose() {
    _patrolSimulationTimer?.cancel();
    super.dispose();
  }

  void _initializeBaselineData() {
    // 1. Initialize Mumbai H3 Hexagonal Grid
    _hexCells = [
      HexCell(
        id: 'hex_andheri_east',
        h3Index: '886189258ffffff',
        name: 'Sector 7A - Andheri East',
        shortCode: 'Sector 7A',
        center: const LatLng(19.1197, 72.8468),
        polygonPoints: HexCell.generateHexVertices(const LatLng(19.1197, 72.8468), 1250),
        riskScore: 92.0,
        zoneType: 'Residential + Commercial',
        latDegStr: '19.1197° N',
        lngDegStr: '72.8468° E',
        neighborScores: {0: 68.0, 1: 54.0, 2: 37.0, 3: 48.0, 4: 72.0, 5: 61.0},
        riskFactors: const RiskFactors(
          theft: 0.88,
          assault: 0.64,
          vandalism: 0.32,
          trafficViolation: 0.58,
          drugActivity: 0.28,
          womenSafetyRisk: 0.85,
          crowdDensity: 0.76,
          poorLighting: 0.65,
          cctvAnomaly: true,
        ),
        whyPriorityReasons: [
          'High risk score (9.2)',
          "Women's safety activity",
          'CCTV anomaly',
        ],
        coverage: 'Low',
        recommendation: 'Increase patrol presence',
        incidentCount: 14,
        isWomenSafetyPriority: true,
        activeUnitsCount: 1,
      ),
      HexCell(
        id: 'hex_kurla',
        h3Index: '886189259ffffff',
        name: 'Sector 5B - Kurla',
        shortCode: 'Sector 5B',
        center: const LatLng(19.0728, 72.8794),
        polygonPoints: HexCell.generateHexVertices(const LatLng(19.0728, 72.8794), 1250),
        riskScore: 83.0,
        zoneType: 'Transit Hub + Market',
        latDegStr: '19.0728° N',
        lngDegStr: '72.8794° E',
        neighborScores: {0: 72.0, 1: 65.0, 2: 50.0, 3: 42.0, 4: 68.0, 5: 75.0},
        riskFactors: const RiskFactors(
          theft: 0.80,
          assault: 0.70,
          vandalism: 0.45,
          trafficViolation: 0.62,
          drugActivity: 0.35,
          womenSafetyRisk: 0.78,
          crowdDensity: 0.88,
          poorLighting: 0.50,
          cctvAnomaly: false,
        ),
        whyPriorityReasons: [
          'Increased incident activity',
          'High journey exposure',
          'Limited current coverage',
        ],
        coverage: 'Moderate',
        recommendation: 'Maintain / increase presence',
        incidentCount: 11,
        activeUnitsCount: 2,
      ),
      HexCell(
        id: 'hex_bandra_west',
        h3Index: '88618925affffff',
        name: 'Sector 3C - Bandra West',
        shortCode: 'Sector 3C',
        center: const LatLng(19.0596, 72.8368),
        polygonPoints: HexCell.generateHexVertices(const LatLng(19.0596, 72.8368), 1250),
        riskScore: 67.0,
        zoneType: 'Commercial + Nightlife',
        latDegStr: '19.0596° N',
        lngDegStr: '72.8368° E',
        neighborScores: {0: 55.0, 1: 45.0, 2: 30.0, 3: 38.0, 4: 52.0, 5: 60.0},
        riskFactors: const RiskFactors(
          theft: 0.58,
          assault: 0.42,
          vandalism: 0.38,
          trafficViolation: 0.72,
          drugActivity: 0.30,
          womenSafetyRisk: 0.45,
          crowdDensity: 0.80,
          poorLighting: 0.25,
          cctvAnomaly: false,
        ),
        whyPriorityReasons: [
          'Accident-prone zone',
          'Elevated CCTV activity',
        ],
        coverage: 'Adequate',
        recommendation: 'Routine patrol',
        incidentCount: 7,
        isAccidentCorridor: true,
        activeUnitsCount: 3,
      ),
      HexCell(
        id: 'hex_goregaon',
        h3Index: '88618925bffffff',
        name: 'Sector 8D - Goregaon',
        shortCode: 'Sector 8D',
        center: const LatLng(19.1663, 72.8526),
        polygonPoints: HexCell.generateHexVertices(const LatLng(19.1663, 72.8526), 1250),
        riskScore: 42.0,
        zoneType: 'Residential + IT Park',
        latDegStr: '19.1663° N',
        lngDegStr: '72.8526° E',
        neighborScores: {0: 38.0, 1: 32.0, 2: 25.0, 3: 28.0, 4: 35.0, 5: 40.0},
        riskFactors: const RiskFactors(
          theft: 0.35,
          assault: 0.22,
          vandalism: 0.18,
          trafficViolation: 0.40,
          drugActivity: 0.15,
          womenSafetyRisk: 0.30,
          crowdDensity: 0.45,
          poorLighting: 0.20,
          cctvAnomaly: false,
        ),
        whyPriorityReasons: [
          'Risk levels are within normal range',
        ],
        coverage: 'Good',
        recommendation: 'No additional units required',
        incidentCount: 3,
        activeUnitsCount: 2,
      ),
      HexCell(
        id: 'hex_powai',
        h3Index: '88618925cffffff',
        name: 'Sector 6C - Powai',
        shortCode: 'Sector 6C',
        center: const LatLng(19.1176, 72.9060),
        polygonPoints: HexCell.generateHexVertices(const LatLng(19.1176, 72.9060), 1250),
        riskScore: 71.0,
        zoneType: 'Tech Hub + Residential',
        latDegStr: '19.1176° N',
        lngDegStr: '72.9060° E',
        neighborScores: {0: 60.0, 1: 52.0, 2: 45.0, 3: 38.0, 4: 55.0, 5: 64.0},
        riskFactors: const RiskFactors(
          theft: 0.65,
          assault: 0.35,
          vandalism: 0.25,
          trafficViolation: 0.55,
          drugActivity: 0.20,
          womenSafetyRisk: 0.62,
          crowdDensity: 0.60,
          poorLighting: 0.40,
          cctvAnomaly: false,
        ),
        whyPriorityReasons: [
          'Evening commute transit congestion',
          'Isolated lake promenade stretches',
        ],
        coverage: 'Low',
        recommendation: 'Deploy evening checkpoint',
        incidentCount: 6,
        isWomenSafetyPriority: true,
        activeUnitsCount: 1,
      ),
      HexCell(
        id: 'hex_sion',
        h3Index: '88618925dffffff',
        name: 'Sector 4A - Sion',
        shortCode: 'Sector 4A',
        center: const LatLng(19.0400, 72.8620),
        polygonPoints: HexCell.generateHexVertices(const LatLng(19.0400, 72.8620), 1250),
        riskScore: 58.0,
        zoneType: 'Highway Interchange + Transit',
        latDegStr: '19.0400° N',
        lngDegStr: '72.8620° E',
        neighborScores: {0: 50.0, 1: 46.0, 2: 35.0, 3: 40.0, 4: 55.0, 5: 58.0},
        riskFactors: const RiskFactors(
          theft: 0.50,
          assault: 0.40,
          vandalism: 0.30,
          trafficViolation: 0.75,
          drugActivity: 0.25,
          womenSafetyRisk: 0.48,
          crowdDensity: 0.70,
          poorLighting: 0.35,
          cctvAnomaly: false,
        ),
        whyPriorityReasons: [
          'High traffic density interchange',
          'Heavy vehicle corridor',
        ],
        coverage: 'Moderate',
        recommendation: 'Traffic patrol enforcement',
        incidentCount: 5,
        isAccidentCorridor: true,
        activeUnitsCount: 2,
      ),
      HexCell(
        id: 'hex_dadar',
        h3Index: '88618925effffff',
        name: 'Sector 2B - Dadar',
        shortCode: 'Sector 2B',
        center: const LatLng(19.0178, 72.8478),
        polygonPoints: HexCell.generateHexVertices(const LatLng(19.0178, 72.8478), 1250),
        riskScore: 52.0,
        zoneType: 'Railway Junction + Market',
        latDegStr: '19.0178° N',
        lngDegStr: '72.8478° E',
        neighborScores: {0: 48.0, 1: 44.0, 2: 32.0, 3: 36.0, 4: 45.0, 5: 50.0},
        riskFactors: const RiskFactors(
          theft: 0.60,
          assault: 0.32,
          vandalism: 0.28,
          trafficViolation: 0.65,
          drugActivity: 0.18,
          womenSafetyRisk: 0.50,
          crowdDensity: 0.95,
          poorLighting: 0.20,
          cctvAnomaly: false,
        ),
        whyPriorityReasons: [
          'Extreme peak hour crowd density',
          'Market corridor oversight',
        ],
        coverage: 'Adequate',
        recommendation: 'Foot patrol on station road',
        incidentCount: 4,
        activeUnitsCount: 3,
      ),
    ];

    _selectedHexCell = _hexCells.first;

    // 2. Initialize Assignments (Ranked exactly as Reference B Screen 2)
    _assignments = [
      const PatrolAssignment(
        rank: 1,
        sectorName: 'Andheri East',
        districtName: 'Andheri East, Mumbai',
        riskScore: 9.1,
        coverage: 'Low',
        recommendation: 'Increase patrol presence',
        whyReasons: [
          'High risk score (9.1)',
          "Women's safety activity",
          'CCTV anomaly',
        ],
        location: LatLng(19.1197, 72.8468),
        hexId: 'hex_andheri_east',
      ),
      const PatrolAssignment(
        rank: 2,
        sectorName: 'Kurla',
        districtName: 'Kurla, Mumbai',
        riskScore: 8.3,
        coverage: 'Moderate',
        recommendation: 'Maintain / increase presence',
        whyReasons: [
          'Increased incident activity',
          'High journey exposure',
          'Limited current coverage',
        ],
        location: LatLng(19.0728, 72.8794),
        hexId: 'hex_kurla',
      ),
      const PatrolAssignment(
        rank: 3,
        sectorName: 'Bandra West',
        districtName: 'Bandra West, Mumbai',
        riskScore: 6.7,
        coverage: 'Adequate',
        recommendation: 'Routine patrol',
        whyReasons: [
          'Accident-prone zone',
          'Elevated CCTV activity',
        ],
        location: LatLng(19.0596, 72.8368),
        hexId: 'hex_bandra_west',
      ),
      const PatrolAssignment(
        rank: 4,
        sectorName: 'Goregaon',
        districtName: 'Goregaon, Mumbai',
        riskScore: 4.2,
        coverage: 'Good',
        recommendation: 'No additional units required',
        whyReasons: [
          'Risk levels are within normal range',
        ],
        location: LatLng(19.1663, 72.8526),
        hexId: 'hex_goregaon',
      ),
      const PatrolAssignment(
        rank: 5,
        sectorName: 'Powai',
        districtName: 'Powai, Mumbai',
        riskScore: 7.1,
        coverage: 'Low',
        recommendation: 'Deploy evening unit',
        whyReasons: [
          'Evening commute congestion',
          'Isolated promenade stretches',
        ],
        location: LatLng(19.1176, 72.9060),
        hexId: 'hex_powai',
      ),
    ];

    // 3. Initialize Alerts (Matching Reference B Screen 3)
    _alerts = [
      const PatrolAlert(
        id: 'alert_1',
        severity: AlertSeverity.critical,
        iconCategory: AlertIconCategory.womenSafety,
        title: "Women's Safe Journey — Help Requested",
        locationName: 'Jogeshwari',
        timeAgo: '2 min ago',
        description: 'User has requested assistance.',
        status: 'Active',
        position: LatLng(19.1360, 72.8490),
        sectorId: 'hex_andheri_east',
      ),
      const PatrolAlert(
        id: 'alert_2',
        severity: AlertSeverity.high,
        iconCategory: AlertIconCategory.accident,
        title: 'Accident Reported',
        locationName: 'Western Express Highway',
        timeAgo: '8 min ago',
        description: 'Accident reported in high-risk zone.',
        status: 'Active',
        position: LatLng(19.0900, 72.8520),
        sectorId: 'hex_bandra_west',
      ),
      const PatrolAlert(
        id: 'alert_3',
        severity: AlertSeverity.high,
        iconCategory: AlertIconCategory.cctv,
        title: 'CCTV Activity Anomaly',
        locationName: 'Kurla',
        timeAgo: '12 min ago',
        description: 'Unusual crowd movement detected.',
        status: 'Active',
        position: LatLng(19.0728, 72.8794),
        sectorId: 'hex_kurla',
      ),
      const PatrolAlert(
        id: 'alert_4',
        severity: AlertSeverity.medium,
        iconCategory: AlertIconCategory.crowd,
        title: 'Crowd Increase Detected',
        locationName: 'Andheri East',
        timeAgo: '18 min ago',
        description: 'Sudden increase in crowd density.',
        status: 'Active',
        position: LatLng(19.1197, 72.8468),
        sectorId: 'hex_andheri_east',
      ),
      const PatrolAlert(
        id: 'alert_5',
        severity: AlertSeverity.medium,
        iconCategory: AlertIconCategory.routeDeviation,
        title: 'Journey Route Deviation',
        locationName: 'Bandra',
        timeAgo: '24 min ago',
        description: "User's route deviated from expected path.",
        status: 'Active',
        position: LatLng(19.0596, 72.8368),
        sectorId: 'hex_bandra_west',
      ),
      const PatrolAlert(
        id: 'alert_6',
        severity: AlertSeverity.resolved,
        iconCategory: AlertIconCategory.resolvedCheck,
        title: 'Safe Journey Alert',
        locationName: 'Goregaon',
        timeAgo: '18 min ago',
        description: 'User reached destination safely.',
        status: 'Resolved',
        position: LatLng(19.1663, 72.8526),
        sectorId: 'hex_goregaon',
      ),
    ];

    // 4. Initialize Safe Journeys (Matching Reference B Screen 4)
    _safeJourneys = [
      const SafeJourneyItem(
        id: 'Journey #2481',
        civilianName: 'Priya Mehta',
        startLocation: 'Andheri',
        destination: 'Goregaon',
        travelMode: 'Cab',
        eta: '11:42 PM',
        durationMinutes: 35,
        elapsedMinutes: 14,
        status: SafeJourneyStatus.normal,
        riskScore: 2.8,
        statusReason: 'On expected route with steady progress',
        currentPos: LatLng(19.1350, 72.8480),
        destPos: LatLng(19.1663, 72.8526),
        routePoints: [
          LatLng(19.1197, 72.8468),
          LatLng(19.1350, 72.8480),
          LatLng(19.1500, 72.8500),
          LatLng(19.1663, 72.8526),
        ],
      ),
      const SafeJourneyItem(
        id: 'Journey #2485',
        civilianName: 'Sneha Kulkarni',
        startLocation: 'Malad',
        destination: 'Kandivali',
        travelMode: 'Auto',
        eta: '11:18 PM',
        durationMinutes: 22,
        elapsedMinutes: 9,
        status: SafeJourneyStatus.attention,
        riskScore: 5.6,
        statusReason: 'Brief 4 min stop detected in low-light zone',
        currentPos: LatLng(19.1950, 72.8500),
        destPos: LatLng(19.2080, 72.8540),
        routePoints: [
          LatLng(19.1860, 72.8485),
          LatLng(19.1950, 72.8500),
          LatLng(19.2080, 72.8540),
        ],
      ),
      const SafeJourneyItem(
        id: 'Journey #2487',
        civilianName: 'Ritu Verma',
        startLocation: 'Jogeshwari',
        destination: 'Andheri',
        travelMode: 'Cab',
        eta: '11:07 PM',
        durationMinutes: 18,
        elapsedMinutes: 15,
        status: SafeJourneyStatus.highRisk,
        riskScore: 8.9,
        statusReason: 'SOS Assistance Requested by User',
        currentPos: LatLng(19.1360, 72.8490),
        destPos: LatLng(19.1197, 72.8468),
        routePoints: [
          LatLng(19.1450, 72.8510),
          LatLng(19.1360, 72.8490),
          LatLng(19.1280, 72.8480),
          LatLng(19.1197, 72.8468),
        ],
      ),
      const SafeJourneyItem(
        id: 'Journey #2490',
        civilianName: 'Aishwarya Deshmukh',
        startLocation: 'Bandra',
        destination: 'Worli',
        travelMode: 'Cab',
        eta: '10:45 PM',
        durationMinutes: 16,
        elapsedMinutes: 6,
        status: SafeJourneyStatus.normal,
        riskScore: 3.1,
        statusReason: 'Crossing Bandra-Worli Sea Link safely',
        currentPos: LatLng(19.0300, 72.8180),
        destPos: LatLng(19.0150, 72.8180),
        routePoints: [
          LatLng(19.0596, 72.8368),
          LatLng(19.0400, 72.8250),
          LatLng(19.0300, 72.8180),
          LatLng(19.0150, 72.8180),
        ],
      ),
      const SafeJourneyItem(
        id: 'Journey #2493',
        civilianName: 'Kavita Nair',
        startLocation: 'Chembur',
        destination: 'Ghatkopar',
        travelMode: 'Auto',
        eta: '10:32 PM',
        durationMinutes: 20,
        elapsedMinutes: 11,
        status: SafeJourneyStatus.attention,
        riskScore: 6.2,
        statusReason: 'Slow movement near unlit industrial stretch',
        currentPos: LatLng(19.0720, 72.9030),
        destPos: LatLng(19.0860, 72.9080),
        routePoints: [
          LatLng(19.0622, 72.8977),
          LatLng(19.0720, 72.9030),
          LatLng(19.0860, 72.9080),
        ],
      ),
    ];

    // 5. Initialize Patrol Units (Matching Reference A Screen 4)
    _patrolUnits = [
      const PatrolUnit(
        id: 'Unit P-12',
        officerName: 'Inspector R. Patil',
        sectorName: 'Sector 7A - Andheri',
        speedKmH: 32,
        state: PatrolUnitState.onRoute,
        position: LatLng(19.1150, 72.8440),
      ),
      const PatrolUnit(
        id: 'Unit P-08',
        officerName: 'Sub-Inspector S. Shinde',
        sectorName: 'Kurla West',
        speedKmH: 28,
        state: PatrolUnitState.onRoute,
        position: LatLng(19.0700, 72.8750),
      ),
      const PatrolUnit(
        id: 'Unit P-05',
        officerName: 'Constable V. More',
        sectorName: 'Dadar',
        speedKmH: 0,
        state: PatrolUnitState.atLocation,
        position: LatLng(19.0178, 72.8478),
      ),
    ];

    // 6. Initialize Route Planner (Matching Reference A Screen 3)
    _activeRoute = const PatrolRouteInfo(
      mode: 'safe',
      distanceKm: 6.8,
      estTimeMinutes: 16,
      startLocation: LatLng(19.0400, 72.8620), // Sion
      endLocation: LatLng(19.1197, 72.8468),   // Andheri East
      startName: 'Start (Sion)',
      endName: 'End (Andheri East)',
      highRiskAreas: 1,
      mediumRiskAreas: 1,
      lowRiskAreas: 1,
      stops: [
        PatrolStop(index: 1, name: 'Andheri East (High risk area)', riskTag: 'High', distanceKm: 4.2, position: LatLng(19.1197, 72.8468)),
        PatrolStop(index: 2, name: 'Sion (Medium risk area)', riskTag: 'Medium', distanceKm: 2.1, position: LatLng(19.0400, 72.8620)),
        PatrolStop(index: 3, name: 'Kurla (Low risk area)', riskTag: 'Low', distanceKm: 0.5, position: LatLng(19.0728, 72.8794)),
      ],
      polylinePoints: [
        LatLng(19.0400, 72.8620), // Sion
        LatLng(19.0550, 72.8590),
        LatLng(19.0728, 72.8794), // Kurla
        LatLng(19.0880, 72.8600),
        LatLng(19.1020, 72.8510),
        LatLng(19.1197, 72.8468), // Andheri East
      ],
      avoidHighRiskZones: true,
      preferMainRoads: true,
      includePoliceCheckpoints: false,
    );
  }

  // Route Planning Toggles
  void setRouteMode(String mode) {
    if (mode == 'quickest') {
      _activeRoute = _activeRoute.copyWith(
        mode: 'quickest',
        distanceKm: 5.4,
        estTimeMinutes: 12,
        highRiskAreas: 2,
        mediumRiskAreas: 0,
        lowRiskAreas: 1,
        polylinePoints: const [
          LatLng(19.0400, 72.8620),
          LatLng(19.0700, 72.8500),
          LatLng(19.0950, 72.8480),
          LatLng(19.1197, 72.8468),
        ],
      );
    } else {
      _activeRoute = _activeRoute.copyWith(
        mode: 'safe',
        distanceKm: 6.8,
        estTimeMinutes: 16,
        highRiskAreas: 1,
        mediumRiskAreas: 1,
        lowRiskAreas: 1,
        polylinePoints: const [
          LatLng(19.0400, 72.8620),
          LatLng(19.0550, 72.8590),
          LatLng(19.0728, 72.8794),
          LatLng(19.0880, 72.8600),
          LatLng(19.1020, 72.8510),
          LatLng(19.1197, 72.8468),
        ],
      );
    }
    notifyListeners();
  }

  void toggleRoutePreference({bool? avoidHighRisk, bool? preferMain, bool? includeCheckpoints}) {
    _activeRoute = _activeRoute.copyWith(
      avoidHighRiskZones: avoidHighRisk ?? _activeRoute.avoidHighRiskZones,
      preferMainRoads: preferMain ?? _activeRoute.preferMainRoads,
      includePoliceCheckpoints: includeCheckpoints ?? _activeRoute.includePoliceCheckpoints,
    );
    notifyListeners();
  }

  void generateNewRoute({required LatLng start, required LatLng destination, required String startName, required String destName}) {
    // Generate optimized patrol polyline
    final List<LatLng> generatedPoints = [
      start,
      LatLng((start.latitude + destination.latitude) / 2 + 0.008, (start.longitude + destination.longitude) / 2 - 0.005),
      LatLng((start.latitude + destination.latitude) / 2 - 0.003, (start.longitude + destination.longitude) / 2 + 0.006),
      destination,
    ];

    _activeRoute = _activeRoute.copyWith(
      startLocation: start,
      endLocation: destination,
      startName: startName,
      endName: destName,
      polylinePoints: generatedPoints,
      distanceKm: 7.2,
      estTimeMinutes: 18,
    );
    notifyListeners();
  }

  // Live Patrol Actions
  void startLivePatrol() {
    _isLivePatrolActive = true;
    _currentPatrolStep = 0;
    _hasPendingReroute = false;
    notifyListeners();

    _patrolSimulationTimer?.cancel();
    _patrolSimulationTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_isLivePatrolActive) {
        timer.cancel();
        return;
      }

      if (_activeRoute.polylinePoints.isEmpty) return;
      _currentPatrolStep = (_currentPatrolStep + 1) % _activeRoute.polylinePoints.length;
      final newPos = _activeRoute.polylinePoints[_currentPatrolStep];

      // Update Unit P-12 position
      _patrolUnits[0] = _patrolUnits[0].copyWith(
        position: newPos,
        speedKmH: 26 + (_currentPatrolStep % 4) * 3,
      );
      notifyListeners();
    });
  }

  void endLivePatrol() {
    _isLivePatrolActive = false;
    _patrolSimulationTimer?.cancel();
    _hasPendingReroute = false;
    notifyListeners();
  }

  void applyReroute() {
    _hasPendingReroute = false;
    _rerouteReason = '';
    // Recalculate patrol route through safer bypass avoiding incident cell
    _activeRoute = _activeRoute.copyWith(
      distanceKm: 7.4,
      estTimeMinutes: 19,
      polylinePoints: const [
        LatLng(19.0400, 72.8620),
        LatLng(19.0550, 72.8450), // Western bypass
        LatLng(19.0800, 72.8390), // Via Khar/Santacruz
        LatLng(19.1050, 72.8420),
        LatLng(19.1197, 72.8468),
      ],
    );
    notifyListeners();
  }

  // Alert Actions
  void acknowledgeAlert(String alertId) {
    final idx = _alerts.indexWhere((a) => a.id == alertId);
    if (idx != -1) {
      _alerts[idx] = _alerts[idx].copyWith(status: 'Acknowledged');
      notifyListeners();
    }
  }

  void resolveAlert(String alertId) {
    final idx = _alerts.indexWhere((a) => a.id == alertId);
    if (idx != -1) {
      _alerts[idx] = _alerts[idx].copyWith(
        status: 'Resolved',
        severity: AlertSeverity.resolved,
      );
      notifyListeners();
    }
  }

  void dispatchBackup(String alertId, String unitId) {
    acknowledgeAlert(alertId);
    final unitIdx = _patrolUnits.indexWhere((u) => u.id == unitId);
    if (unitIdx != -1) {
      _patrolUnits[unitIdx] = _patrolUnits[unitIdx].copyWith(state: PatrolUnitState.onRoute);
    }
    notifyListeners();
  }

  // Safe Journey Actions
  void escalateSafeJourney(String journeyId) {
    final idx = _safeJourneys.indexWhere((j) => j.id == journeyId);
    if (idx != -1) {
      _safeJourneys[idx] = _safeJourneys[idx].copyWith(
        status: SafeJourneyStatus.highRisk,
        statusReason: 'SOS Escalated • Patrol Unit Dispatched',
        riskScore: 9.4,
      );

      // Also create Critical Alert
      final newAlert = PatrolAlert(
        id: 'alert_escalated_${DateTime.now().millisecondsSinceEpoch}',
        severity: AlertSeverity.critical,
        iconCategory: AlertIconCategory.womenSafety,
        title: "SOS Escalated — ${_safeJourneys[idx].civilianName}",
        locationName: _safeJourneys[idx].startLocation,
        timeAgo: 'Just now',
        description: 'Unit dispatched to intercept monitored journey.',
        status: 'Active',
        position: _safeJourneys[idx].currentPos,
        sectorId: 'hex_andheri_east',
      );
      _alerts.insert(0, newAlert);
      notifyListeners();
    }
  }

  void resolveSafeJourney(String journeyId) {
    final idx = _safeJourneys.indexWhere((j) => j.id == journeyId);
    if (idx != -1) {
      _safeJourneys[idx] = _safeJourneys[idx].copyWith(
        status: SafeJourneyStatus.normal,
        statusReason: 'Verified Safe • Journey Completed',
        riskScore: 2.1,
      );
      notifyListeners();
    }
  }

  // Incident Reporting Flow (End-to-End)
  void reportIncident({
    required String category,
    required String locationName,
    required String severity,
    required String description,
    required LatLng position,
    String? sectorId,
  }) {
    AlertSeverity alertSeverity;
    AlertIconCategory iconCat;

    switch (severity.toLowerCase()) {
      case 'critical':
        alertSeverity = AlertSeverity.critical;
        break;
      case 'high':
        alertSeverity = AlertSeverity.high;
        break;
      case 'low':
        alertSeverity = AlertSeverity.resolved;
        break;
      default:
        alertSeverity = AlertSeverity.medium;
    }

    switch (category.toLowerCase()) {
      case 'theft':
        iconCat = AlertIconCategory.theft;
        break;
      case 'harassment':
      case 'women safety':
        iconCat = AlertIconCategory.womenSafety;
        break;
      case 'road accident':
      case 'accident':
        iconCat = AlertIconCategory.accident;
        break;
      case 'cctv anomaly':
        iconCat = AlertIconCategory.cctv;
        break;
      case 'crowd anomaly':
        iconCat = AlertIconCategory.crowd;
        break;
      default:
        iconCat = AlertIconCategory.vandalism;
    }

    final newAlert = PatrolAlert(
      id: 'new_incident_${DateTime.now().millisecondsSinceEpoch}',
      severity: alertSeverity,
      iconCategory: iconCat,
      title: '$category Reported',
      locationName: locationName,
      timeAgo: 'Just now',
      description: description,
      status: 'Active',
      position: position,
      sectorId: sectorId ?? 'hex_andheri_east',
    );

    _alerts.insert(0, newAlert);

    // Increase risk score of the affected sector
    final targetSectorId = sectorId ?? 'hex_andheri_east';
    final hexIdx = _hexCells.indexWhere((h) => h.id == targetSectorId);
    if (hexIdx != -1) {
      final oldCell = _hexCells[hexIdx];
      final newScore = (oldCell.riskScore + 12.0).clamp(1.0, 99.0);
      _hexCells[hexIdx] = oldCell.copyWith(
        riskScore: newScore,
        incidentCount: oldCell.incidentCount + 1,
      );
    }

    // Update assignment ranking
    _recalculateAssignments();

    // Trigger reroute if live patrol is active
    if (_isLivePatrolActive) {
      _hasPendingReroute = true;
      _rerouteReason = 'New incident reported near $locationName ($category)';
    }

    notifyListeners();
  }

  void _recalculateAssignments() {
    // Sort assignments by sector risk scores
    for (int i = 0; i < _assignments.length; i++) {
      final assign = _assignments[i];
      final hex = _hexCells.firstWhere((h) => h.id == assign.hexId, orElse: () => _hexCells.first);
      _assignments[i] = PatrolAssignment(
        rank: i + 1,
        sectorName: assign.sectorName,
        districtName: assign.districtName,
        riskScore: hex.displayScore10,
        coverage: hex.coverage,
        recommendation: hex.recommendation,
        whyReasons: hex.whyPriorityReasons,
        location: assign.location,
        hexId: assign.hexId,
      );
    }
  }

  // Demo Simulation Scenarios
  void triggerDemoScenario(String scenarioName) {
    if (scenarioName == 'cctv_andheri') {
      // Scenario A: CCTV anomaly in Andheri East
      final andheriIdx = _hexCells.indexWhere((h) => h.id == 'hex_andheri_east');
      if (andheriIdx != -1) {
        _hexCells[andheriIdx] = _hexCells[andheriIdx].copyWith(
          riskScore: 96.0,
          riskFactors: _hexCells[andheriIdx].riskFactors.copyWith(
            crowdDensity: 0.94,
            cctvAnomaly: true,
          ),
          incidentCount: _hexCells[andheriIdx].incidentCount + 2,
        );
      }

      _alerts.insert(
        0,
        const PatrolAlert(
          id: 'demo_cctv_andheri',
          severity: AlertSeverity.high,
          iconCategory: AlertIconCategory.cctv,
          title: 'CCTV Anomaly & Crowd Surge',
          locationName: 'Sector 7A - Andheri East',
          timeAgo: 'Just now',
          description: 'Unusual gathering of 350+ persons detected near Station Metro exit.',
          status: 'Active',
          position: LatLng(19.1197, 72.8468),
          sectorId: 'hex_andheri_east',
        ),
      );

      _recalculateAssignments();

      if (_isLivePatrolActive) {
        _hasPendingReroute = true;
        _rerouteReason = 'CCTV Anomaly in Sector 7A — Crowd surge detected';
      }
      notifyListeners();
    } else if (scenarioName == 'sos_jogeshwari') {
      // Scenario B: SOS Alert in Jogeshwari
      escalateSafeJourney('Journey #2487');
    } else if (scenarioName == 'accident_weh') {
      // Scenario C: Western Express Highway Accident
      reportIncident(
        category: 'Road Accident',
        locationName: 'Western Express Highway (Kalanagar)',
        severity: 'High',
        description: 'Multi-vehicle collision on north-bound flyover. Traffic stalled.',
        position: const LatLng(19.0596, 72.8368),
        sectorId: 'hex_bandra_west',
      );
    } else if (scenarioName == 'reset') {
      // Reset to baseline clean state
      _initializeBaselineData();
      _isLivePatrolActive = false;
      _hasPendingReroute = false;
      notifyListeners();
    }
  }
}
