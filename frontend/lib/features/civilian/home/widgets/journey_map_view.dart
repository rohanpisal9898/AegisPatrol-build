import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/journey_model.dart';

class JourneyMapView extends StatefulWidget {
  final LatLng currentPosition;
  final LatLng? destinationPosition;
  final List<LatLng> routePoints;
  final JourneyStatus journeyStatus;
  final RiskLevel riskLevel;
  final double height;

  const JourneyMapView({
    super.key,
    required this.currentPosition,
    this.destinationPosition,
    this.routePoints = const [],
    required this.journeyStatus,
    required this.riskLevel,
    this.height = 240,
  });

  @override
  State<JourneyMapView> createState() => _JourneyMapViewState();
}

class _JourneyMapViewState extends State<JourneyMapView> {
  final MapController _mapController = MapController();

  @override
  void didUpdateWidget(covariant JourneyMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPosition != widget.currentPosition ||
        oldWidget.destinationPosition != widget.destinationPosition ||
        oldWidget.routePoints.length != widget.routePoints.length) {
      _fitMapToContent();
    }
  }

  void _fitMapToContent() {
    try {
      if (widget.routePoints.length > 1) {
        final bounds = LatLngBounds.fromPoints(widget.routePoints);
        _mapController.fitCamera(CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(32),
        ));
      } else if (widget.destinationPosition != null) {
        final bounds = LatLngBounds.fromPoints([widget.currentPosition, widget.destinationPosition!]);
        _mapController.fitCamera(CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(32),
        ));
      } else {
        _mapController.move(widget.currentPosition, 14.5);
      }
    } catch (_) {
      _mapController.move(widget.currentPosition, 14.5);
    }
  }

  Color _getRouteColor() {
    switch (widget.riskLevel) {
      case RiskLevel.high:
        return AppColors.riskHigh;
      case RiskLevel.unusual:
        return const Color(0xFFF59E0B); // Amber / Warning Yellow
      case RiskLevel.normal:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeColor = _getRouteColor();
    final bool showHazard = widget.journeyStatus == JourneyStatus.unusualActivity ||
        widget.journeyStatus == JourneyStatus.safetyAlert;

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.currentPosition,
              initialZoom: 14.5,
              minZoom: 5.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // OpenStreetMap Standard Tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.aegispatrol.safety',
                tileProvider: NetworkTileProvider(),
              ),

              // Hazard / Risk Circle highlight if unusual or safety alert
              if (showHazard)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: widget.currentPosition,
                      radius: widget.journeyStatus == JourneyStatus.safetyAlert ? 90 : 65,
                      useRadiusInMeter: true,
                      color: (widget.journeyStatus == JourneyStatus.safetyAlert
                              ? AppColors.riskHigh
                              : const Color(0xFFF59E0B))
                          .withValues(alpha: 0.22),
                      borderColor: widget.journeyStatus == JourneyStatus.safetyAlert
                          ? AppColors.riskHigh
                          : const Color(0xFFF59E0B),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),

              // Polyline Route
              if (widget.routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: widget.routePoints,
                      strokeWidth: 5.0,
                      color: routeColor,
                      borderStrokeWidth: 2.0,
                      borderColor: Colors.white.withValues(alpha: 0.8),
                    ),
                  ],
                ),

              // Markers Layer
              MarkerLayer(
                markers: [
                  // Start / Civilian Current Location Marker
                  Marker(
                    point: widget.currentPosition,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: routeColor, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.directions_car_rounded,
                        color: routeColor,
                        size: 24,
                      ),
                    ),
                  ),

                  // Destination Marker
                  if (widget.destinationPosition != null)
                    Marker(
                      point: widget.destinationPosition!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.error,
                        size: 38,
                      ),
                    ),

                  // Hazard warning marker if unusual / safety alert
                  if (showHazard)
                    Marker(
                      point: widget.currentPosition,
                      width: 32,
                      height: 32,
                      alignment: Alignment.topRight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.journeyStatus == JourneyStatus.safetyAlert
                              ? AppColors.riskHigh
                              : const Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Re-center floating button
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.my_location_rounded, size: 20, color: AppColors.textPrimary),
                onPressed: () {
                  _mapController.move(widget.currentPosition, 14.5);
                },
              ),
            ),
          ),

          // OSM Attribution badge
          Positioned(
            left: 8,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '© OpenStreetMap',
                style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
