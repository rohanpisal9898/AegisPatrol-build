import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../models/patrol_domain_models.dart';
import '../../routes/patrol_route_planner_screen.dart';

class HexagonRiskDetailSheet extends StatelessWidget {
  final HexCell cell;
  final bool isDarkMode;
  final VoidCallback? onViewNearbyIncidents;

  const HexagonRiskDetailSheet({
    super.key,
    required this.cell,
    this.isDarkMode = true,
    this.onViewNearbyIncidents,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDarkMode ? const Color(0xFF071A2E) : Colors.white;
    final cardBg = isDarkMode ? const Color(0xFF0E263D) : const Color(0xFFF8FAFC);
    final textPrimary = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: borderColor, width: 1.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.6 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sheet Handle Bar
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title Header Row matching Reference A Screen 2: "Sector 7A - Andheri East"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cell.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Zone Type: ${cell.zoneType}',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cell.riskBand.badgeBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          cell.riskBand.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: cell.riskBand.badgeText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.bookmark_border_rounded, color: textSecondary, size: 22),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Bookmarked ${cell.name} for surveillance'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Visual Hexagon Neighbor Cluster Representation (Reference A Screen 2)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Center(
                  child: SizedBox(
                    width: 220,
                    height: 190,
                    child: CustomPaint(
                      painter: _HexClusterPainter(
                        centerScore: cell.riskScore.round(),
                        centerLabel: cell.riskBand.label,
                        centerColor: cell.riskBand.color,
                        neighborScores: cell.neighborScores,
                        isDarkMode: isDarkMode,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Sector Location & Metadata Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF147DF5).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.location_on_rounded, color: Color(0xFF147DF5), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Geographic Coordinates',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${cell.latDegStr}, ${cell.lngDegStr}',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textPrimary),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Incidents', style: TextStyle(fontSize: 10, color: textSecondary)),
                        Text('${cell.incidentCount}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Risk Factors Header & Progress Values (Reference A Screen 2)
              Text(
                'Risk Factors',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              _buildRiskFactorBar(
                title: 'Theft',
                icon: Icons.fingerprint_rounded,
                progress: cell.riskFactors.theft,
                tag: cell.riskFactors.theft >= 0.7 ? 'High' : (cell.riskFactors.theft >= 0.4 ? 'Moderate' : 'Low'),
                color: const Color(0xFFEA3F4F),
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 8),

              _buildRiskFactorBar(
                title: 'Assault',
                icon: Icons.front_hand_rounded,
                progress: cell.riskFactors.assault,
                tag: cell.riskFactors.assault >= 0.7 ? 'High' : (cell.riskFactors.assault >= 0.4 ? 'Moderate' : 'Low'),
                color: const Color(0xFFF95738),
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 8),

              _buildRiskFactorBar(
                title: 'Vandalism',
                icon: Icons.broken_image_outlined,
                progress: cell.riskFactors.vandalism,
                tag: cell.riskFactors.vandalism >= 0.7 ? 'High' : (cell.riskFactors.vandalism >= 0.4 ? 'Moderate' : 'Low'),
                color: const Color(0xFFF4A51C),
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 8),

              _buildRiskFactorBar(
                title: 'Traffic Violation',
                icon: Icons.directions_car_rounded,
                progress: cell.riskFactors.trafficViolation,
                tag: cell.riskFactors.trafficViolation >= 0.7 ? 'High' : (cell.riskFactors.trafficViolation >= 0.4 ? 'Moderate' : 'Low'),
                color: const Color(0xFFF97316),
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 8),

              _buildRiskFactorBar(
                title: 'Drug Activity',
                icon: Icons.medication_liquid_rounded,
                progress: cell.riskFactors.drugActivity,
                tag: cell.riskFactors.drugActivity >= 0.7 ? 'High' : (cell.riskFactors.drugActivity >= 0.4 ? 'Moderate' : 'Low'),
                color: const Color(0xFF64748B),
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 18),

              // "Why is this area a priority?" (Reference B & Prompt)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF0A223B) : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode ? const Color(0xFF147DF5).withValues(alpha: 0.3) : const Color(0xFFFDE68A),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: isDarkMode ? const Color(0xFF20C7E8) : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Why is this area a priority?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isDarkMode ? Colors.white : const Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...cell.whyPriorityReasons.map(
                      (reason) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• ',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: isDarkMode ? const Color(0xFF20C7E8) : const Color(0xFFD97706),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                reason,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF78350F),
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons Row: "Plan Patrol Route" + "View Nearby Incidents ->"
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textPrimary,
                        side: BorderSide(color: borderColor, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.route_outlined, size: 18),
                      label: const Text(
                        'Plan Route',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PatrolRoutePlannerScreen(destinationHex: cell),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF147DF5), Color(0xFF4F46E5)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF147DF5).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (onViewNearbyIncidents != null) {
                            onViewNearbyIncidents!();
                          }
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'View Incidents',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskFactorBar({
    required String title,
    required IconData icon,
    required double progress,
    required String tag,
    required Color color,
    required bool isDarkMode,
  }) {
    final textPrimary = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final trackColor = isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        SizedBox(
          width: 85,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.05, 1.0),
              minHeight: 6,
              backgroundColor: trackColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: Text(
            tag,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter to render the exact hexagonal neighbor diagram from Reference A Screen 2
class _HexClusterPainter extends CustomPainter {
  final int centerScore;
  final String centerLabel;
  final Color centerColor;
  final Map<int, double> neighborScores;
  final bool isDarkMode;

  _HexClusterPainter({
    required this.centerScore,
    required this.centerLabel,
    required this.centerColor,
    required this.neighborScores,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const hexRadius = 32.0;

    // Draw 6 surrounding neighbor hexagons
    // Angles for 6 directions: 0, 60, 120, 180, 240, 300
    final distance = hexRadius * math.sqrt(3);

    for (int i = 0; i < 6; i++) {
      final angle = (60.0 * i - 30.0) * math.pi / 180.0;
      final neighborCenter = Offset(
        center.dx + distance * math.cos(angle),
        center.dy + distance * math.sin(angle),
      );

      final score = neighborScores[i] ?? 50.0;
      _drawHexagon(
        canvas: canvas,
        center: neighborCenter,
        radius: hexRadius * 0.9,
        fillColor: isDarkMode ? const Color(0xFF0E263D) : const Color(0xFFF1F5F9),
        strokeColor: isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFFCBD5E1),
        strokeWidth: 1.0,
      );

      _drawText(
        canvas: canvas,
        center: neighborCenter,
        text: '${score.round()}',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      );
    }

    // Draw prominent Center Hexagon (Score 92 High Risk)
    _drawHexagon(
      canvas: canvas,
      center: center,
      radius: hexRadius,
      fillColor: centerColor,
      strokeColor: Colors.white,
      strokeWidth: 2.2,
    );

    _drawText(
      canvas: canvas,
      center: Offset(center.dx, center.dy - 6),
      text: '$centerScore',
      fontSize: 18,
      fontWeight: FontWeight.w900,
      color: Colors.white,
    );

    _drawText(
      canvas: canvas,
      center: Offset(center.dx, center.dy + 10),
      text: centerLabel,
      fontSize: 8,
      fontWeight: FontWeight.w800,
      color: Colors.white.withValues(alpha: 0.9),
    );
  }

  void _drawHexagon({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required Color fillColor,
    required Color strokeColor,
    required double strokeWidth,
  }) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (60.0 * i + 30.0) * math.pi / 180.0;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawPath(path, strokePaint);
  }

  void _drawText({
    required Canvas canvas,
    required Offset center,
    required String text,
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final textOffset = Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant _HexClusterPainter oldDelegate) {
    return oldDelegate.centerScore != centerScore ||
        oldDelegate.centerColor != centerColor ||
        oldDelegate.isDarkMode != isDarkMode;
  }
}
