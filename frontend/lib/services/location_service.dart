import 'dart:async';
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

  const LocationResult({
    this.position,
    required this.status,
    this.errorMessage,
  });

  bool get isSuccess => position != null && status == LocationPermissionState.granted;
}

class LocationService {
  /// Checks whether device location service is enabled.
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Obtains the current genuine device GPS location.
  /// Does NOT substitute fake coordinates on failure.
  static Future<LocationResult> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(
          status: LocationPermissionState.serviceDisabled,
          errorMessage: 'Location services are disabled on your device.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LocationResult(
            status: LocationPermissionState.denied,
            errorMessage: 'Location permission was denied.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
          status: LocationPermissionState.deniedForever,
          errorMessage: 'Location permissions are permanently denied. Please enable in settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return LocationResult(
        position: LatLng(position.latitude, position.longitude),
        status: LocationPermissionState.granted,
      );
    } catch (e) {
      return LocationResult(
        status: LocationPermissionState.error,
        errorMessage: 'Unable to retrieve GPS coordinates: $e',
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
