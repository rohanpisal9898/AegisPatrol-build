import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../models/patrol_domain_models.dart';
import '../../../providers/patrol_intelligence_provider.dart';
import 'widgets/hexagon_risk_detail_sheet.dart';
import '../routes/patrol_route_planner_screen.dart';
import '../patrol/live_patrol_monitoring_screen.dart';
import '../dispatch/patrol_dispatch_summary_screen.dart';
import '../incidents/incident_reporting_sheet.dart';

class PoliceHomeScreen extends StatefulWidget {
  const PoliceHomeScreen({super.key});

  @override
  State<PoliceHomeScreen> createState() => _PoliceHomeScreenState();
}

class _PoliceHomeScreenState extends State<PoliceHomeScreen> {
  final MapController _mapController = MapController();
  final LatLng _mumbaiCenter = const LatLng(19.0760, 72.8777);

  void _showDemoScenariosSheet(BuildContext context, PatrolIntelligenceProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: provider.isDarkMode ? const Color(0xFF0E263D) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: Color(0xFFF4A51C), size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Live Intelligence Demo Simulator',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Simulate live operational events. Data reactively recalculates across Map, Alerts, Assignments & Patrol.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.videocam_rounded, color: Color(0xFFDC2626), size: 20),
              ),
              title: const Text('CCTV Anomaly & Crowd Surge in Andheri', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
              subtitle: const Text('Andheri risk 92 -> 96, new alert, reroute prompt', style: TextStyle(fontSize: 11)),
              onTap: () {
                provider.triggerDemoScenario('cctv_andheri');
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Simulated CCTV surge! Sector 7A risk increased, high alert added.'),
                    backgroundColor: Color(0xFFEA3F4F),
                  ),
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.emergency_rounded, color: Color(0xFFD97706), size: 20),
              ),
              title: const Text("Women's Safety Distress in Jogeshwari", style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
              subtitle: const Text('Critical SOS journey triggered, patrol interception', style: TextStyle(fontSize: 11)),
              onTap: () {
                provider.triggerDemoScenario('sos_jogeshwari');
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Simulated Women's Safety Distress! Critical alert created."),
                    backgroundColor: Color(0xFFEA3F4F),
                  ),
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: const Color(0xFFFFEDD5), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.car_crash_rounded, color: Color(0xFFEA580C), size: 20),
              ),
              title: const Text('Western Express Highway Collision', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
              subtitle: const Text('Corridor risk escalation, traffic congestion alert', style: TextStyle(fontSize: 11)),
              onTap: () {
                provider.triggerDemoScenario('accident_weh');
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Simulated Highway accident! Corridors updated.'),
                    backgroundColor: Color(0xFFF97316),
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text('Reset All Demo Data to Baseline'),
                onPressed: () {
                  provider.triggerDemoScenario('reset');
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Demo intelligence state reset to initial baseline.')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PatrolIntelligenceProvider>(context);
    final isDarkMode = provider.isDarkMode;
    final hexCells = provider.hexCells;

    final bgColor = isDarkMode ? const Color(0xFF071A2E) : const Color(0xFFF5F8FC);
    final cardBg = isDarkMode ? const Color(0xFF0E263D) : Colors.white;
    final textPrimary = isDarkMode ? Colors.white : const Color(0xFF10233D);
    final textSecondary = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF63758A);
    final borderColor = isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0);

    // Calculate dynamic risk counts matching Reference B
    final highCount = hexCells.where((h) => h.riskScore >= 70).length;
    final elevatedCount = hexCells.where((h) => h.riskScore >= 50 && h.riskScore < 70).length;
    final lowCount = hexCells.where((h) => h.riskScore < 50).length;

    // Top priority assignment
    final topPriority = provider.assignments.first;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Operational Header matching Reference A & B
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              color: isDarkMode ? const Color(0xFF071A2E) : const Color(0xFF0B2239),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Shield Logo
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF147DF5).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF20C7E8), width: 1.2),
                        ),
                        child: const Icon(Icons.shield_rounded, color: Color(0xFF20C7E8), size: 20),
                      ),
                      const SizedBox(width: 10),

                      // App Name & Subtitle
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AEGISPATROL',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              'Safer Cities. Stronger Communities.',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Quick Demo Simulator Trigger
                      GestureDetector(
                        onTap: () => _showDemoScenariosSheet(context, provider),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4A51C).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFF4A51C), width: 1.0),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFF4A51C)),
                              SizedBox(width: 4),
                              Text(
                                'DEMO',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFF4A51C),
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Theme Toggle (Dark Command-Centre vs Light Field)
                      IconButton(
                        tooltip: 'Toggle Theme (Dark Command vs Light Field)',
                        icon: Icon(
                          isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                          color: const Color(0xFFCBD5E1),
                          size: 20,
                        ),
                        onPressed: provider.toggleTheme,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Risk Overview Metric Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.radar_rounded, size: 15, color: Color(0xFF147DF5)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'HOTSPOTS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: textSecondary,
                        letterSpacing: 0.6,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 3 Metric Counters: High Risk | Elevated Risk | Low Risk
                  _buildMetricCounter('High', '$highCount', const Color(0xFFEA3F4F), textPrimary, textSecondary),
                  const SizedBox(width: 10),
                  _buildMetricCounter('Elevated', '$elevatedCount', const Color(0xFFF4A51C), textPrimary, textSecondary),
                  const SizedBox(width: 10),
                  _buildMetricCounter('Low', '$lowCount', const Color(0xFF18B875), textPrimary, textSecondary),
                ],
              ),
            ),

            // Primary Map View with True Geospatial H3 Hexagons (Reference A & B)
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _mumbaiCenter,
                      initialZoom: 12.2,
                      minZoom: 9.0,
                      maxZoom: 18.0,
                    ),
                    children: [
                      // CartoDB dark or OSM standard map tiles
                      TileLayer(
                        urlTemplate: isDarkMode
                            ? 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                            : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.aegispatrol.safety',
                      ),

                      // Real Geographic H3 Hexagon Polygon Layer
                      PolygonLayer(
                        polygons: hexCells.map((hex) {
                          final isSelected = provider.selectedHexCell?.id == hex.id;
                          return Polygon(
                            points: hex.polygonPoints,
                            color: isSelected
                                ? hex.riskBand.color.withValues(alpha: 0.6)
                                : hex.riskBand.fillColor,
                            borderColor: isSelected
                                ? Colors.white
                                : hex.riskBand.color.withValues(alpha: 0.8),
                            borderStrokeWidth: isSelected ? 2.5 : 1.2,
                          );
                        }).toList(),
                      ),

                      // Markers on Map: Hexagon Centers + Incidents + Police Checkpoints
                      MarkerLayer(
                        markers: [
                          // Center Risk Scores for Hexagons
                          ...hexCells.map(
                            (hex) => Marker(
                              point: hex.center,
                              width: 36,
                              height: 36,
                              child: GestureDetector(
                                onTap: () {
                                  provider.selectHexCell(hex);
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => HexagonRiskDetailSheet(
                                      cell: hex,
                                      isDarkMode: isDarkMode,
                                      onViewNearbyIncidents: () {
                                        provider.setAlertTab('All');
                                      },
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: hex.riskBand.color,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.35),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${hex.riskScore.round()}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Active Patrol Unit P-12 Marker
                          Marker(
                            point: provider.patrolUnits.first.position,
                            width: 38,
                            height: 38,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF147DF5),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF147DF5).withValues(alpha: 0.4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 20),
                            ),
                          ),

                          // Police Checkpoint Shields (Reference B Screen 1)
                          Marker(
                            point: const LatLng(19.0596, 72.8368), // Bandra
                            width: 28,
                            height: 28,
                            child: Container(
                              decoration: const BoxDecoration(color: Color(0xFF147DF5), shape: BoxShape.circle),
                              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                          Marker(
                            point: const LatLng(19.0178, 72.8478), // Dadar
                            width: 28,
                            height: 28,
                            child: Container(
                              decoration: const BoxDecoration(color: Color(0xFF147DF5), shape: BoxShape.circle),
                              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Floating Map Controls (Zoom In/Out, Recenter)
                  Positioned(
                    right: 14,
                    top: 14,
                    child: Column(
                      children: [
                        _buildMapActionButton(
                          icon: Icons.navigation_rounded,
                          onTap: () => _mapController.move(_mumbaiCenter, 12.2),
                          cardBg: cardBg,
                          borderColor: borderColor,
                          iconColor: textPrimary,
                        ),
                        const SizedBox(height: 8),
                        _buildMapActionButton(
                          icon: Icons.add_rounded,
                          onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
                          cardBg: cardBg,
                          borderColor: borderColor,
                          iconColor: textPrimary,
                        ),
                        const SizedBox(height: 4),
                        _buildMapActionButton(
                          icon: Icons.remove_rounded,
                          onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
                          cardBg: cardBg,
                          borderColor: borderColor,
                          iconColor: textPrimary,
                        ),
                      ],
                    ),
                  ),

                  // Floating Operational Action Dock (Plan Route, Live Patrol, Summary, Report)
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 96,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: cardBg.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: _buildDockButton(
                              icon: Icons.alt_route_rounded,
                              label: 'Plan Route',
                              color: const Color(0xFF147DF5),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const PatrolRoutePlannerScreen()),
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: _buildDockButton(
                              icon: Icons.local_police_rounded,
                              label: 'Live Patrol',
                              color: const Color(0xFF18B875),
                              onTap: () {
                                provider.startLivePatrol();
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const LivePatrolMonitoringScreen()),
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: _buildDockButton(
                              icon: Icons.pie_chart_outline_rounded,
                              label: 'Dispatch',
                              color: const Color(0xFFF4A51C),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const PatrolDispatchSummaryScreen()),
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: _buildDockButton(
                              icon: Icons.add_circle_outline_rounded,
                              label: 'Report',
                              color: const Color(0xFFEA3F4F),
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => const IncidentReportingSheet(),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Floating CURRENT PRIORITY Card (Reference B Screen 1)
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF0E263D) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFFFEE2E2),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDarkMode ? 0.4 : 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            final targetHex = hexCells.firstWhere((h) => h.id == topPriority.hexId);
                            provider.selectHexCell(targetHex);
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => HexagonRiskDetailSheet(
                                cell: targetHex,
                                isDarkMode: isDarkMode,
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFEE2E2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.priority_high_rounded, color: Color(0xFFDC2626), size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'CURRENT PRIORITY',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFDC2626),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        topPriority.sectorName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w900,
                                          color: textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Risk ${topPriority.riskScore} • High risk • ${topPriority.coverage} coverage',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    '#1',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: textSecondary),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCounter(String label, String count, Color dotColor, Color textPrimary, Color textSecondary) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              count.padLeft(2, '0'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: textPrimary,
                height: 1.1,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 9.5, color: textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMapActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color cardBg,
    required Color borderColor,
    required Color iconColor,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 18, color: iconColor),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildDockButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
