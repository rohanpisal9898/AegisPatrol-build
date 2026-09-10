import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/patrol_intelligence_provider.dart';
import '../incidents/incident_reporting_sheet.dart';

class PatrolDispatchSummaryScreen extends StatelessWidget {
  const PatrolDispatchSummaryScreen({super.key});

  void _showBackupDialog(BuildContext context, PatrolIntelligenceProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: provider.isDarkMode ? const Color(0xFF0E263D) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Deploy Reinforcements',
          style: TextStyle(
            color: provider.isDarkMode ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select unit to dispatch backup to Sector 7A (Andheri East):',
              style: TextStyle(
                color: provider.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            ...provider.patrolUnits.map(
              (u) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.shield_rounded, color: Color(0xFF147DF5)),
                title: Text(u.id, style: TextStyle(color: provider.isDarkMode ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold)),
                subtitle: Text('${u.sectorName} (${u.stateLabel})', style: const TextStyle(fontSize: 11)),
                trailing: TextButton(
                  onPressed: () {
                    provider.dispatchBackup('alert_1', u.id);
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Backup unit ${u.id} dispatched to Sector 7A!'),
                        backgroundColor: const Color(0xFF18B875),
                      ),
                    );
                  },
                  child: const Text('DISPATCH', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBroadcastDialog(BuildContext context, PatrolIntelligenceProvider provider) {
    final controller = TextEditingController(text: 'High vigilance alert active across Western Express Highway corridors.');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: provider.isDarkMode ? const Color(0xFF0E263D) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Broadcast Area Alert',
          style: TextStyle(
            color: provider.isDarkMode ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
          ),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: TextStyle(color: provider.isDarkMode ? Colors.white : const Color(0xFF0F172A)),
          decoration: const InputDecoration(
            hintText: 'Enter dispatch broadcast message...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF147DF5)),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Operational broadcast transmitted to all on-duty units.'),
                  backgroundColor: Color(0xFF147DF5),
                ),
              );
            },
            child: const Text('BROADCAST', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PatrolIntelligenceProvider>(context);
    final isDarkMode = provider.isDarkMode;

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
          'Dispatch Summary',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list_rounded, color: textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radial Coverage & Total Incidents Card (Reference A Screen 5)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  // Circular Progress Gauge 78% (Risk Coverage)
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: CustomPaint(
                      painter: _RadialGaugePainter(
                        percentage: 0.78,
                        progressColor: const Color(0xFFF4A51C),
                        backgroundColor: isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '78%',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              'Coverage',
                              style: TextStyle(fontSize: 9.5, color: textSecondary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Total Incidents Breakdown
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total Incidents', style: TextStyle(fontSize: 12, color: textSecondary)),
                                const SizedBox(height: 2),
                                Text(
                                  '${provider.totalIncidentsToday}',
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textPrimary),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDarkMode ? const Color(0xFF071A2E) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  Text('Today', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textSecondary)),
                                  const Icon(Icons.arrow_drop_down, size: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Severity distribution pills (High: 14, Medium: 22, Low: 12)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSeverityMiniStat('High', '${provider.highIncidentsCount}', const Color(0xFFEA3F4F), textPrimary, textSecondary),
                            _buildSeverityMiniStat('Medium', '${provider.mediumIncidentsCount}', const Color(0xFFF4A51C), textPrimary, textSecondary),
                            _buildSeverityMiniStat('Low', '${provider.lowIncidentsCount}', const Color(0xFF18B875), textPrimary, textSecondary),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Recent Incidents Section (Reference A Screen 5)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Incidents',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary),
                ),
                const Text(
                  'View All',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF147DF5)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            _buildIncidentItem(
              title: 'Theft Attempt',
              location: 'Sector 7A - Andheri',
              time: '10:42 AM',
              severity: 'High',
              severityColor: const Color(0xFFEA3F4F),
              severityBg: const Color(0xFFFEE2E2),
              icon: Icons.warning_amber_rounded,
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 8),

            _buildIncidentItem(
              title: 'Public Disturbance',
              location: 'Bandra West',
              time: '09:15 AM',
              severity: 'Medium',
              severityColor: const Color(0xFFF4A51C),
              severityBg: const Color(0xFFFEF3C7),
              icon: Icons.groups_rounded,
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 8),

            _buildIncidentItem(
              title: 'Traffic Violation',
              location: 'Kurla',
              time: '08:32 AM',
              severity: 'Low',
              severityColor: const Color(0xFF18B875),
              severityBg: const Color(0xFFD1FAE5),
              icon: Icons.directions_car_rounded,
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 8),

            _buildIncidentItem(
              title: 'Vandalism',
              location: 'Dadar',
              time: '07:50 AM',
              severity: 'Low',
              severityColor: const Color(0xFF18B875),
              severityBg: const Color(0xFFD1FAE5),
              icon: Icons.shield_outlined,
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 20),

            // Quick Actions (2x2 Grid from Reference A Screen 5)
            Text(
              'Quick Actions',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.shield_rounded,
                    label: 'Send Backup',
                    iconColor: const Color(0xFF147DF5),
                    bgColor: isDarkMode ? const Color(0xFF0E263D) : Colors.white,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    onTap: () => _showBackupDialog(context, provider),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.add_box_rounded,
                    label: 'Create Incident',
                    iconColor: const Color(0xFF8B5CF6),
                    bgColor: isDarkMode ? const Color(0xFF0E263D) : Colors.white,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
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
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.campaign_rounded,
                    label: 'Broadcast Alert',
                    iconColor: const Color(0xFFF97316),
                    bgColor: isDarkMode ? const Color(0xFF0E263D) : Colors.white,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    onTap: () => _showBroadcastDialog(context, provider),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.sync_rounded,
                    label: 'Update Status',
                    iconColor: const Color(0xFF10B981),
                    bgColor: isDarkMode ? const Color(0xFF0E263D) : Colors.white,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All unit statuses and geo-beacons synchronized.'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Bottom Complete Patrol Button (Reference A Screen 5)
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF147DF5), Color(0xFF18B875)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF18B875).withValues(alpha: 0.35),
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
                  provider.endLivePatrol();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Shift Patrol Marked Complete! Summary logged to department dispatch.'),
                      backgroundColor: Color(0xFF18B875),
                    ),
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Mark Patrol Complete',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityMiniStat(String label, String count, Color color, Color textPrimary, Color textSecondary) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label ',
          style: TextStyle(fontSize: 11, color: textSecondary),
        ),
        Text(
          count,
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: textPrimary),
        ),
      ],
    );
  }

  Widget _buildIncidentItem({
    required String title,
    required String location,
    required String time,
    required String severity,
    required Color severityColor,
    required Color severityBg,
    required IconData icon,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: severityColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textPrimary)),
                const SizedBox(height: 2),
                Text('$location • $time', style: TextStyle(fontSize: 11, color: textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: severityBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              severity,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: severityColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required Color textPrimary,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadialGaugePainter extends CustomPainter {
  final double percentage;
  final Color progressColor;
  final Color backgroundColor;

  _RadialGaugePainter({
    required this.percentage,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * percentage,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RadialGaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.progressColor != progressColor;
  }
}
