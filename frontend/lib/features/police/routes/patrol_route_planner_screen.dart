import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../models/patrol_domain_models.dart';
import '../../../providers/patrol_intelligence_provider.dart';
import '../patrol/live_patrol_monitoring_screen.dart';

class PatrolRoutePlannerScreen extends StatefulWidget {
  final HexCell? destinationHex;

  const PatrolRoutePlannerScreen({super.key, this.destinationHex});

  @override
  State<PatrolRoutePlannerScreen> createState() => _PatrolRoutePlannerScreenState();
}

class _PatrolRoutePlannerScreenState extends State<PatrolRoutePlannerScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    if (widget.destinationHex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = Provider.of<PatrolIntelligenceProvider>(context, listen: false);
        provider.generateNewRoute(
          start: const LatLng(19.0400, 72.8620), // Sion
          destination: widget.destinationHex!.center,
          startName: 'Start (Sion Command Hub)',
          destName: 'End (${widget.destinationHex!.name})',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PatrolIntelligenceProvider>(context);
    final isDarkMode = provider.isDarkMode;
    final route = provider.activeRoute;

    final bgColor = isDarkMode ? const Color(0xFF071A2E) : const Color(0xFFF5F8FC);
    final cardBg = isDarkMode ? const Color(0xFF0E263D) : Colors.white;
    final textPrimary = isDarkMode ? Colors.white : const Color(0xFF10233D);
    final textSecondary = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF63758A);
    final borderColor = isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Plan Patrol Route',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: textSecondary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Patrol routing algorithm: H3 Multi-Objective Place-Time')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Safe Route vs Quickest Route Toggle (Reference A Screen 3)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF0E263D) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => provider.setRouteMode('safe'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: route.mode == 'safe' ? const Color(0xFF147DF5) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Safe Route',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: route.mode == 'safe' ? Colors.white : textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => provider.setRouteMode('quickest'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: route.mode == 'quickest' ? const Color(0xFF147DF5) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Quickest Route',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: route.mode == 'quickest' ? Colors.white : textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Route Preview Map Container with distance & time stats overlay
            Container(
              height: 250,
              margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: const MapOptions(
                      initialCenter: LatLng(19.0750, 72.8550),
                      initialZoom: 12.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: isDarkMode
                            ? 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                            : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.aegispatrol.safety',
                      ),
                      // Hexagon risk overlays
                      PolygonLayer(
                        polygons: provider.hexCells.map((hex) {
                          return Polygon(
                            points: hex.polygonPoints,
                            color: hex.riskBand.fillColor,
                            borderColor: hex.riskBand.color.withValues(alpha: 0.6),
                            borderStrokeWidth: 1.2,
                          );
                        }).toList(),
                      ),
                      // Polyline route
                      if (route.polylinePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: route.polylinePoints,
                              strokeWidth: 4.5,
                              color: const Color(0xFF20C7E8),
                              borderColor: Colors.white.withValues(alpha: 0.8),
                              borderStrokeWidth: 1.5,
                            ),
                          ],
                        ),
                      // Markers for Start, Stops & End
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: route.startLocation,
                            width: 32,
                            height: 32,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF147DF5),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text('S', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ),
                          ),
                          Marker(
                            point: route.endLocation,
                            width: 34,
                            height: 34,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFFEA3F4F),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.flag_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Distance & Time Overlay Box (Reference A Screen 3)
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF071A2E).withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Route Distance: ',
                                style: TextStyle(fontSize: 11, color: textSecondary),
                              ),
                              Text(
                                '${route.distanceKm} km',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.timer_outlined, size: 12, color: textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                'Est. Time: ',
                                style: TextStyle(fontSize: 11, color: textSecondary),
                              ),
                              Text(
                                '${route.estTimeMinutes} min',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textPrimary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Priority Areas Row (Responsive Horizontal Scroll)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Priority Areas',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPriorityPill('High Risk', '${route.highRiskAreas}', const Color(0xFFEA3F4F), isDarkMode),
                        const SizedBox(width: 8),
                        _buildPriorityPill('Medium Risk', '${route.mediumRiskAreas}', const Color(0xFFF4A51C), isDarkMode),
                        const SizedBox(width: 8),
                        _buildPriorityPill('Low Risk', '${route.lowRiskAreas}', const Color(0xFF18B875), isDarkMode),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Route Stops Section (Reference A Screen 3)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Route Stops',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...route.stops.map(
                    (stop) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Color(0xFF147DF5),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${stop.index}',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              stop.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${stop.distanceKm} km',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Route Preferences Section (Reference A Screen 3)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Route Preferences',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Avoid High-Risk Zones', style: TextStyle(fontSize: 13, color: textPrimary)),
                      value: route.avoidHighRiskZones,
                      activeTrackColor: const Color(0xFF147DF5),
                      onChanged: (val) => provider.toggleRoutePreference(avoidHighRisk: val),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Prefer Main Roads', style: TextStyle(fontSize: 13, color: textPrimary)),
                      value: route.preferMainRoads,
                      activeTrackColor: const Color(0xFF147DF5),
                      onChanged: (val) => provider.toggleRoutePreference(preferMain: val),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Include Police Checkpoints', style: TextStyle(fontSize: 13, color: textPrimary)),
                      value: route.includePoliceCheckpoints,
                      activeTrackColor: const Color(0xFF147DF5),
                      onChanged: (val) => provider.toggleRoutePreference(includeCheckpoints: val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Bottom Action Buttons: Generate Route + Start Live Patrol
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF147DF5), Color(0xFF20C7E8)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF147DF5).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        provider.startLivePatrol();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LivePatrolMonitoringScreen()),
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_car_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Start Live Patrol',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityPill(String label, String count, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0E263D) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $count',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.white : const Color(0xFF10233D),
            ),
          ),
        ],
      ),
    );
  }
}
