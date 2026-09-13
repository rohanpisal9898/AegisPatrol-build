import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import '../../../models/patrol_domain_models.dart';
import '../../../providers/patrol_intelligence_provider.dart';
import '../dispatch/patrol_dispatch_summary_screen.dart';

class LivePatrolMonitoringScreen extends StatefulWidget {
  const LivePatrolMonitoringScreen({super.key});

  @override
  State<LivePatrolMonitoringScreen> createState() => _LivePatrolMonitoringScreenState();
}

class _LivePatrolMonitoringScreenState extends State<LivePatrolMonitoringScreen> {
  final MapController _mapController = MapController();
  int _activeTabIndex = 0; // 0: Active Units, 1: Recent Activity, 2: Alerts

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PatrolIntelligenceProvider>(context);
    final isDarkMode = provider.isDarkMode;
    final units = provider.patrolUnits;
    final route = provider.activeRoute;
    final unitP12 = units.first;

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
          'Live Patrol',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: textPrimary,
          ),
        ),
        actions: [
          // Live Pulse Badge (Reference A Screen 4)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF18B875).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF18B875)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF18B875),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF18B875),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Dynamic Reroute Alert Banner if risk condition changes during patrol (Mission Requirement 5)
          if (provider.hasPendingReroute)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEA3F4F).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEA3F4F), width: 1.4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_rounded, color: Color(0xFFEA3F4F), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Priority Changed Nearby',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFEA3F4F),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          provider.rerouteReason.isNotEmpty
                              ? provider.rerouteReason
                              : 'Incident detected along primary route.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA3F4F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      provider.applyReroute();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Patrol route optimized via western bypass.'),
                          backgroundColor: Color(0xFF18B875),
                        ),
                      );
                    },
                    child: const Text('REROUTE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                ],
              ),
            ),

          // Live Interactive Map (Top Half)
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: unitP12.position,
                    initialZoom: 13.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: isDarkMode
                          ? 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                          : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.aegispatrol.safety',
                    ),
                    // Hexagons
                    PolygonLayer(
                      polygons: provider.hexCells.map((hex) {
                        return Polygon(
                          points: hex.polygonPoints,
                          color: hex.riskBand.fillColor,
                          borderColor: hex.riskBand.color.withValues(alpha: 0.5),
                          borderStrokeWidth: 1.2,
                        );
                      }).toList(),
                    ),
                    // Polyline route trail
                    if (route.polylinePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: route.polylinePoints,
                            strokeWidth: 4.5,
                            color: const Color(0xFF147DF5),
                          ),
                        ],
                      ),
                    // Patrol Unit Markers
                    MarkerLayer(
                      markers: [
                        // Unit P-12 (Active Car with pulsing radar)
                        Marker(
                          point: unitP12.position,
                          width: 52,
                          height: 52,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF147DF5).withValues(alpha: 0.25),
                                ),
                              ),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF147DF5),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 20),
                              ),
                            ],
                          ),
                        ),
                        // Unit P-08
                        Marker(
                          point: units[1].position,
                          width: 38,
                          height: 38,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0E263D),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF20C7E8), width: 1.8),
                            ),
                            child: const Icon(Icons.shield_rounded, color: Color(0xFF20C7E8), size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Floating Live Unit Tag (Reference A Screen 4)
                Positioned(
                  left: 16,
                  top: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF071A2E).withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF18B875),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${unitP12.id} • ${unitP12.speedKmH} km/h',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Recenter location button
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: FloatingActionButton.small(
                    heroTag: 'recenter_live',
                    backgroundColor: cardBg,
                    foregroundColor: textPrimary,
                    onPressed: () {
                      _mapController.move(unitP12.position, 14.0);
                    },
                    child: const Icon(Icons.my_location_rounded, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Dashboard Section (Reference A Screen 4)
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: borderColor, width: 1.2)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Units Summary Row: Total Units 12 Active | On Duty 10 | Available 2
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(child: _buildSummaryItem('Total Units', '12 Active', textPrimary, textSecondary)),
                        Container(width: 1, height: 26, color: borderColor),
                        Expanded(child: _buildSummaryItem('On Duty', '10', const Color(0xFF18B875), textSecondary)),
                        Container(width: 1, height: 26, color: borderColor),
                        Expanded(child: _buildSummaryItem('Available', '2', const Color(0xFF147DF5), textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Divider(height: 1, color: borderColor),

                  // Tabs: Active Units | Recent Activity | Alerts (Horizontally scrollable / responsive)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildTabItem('Active Units', 0, isDarkMode),
                          const SizedBox(width: 8),
                          _buildTabItem('Recent Activity', 1, isDarkMode),
                          const SizedBox(width: 8),
                          _buildTabItem('Alerts', 2, isDarkMode),
                        ],
                      ),
                    ),
                  ),

                  // Tab Content
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      children: [
                        if (_activeTabIndex == 0) ...[
                          ...units.map(
                            (unit) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDarkMode ? const Color(0xFF071A2E) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: unit.stateBg,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.local_police_rounded, color: unit.stateColor, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          unit.id,
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${unit.sectorName} • ${unit.speedKmH} km/h',
                                          style: TextStyle(fontSize: 11.5, color: textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: unit.stateBg,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      unit.stateLabel,
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: unit.stateColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else if (_activeTabIndex == 1) ...[
                          _buildActivityItem('Unit P-12 verified checkpoint at Andheri Metro', '2 min ago', textPrimary, textSecondary),
                          _buildActivityItem('Unit P-08 acknowledged CCTV anomaly at Kurla', '9 min ago', textPrimary, textSecondary),
                          _buildActivityItem('Unit P-05 stationed at Dadar central station', '22 min ago', textPrimary, textSecondary),
                        ] else ...[
                          ...provider.alerts.take(3).map(
                                (alert) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? const Color(0xFF071A2E) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(alert.icon, size: 18, color: alert.iconColor),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          alert.title,
                                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textPrimary),
                                        ),
                                      ),
                                      Text(
                                        alert.timeAgo,
                                        style: TextStyle(fontSize: 11, color: textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        ],
                      ],
                    ),
                  ),

                  // Bottom Action Bar: Complete Patrol / Dispatch Summary
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFEA3F4F),
                              side: const BorderSide(color: Color(0xFFEA3F4F), width: 1.2),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              provider.endLivePatrol();
                              Navigator.of(context).pop();
                            },
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('End Patrol', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF147DF5),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const PatrolDispatchSummaryScreen()),
                              );
                            },
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Dispatch Summary', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, Color valueColor, Color titleColor) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 11, color: titleColor)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: valueColor)),
      ],
    );
  }

  Widget _buildTabItem(String label, int index, bool isDarkMode) {
    final isSelected = _activeTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF147DF5) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : (isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF63758A)),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(String text, String time, Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: Color(0xFF20C7E8), shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12.5, color: textPrimary)),
          ),
          const SizedBox(width: 8),
          Text(time, style: TextStyle(fontSize: 11, color: textSecondary)),
        ],
      ),
    );
  }
}
