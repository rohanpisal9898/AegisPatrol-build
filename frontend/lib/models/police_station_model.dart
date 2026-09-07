import 'package:latlong2/latlong.dart';

class PoliceStationModel {
  final String id;
  final String name;
  final String district;
  final double lat;
  final double lon;
  final String? phone;
  final String? address;
  final double? distanceKm;

  const PoliceStationModel({
    required this.id,
    required this.name,
    required this.district,
    required this.lat,
    required this.lon,
    this.phone,
    this.address,
    this.distanceKm,
  });

  LatLng get coordinates => LatLng(lat, lon);

  factory PoliceStationModel.fromJson(Map<String, dynamic> json) {
    return PoliceStationModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Police Station',
      district: json['district'] ?? 'Mumbai Suburban',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
      phone: json['phone'],
      address: json['address'],
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }
}
