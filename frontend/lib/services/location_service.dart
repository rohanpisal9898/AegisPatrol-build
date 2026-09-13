import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum LocationPermissionState {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
  error
}

class LocationResult {
  final LatLng? position;
  final LocationPermissionState status;
  final String? errorMessage;
  final bool isRealGps;
  final double? accuracy;

  const LocationResult({
    this.position,
    required this.status,
    this.errorMessage,
    this.isRealGps = false,
    this.accuracy,
  });

  bool get isSuccess => position != null && isRealGps;
}

class LocationService {
  /// Operational fallback coordinates (Mumbai Central centroid)
  static const LatLng defaultLocation = LatLng(19.0760, 72.8777);

  /// Checks whether device location service is enabled.
  static Future<bool> isLocationServiceEnabled() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('[GPS-Diagnostic] 1. isLocationServiceEnabled = $enabled');
      return enabled;
    } catch (e) {
      debugPrint('[GPS-Diagnostic] 1. isLocationServiceEnabled Error: $e');
      return false;
    }
  }

  /// Explicitly requests location permission from the OS.
  static Future<LocationPermission> requestPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('[GPS-Diagnostic] 2. checkPermission = $permission');
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('[GPS-Diagnostic] 3. requestPermission result = $permission');
      }
      return permission;
    } catch (e) {
      debugPrint('[GPS-Diagnostic] 2/3. Permission request exception: $e');
      return LocationPermission.denied;
    }
  }

  /// Obtains current GPS location with multi-strategy provider targeting.
  static Future<LocationResult> getCurrentLocation() async {
    debugPrint('[GPS-Diagnostic] === INITIATING GPS RESOLUTION ===');
    try {
      // Step 1: Check hardware service switch
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[GPS-Diagnostic] ❌ Device Location Services are turned OFF in quick settings');
        return const LocationResult(
          position: defaultLocation,
          status: LocationPermissionState.serviceDisabled,
          errorMessage: 'Location service (GPS) is turned OFF on this device. Please turn ON GPS.',
          isRealGps: false,
        );
      }

      // Step 2: Check & request runtime permissions
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('[GPS-Diagnostic] Permission status: $permission');
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('[GPS-Diagnostic] Permission requested: $permission');
      }

      if (permission == LocationPermission.denied) {
        debugPrint('[GPS-Diagnostic] ❌ Location permission denied by user');
        return const LocationResult(
          position: defaultLocation,
          status: LocationPermissionState.denied,
          errorMessage: 'Location permission denied by user.',
          isRealGps: false,
        );
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[GPS-Diagnostic] ❌ Location permission permanently denied');
        return const LocationResult(
          position: defaultLocation,
          status: LocationPermissionState.deniedForever,
          errorMessage: 'Location permission is permanently denied. Please allow in App Settings.',
          isRealGps: false,
        );
      }

      // Step 3: Check Last Known Position for immediate fix
      Position? lastKnownPos;
      try {
        lastKnownPos = await Geolocator.getLastKnownPosition();
        if (lastKnownPos != null) {
          debugPrint('[GPS-Diagnostic] ✅ Last Known GPS Found: (${lastKnownPos.latitude}, ${lastKnownPos.longitude}) ±${lastKnownPos.accuracy}m');
        }
      } catch (e) {
        debugPrint('[GPS-Diagnostic] Note: getLastKnownPosition error: $e');
      }

      // Step 4: Primary GPS Fix (Fused Provider / High Accuracy)
      try {
        debugPrint('[GPS-Diagnostic] Requesting fresh GPS position with high accuracy...');
        final freshPos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 12),
          ),
        );

        debugPrint('[GPS-Diagnostic] 🎉 Fresh GPS Position Locked: (${freshPos.latitude}, ${freshPos.longitude}) ±${freshPos.accuracy}m @ ${freshPos.timestamp}');
        return LocationResult(
          position: LatLng(freshPos.latitude, freshPos.longitude),
          status: LocationPermissionState.granted,
          isRealGps: true,
          accuracy: freshPos.accuracy,
        );
      } on TimeoutException catch (te) {
        debugPrint('[GPS-Diagnostic] ⚠️ High-accuracy GPS timed out: $te. Trying AndroidLocationManager fallback...');
      } on LocationServiceDisabledException catch (lsde) {
        debugPrint('[GPS-Diagnostic] ⚠️ LocationServiceDisabledException: $lsde');
      } catch (e) {
        debugPrint('[GPS-Diagnostic] ⚠️ Primary GPS attempt error: $e');
      }

      // Step 5: Fallback GPS Fix using Android Native Location Manager directly
      try {
        debugPrint('[GPS-Diagnostic] Attempting fallback with forceAndroidLocationManager = true...');
        final androidSettings = AndroidSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
          forceLocationManager: true,
        );

        final fallbackPos = await Geolocator.getCurrentPosition(locationSettings: androidSettings);
        debugPrint('[GPS-Diagnostic] 🎉 Fallback Android Location Locked: (${fallbackPos.latitude}, ${fallbackPos.longitude}) ±${fallbackPos.accuracy}m');
        return LocationResult(
          position: LatLng(fallbackPos.latitude, fallbackPos.longitude),
          status: LocationPermissionState.granted,
          isRealGps: true,
          accuracy: fallbackPos.accuracy,
        );
      } catch (e2) {
        debugPrint('[GPS-Diagnostic] ⚠️ Fallback Android Location attempt error: $e2');
      }

      // Step 6: If fresh attempts timed out indoors, use Last Known Position if available
      if (lastKnownPos != null) {
        debugPrint('[GPS-Diagnostic] ℹ️ Returning Last Known GPS coordinates');
        return LocationResult(
          position: LatLng(lastKnownPos.latitude, lastKnownPos.longitude),
          status: LocationPermissionState.granted,
          isRealGps: true,
          accuracy: lastKnownPos.accuracy,
        );
      }

      // Step 7: Fallback to centroid if GPS has no signal indoors
      debugPrint('[GPS-Diagnostic] ⚠️ No satellite/network fix acquired within timeout. Returning fallback centroid.');
      return const LocationResult(
        position: defaultLocation,
        status: LocationPermissionState.error,
        errorMessage: 'GPS timeout: No satellite or network location fix available indoors.',
        isRealGps: false,
      );
    } catch (criticalErr) {
      debugPrint('[GPS-Diagnostic] ❌ Critical Location Pipeline Exception: $criticalErr');
      return LocationResult(
        position: defaultLocation,
        status: LocationPermissionState.error,
        errorMessage: 'GPS Error: $criticalErr',
        isRealGps: false,
      );
    }
  }

  /// Open device app settings if permission is permanently denied.
  static Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Open location settings if location service is disabled.
  static Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
}
