import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/journey_model.dart';
import '../../../services/location_service.dart';
import '../../../services/journey_service.dart';
import '../../../services/alert_service.dart';
import '../../../services/geocoding_service.dart';
import '../../../services/demo_simulation_service.dart';
import '../journeys/civilian_journeys_screen.dart';

class CivilianHomeController extends ChangeNotifier {
  final JourneyService _journeyService = JourneyService();
  final AlertService _alertService = AlertService();

  // Current State
  JourneyStatus _journeyState = JourneyStatus.notStarted;
  JourneyStatus get journeyState => _journeyState;

  // Loading & Error States
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Location State (defaults to Mumbai central base)
  LatLng? _currentPosition = const LatLng(19.0760, 72.8777);
  LatLng? get currentPosition => _currentPosition;
  String? _locationDiagnostic;
  String? get locationDiagnostic => _locationDiagnostic;
  bool _isRealGpsLocked = false;
  bool get isRealGpsLocked => _isRealGpsLocked;


  LocationPermissionState _locationPermissionState = LocationPermissionState.granted;
  LocationPermissionState get locationPermissionState => _locationPermissionState;

  // Planning Form State
  TravelMode _selectedTravelMode = TravelMode.walk;
  TravelMode get selectedTravelMode => _selectedTravelMode;

  int _selectedDurationMinutes = 60;
  int get selectedDurationMinutes => _selectedDurationMinutes;

  String _destinationText = '';
  String get destinationText => _destinationText;

  LatLng? _destinationPosition;
  LatLng? get destinationPosition => _destinationPosition;

  // Active Journey Data
  JourneyModel? _activeJourney;
  JourneyModel? get activeJourney => _activeJourney;

  List<LatLng> _routePoints = [];
  List<LatLng> get routePoints => _routePoints;

  double _currentRiskScore = 3.2;
  double get currentRiskScore => _currentRiskScore;

  RiskLevel _currentRiskLevel = RiskLevel.normal;
  RiskLevel get currentRiskLevel => _currentRiskLevel;

  String _statusMessage = 'You’re on a safe route. We’ll alert you if anything unusual is detected.';
  String get statusMessage => _statusMessage;

  String _eta = '10:59 PM';
  String get eta => _eta;

  double _distanceKm = 6.8;
  double get distanceKm => _distanceKm;

  int _timeRemainingMinutes = 28;
  int get timeRemainingMinutes => _timeRemainingMinutes;

  double _completedDurationMinutes = 35.0;
  double get completedDurationMinutes => _completedDurationMinutes;

  double _completedDistanceKm = 8.7;
  double get completedDistanceKm => _completedDistanceKm;

  bool _safeRoute = true;
  bool get safeRoute => _safeRoute;

  // Demo Simulation State
  bool _isDemoMode = false;
  bool get isDemoMode => _isDemoMode;

  int _demoStepIndex = 0;
  int get demoStepIndex => _demoStepIndex;

  // --- ACTIONS ---

  void openPlanning() {
    _journeyState = JourneyStatus.planning;
    _errorMessage = null;
    notifyListeners();
    fetchCurrentLocation();
  }

  /// Check backend for existing active journey and restore state after login/refresh
  Future<void> checkAndRestoreActiveJourney({required String token}) async {
    if (token.isEmpty || _isDemoMode) return;
    _isLoading = true;
    notifyListeners();

    final response = await _journeyService.getActiveJourney(token: token);
    _isLoading = false;

    if (response.success && response.data != null) {
      final journey = response.data!;
      _activeJourney = journey;
      _journeyState = journey.status;
      _selectedTravelMode = journey.travelMode;
      _selectedDurationMinutes = journey.expectedDurationMinutes;
      _currentRiskScore = journey.riskScore;
      _currentRiskLevel = journey.riskLevel;
      _statusMessage = journey.message ?? 'Monitoring your journey in real-time.';
      _distanceKm = journey.distanceKm > 0 ? journey.distanceKm : 1.5;

      final now = DateTime.now();
      final startedAt = journey.startedAt ?? now;
      final elapsedMins = now.difference(startedAt).inMinutes;
      final remainingMins = (journey.expectedDurationMinutes - elapsedMins).clamp(0, journey.expectedDurationMinutes);
      _timeRemainingMinutes = remainingMins;

      final arrivalTime = startedAt.add(Duration(minutes: journey.expectedDurationMinutes));
      _eta = DateFormat('h:mm a').format(arrivalTime);

      if (journey.route != null && journey.route!.points.isNotEmpty) {
        _routePoints = journey.route!.points;
      } else if (journey.startLocation != null && journey.destination != null) {
        _routePoints = [journey.startLocation!.toLatLng(), journey.destination!.toLatLng()];
      } else if (journey.currentLocation != null) {
        _routePoints = [journey.currentLocation!.toLatLng()];
      }
      if (journey.currentLocation != null) {
        _currentPosition = journey.currentLocation!.toLatLng();
      }
    } else {
      if (_journeyState != JourneyStatus.planning) {
        _journeyState = JourneyStatus.notStarted;
        _activeJourney = null;
      }
    }
    notifyListeners();
  }

  void cancelPlanning() {
    _journeyState = JourneyStatus.notStarted;
    _errorMessage = null;
    notifyListeners();
  }

  final GeocodingService _geocodingService = GeocodingService();

  // Place Suggestions Autocomplete State
  List<PlaceSuggestion> _placeSuggestions = [];
  List<PlaceSuggestion> get placeSuggestions => _placeSuggestions;

  bool _isSearchingPlaces = false;
  bool get isSearchingPlaces => _isSearchingPlaces;

  void setTravelMode(TravelMode mode) {
    _selectedTravelMode = mode;
    notifyListeners();
  }

  void setExpectedDuration(int minutes) {
    _selectedDurationMinutes = minutes.clamp(1, 720);
    notifyListeners();
  }

  void setDestination(String text, LatLng? coords) {
    _destinationText = text;
    _destinationPosition = coords;
    notifyListeners();
  }

  Future<void> searchDestinationPlaces(String query) async {
    _destinationText = query;
    _destinationPosition = null; // reset specific coords until resolved or selected

    if (query.trim().length < 2) {
      _placeSuggestions = [];
      _isSearchingPlaces = false;
      notifyListeners();
      return;
    }

    _isSearchingPlaces = true;
    notifyListeners();

    final results = await _geocodingService.searchPlaces(query, near: _currentPosition);
    _placeSuggestions = results;
    _isSearchingPlaces = false;
    notifyListeners();
  }

  void selectPlaceSuggestion(PlaceSuggestion suggestion) {
    _destinationText = suggestion.displayName.isNotEmpty ? suggestion.displayName : suggestion.shortName;
    _destinationPosition = suggestion.coordinates;
    _placeSuggestions = [];
    notifyListeners();
  }

  Future<void> fetchCurrentLocation() async {
    _isLoading = true;
    notifyListeners();

    final result = await LocationService.getCurrentLocation();
    _isLoading = false;
    _locationPermissionState = result.status;
    _isRealGpsLocked = result.isRealGps;

    if (result.position != null) {
      _currentPosition = result.position;
      if (result.isRealGps) {
        final acc = result.accuracy != null ? '±${result.accuracy!.toStringAsFixed(1)}m' : '';
        _locationDiagnostic = 'Live GPS: (${result.position!.latitude.toStringAsFixed(4)}, ${result.position!.longitude.toStringAsFixed(4)}) $acc';
        _errorMessage = null;
      } else {
        _locationDiagnostic = 'Default Centroid (${result.position!.latitude.toStringAsFixed(4)}, ${result.position!.longitude.toStringAsFixed(4)})';
        _errorMessage = result.errorMessage;
      }
    } else {
      _errorMessage = result.errorMessage ?? 'Location unavailable';
      _locationDiagnostic = 'GPS Unavailable: $_errorMessage';
    }
    notifyListeners();
  }

  /// Start a genuine safe journey via backend API
  Future<bool> startJourney({required String token, String? startDistrict}) async {
    _isLoading = true;
    _errorMessage = null;
    _placeSuggestions = [];
    notifyListeners();

    // If destination position is not yet resolved but user typed something, resolve it now
    if (_destinationPosition == null && _destinationText.trim().isNotEmpty) {
      final resolved = await _geocodingService.resolveDestination(_destinationText, near: _currentPosition);
      if (resolved != null) {
        _destinationPosition = resolved.coordinates;
        _destinationText = resolved.shortName;
      }
    }

    final startPos = _currentPosition;
    final destPos = _destinationPosition;

    final response = await _journeyService.startJourney(
      token: token,
      travelMode: _selectedTravelMode,
      startLocation: startPos,
      startLocationName: startDistrict ?? 'Current Location',
      destination: destPos,
      destinationName: _destinationText.isNotEmpty ? _destinationText : null,
      expectedDurationMinutes: _selectedDurationMinutes,
    );

    _isLoading = false;

    if (response.success && response.data != null) {
      _activeJourney = response.data;
      _journeyState = JourneyStatus.active;
      _currentRiskScore = response.data!.riskScore;
      _currentRiskLevel = response.data!.riskLevel;
      _statusMessage = response.data!.message ?? 'You’re on a safe route.';
      _distanceKm = response.data!.distanceKm > 0 ? response.data!.distanceKm : 1.5;
      final int durationMins = _selectedDurationMinutes;
      _timeRemainingMinutes = durationMins;
      final arrivalTime = DateTime.now().add(Duration(minutes: durationMins));
      _eta = DateFormat('h:mm a').format(arrivalTime);

      if (response.data!.route != null && response.data!.route!.points.isNotEmpty) {
        _routePoints = response.data!.route!.points;
      } else if (startPos != null && destPos != null) {
        _routePoints = [startPos, destPos];
      } else if (startPos != null) {
        _routePoints = [startPos];
      }

      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message ?? 'Failed to start journey';
      notifyListeners();
      return false;
    }
  }

  /// Update location during active journey
  Future<void> updateLocation({
    required String token,
    required double lat,
    required double lon,
    int? stepIndex,
  }) async {
    _currentPosition = LatLng(lat, lon);
    if (_activeJourney == null) return;

    final response = await _journeyService.updateLocation(
      token: token,
      journeyId: _activeJourney!.id,
      lat: lat,
      lon: lon,
      stepIndex: stepIndex,
    );

    if (response.success && response.data != null) {
      final data = response.data!;
      _currentRiskScore = data.riskScore;
      _currentRiskLevel = data.riskLevel;
      _journeyState = data.status;
      _statusMessage = data.message;
      notifyListeners();
    }
  }

  /// User taps "I'm Safe" on Safety Alert
  Future<void> markUserSafe({required String token}) async {
    _isLoading = true;
    notifyListeners();

    if (_activeJourney != null) {
      await _alertService.markJourneySafe(
        token: token,
        journeyId: _activeJourney!.id,
      );
    }

    _currentRiskScore = 3.2;
    _currentRiskLevel = RiskLevel.normal;
    _journeyState = JourneyStatus.active;
    _statusMessage = 'You’re on a safe route. We’ll alert you if anything unusual is detected.';
    _isLoading = false;
    notifyListeners();
  }

  /// User taps "I Need Help" on Safety Alert (Dispatches notification to police in destination district)
  Future<void> requestEmergencyHelp({required String token}) async {
    _isLoading = true;
    notifyListeners();

    final pos = _currentPosition ?? DemoSimulationService.startLocation;
    final targetDistrict = _activeJourney?.destinationName ?? _destinationText;

    await _alertService.createAlert(
      token: token,
      journeyId: _activeJourney?.id,
      district: targetDistrict.isNotEmpty ? targetDistrict : null,
      lat: pos.latitude,
      lon: pos.longitude,
      alertType: 'need_help',
      message: 'Civilian requested emergency assistance. Destination: ${targetDistrict.isNotEmpty ? targetDistrict : 'En route'}',
      riskScore: _currentRiskScore,
    );

    _statusMessage = 'Emergency assistance alert dispatched to police in destination district.';
    _isLoading = false;
    notifyListeners();
  }

  /// End Journey
  Future<bool> endJourney({required String token}) async {
    _isLoading = true;
    notifyListeners();

    if (_activeJourney != null) {
      final response = await _journeyService.endJourney(
        token: token,
        journeyId: _activeJourney!.id,
      );

      _isLoading = false;
      if (response.success && response.data != null) {
        _completedDurationMinutes = (response.data!['duration_minutes'] as num?)?.toDouble() ?? 35.0;
        _completedDistanceKm = (response.data!['distance_km'] as num?)?.toDouble() ?? _distanceKm;
        _safeRoute = response.data!['safe_route'] ?? true;
      }
    } else {
      _isLoading = false;
    }

    _journeyState = JourneyStatus.completed;
    civilianJourneysKey.currentState?.loadJourneys();
    notifyListeners();
    return true;
  }

  /// Reset to Home Not Started
  void resetToHome() {
    _journeyState = JourneyStatus.notStarted;
    _activeJourney = null;
    _isDemoMode = false;
    _demoStepIndex = 0;
    _errorMessage = null;
    notifyListeners();
  }

  // --- DEMO SIMULATION (6-Step Walkthrough) ---

  void startDemoSimulation({required String token}) {
    _isDemoMode = true;
    _demoStepIndex = 0;
    _applyDemoStep(0);
  }

  void nextDemoStep({required String token}) {
    if (_demoStepIndex < DemoSimulationService.demoSteps.length - 1) {
      _demoStepIndex++;
      _applyDemoStep(_demoStepIndex);
    }
  }

  void prevDemoStep({required String token}) {
    if (_demoStepIndex > 0) {
      _demoStepIndex--;
      _applyDemoStep(_demoStepIndex);
    }
  }

  void _applyDemoStep(int index) {
    final step = DemoSimulationService.demoSteps[index];
    _currentPosition = step.position;
    _destinationPosition = DemoSimulationService.destinationLocation;
    _routePoints = DemoSimulationService.demoRoutePolyline;
    _currentRiskScore = step.riskScore;
    _currentRiskLevel = step.riskLevel;
    _journeyState = step.status;
    _statusMessage = step.message;
    _distanceKm = step.distanceKm;

    final totalDuration = _selectedDurationMinutes;
    final totalSteps = DemoSimulationService.demoSteps.length - 1;
    final remainingFraction = totalSteps > 0 ? (totalSteps - index) / totalSteps : 0.0;
    final dynamicRemainingMins = (totalDuration * remainingFraction).round();
    _timeRemainingMinutes = dynamicRemainingMins;
    final arrivalTime = DateTime.now().add(Duration(minutes: dynamicRemainingMins));
    _eta = DateFormat('h:mm a').format(arrivalTime);

    if (step.status == JourneyStatus.completed) {
      _completedDurationMinutes = _selectedDurationMinutes.toDouble();
      _completedDistanceKm = 8.7;
      _safeRoute = true;
    }

    notifyListeners();
  }
}
