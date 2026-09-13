import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'alert_service.dart';
import 'location_service.dart';

/// Singleton manager that handles real-time continuous GPS streaming
/// to police dispatch when a civilian triggers an SOS alert, and automatically
/// turns off tracking when the alert is marked resolved.
class SosTrackingManager extends ChangeNotifier {
  static final SosTrackingManager _instance = SosTrackingManager._internal();
  factory SosTrackingManager() => _instance;
  SosTrackingManager._internal();

  final AlertService _alertService = AlertService();
  Timer? _trackingTimer;

  bool _isSosActive = false;
  String? _activeAlertId;
  String? _activeMessage;
  LatLng? _currentPosition;
  String? _activeToken;
  DateTime? _startedAt;

  bool get isSosActive => _isSosActive;
  String? get activeAlertId => _activeAlertId;
  String? get activeMessage => _activeMessage;
  LatLng? get currentPosition => _currentPosition;
  DateTime? get startedAt => _startedAt;

  /// Start broadcasting live continuous GPS location
  void startTracking({
    required String token,
    required String alertId,
    String? message,
    LatLng? initialPos,
    VoidCallback? onResolvedByPolice,
  }) {
    stopTracking(); // Clear any previous timer

    _isSosActive = true;
    _activeAlertId = alertId;
    _activeMessage = message ?? 'Instant SOS Alert';
    _currentPosition = initialPos;
    _activeToken = token;
    _startedAt = DateTime.now();
    notifyListeners();

    // Broadcast GPS location periodically every 3 seconds
    _trackingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!_isSosActive || _activeAlertId == null) {
        timer.cancel();
        return;
      }

      try {
        final locRes = await LocationService.getCurrentLocation();
        if (locRes.position != null) {
          _currentPosition = locRes.position;
          notifyListeners();

          final res = await _alertService.updateAlertLocation(
            token: token,
            alertId: _activeAlertId!,
            lat: locRes.position!.latitude,
            lon: locRes.position!.longitude,
          );

          // If alert was resolved (by police officer or server), stop tracking immediately
          if (res.success && res.data != null) {
            final isTrackingActive = res.data!['is_tracking_active'] as bool? ?? true;
            final status = res.data!['status'] as String? ?? 'active';
            if (!isTrackingActive || status == 'resolved') {
              timer.cancel();
              _isSosActive = false;
              _activeAlertId = null;
              notifyListeners();
              onResolvedByPolice?.call();
            }
          }
        }
      } catch (e) {
        debugPrint('[SosTrackingManager] Error during GPS broadcast: $e');
      }
    });
  }

  /// Stop tracking and optionally resolve on the backend
  Future<void> stopTracking({bool callBackendResolve = false, String? note}) async {
    _trackingTimer?.cancel();
    _trackingTimer = null;

    final alertId = _activeAlertId;
    final token = _activeToken;

    _isSosActive = false;
    _activeAlertId = null;
    _activeMessage = null;
    _startedAt = null;
    notifyListeners();

    if (callBackendResolve && alertId != null && token != null) {
      try {
        await _alertService.resolveAlert(
          token: token,
          alertId: alertId,
          note: note ?? 'Civilian marked safe and turned off tracking',
        );
      } catch (e) {
        debugPrint('[SosTrackingManager] Error resolving alert on backend: $e');
      }
    }
  }
}
