import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/journey_model.dart';

class RiskDetailsSheet extends StatelessWidget {
  final double riskScore;
  final RiskLevel riskLevel;
  final String message;

  const RiskDetailsSheet({
    super.key,
    required this.riskScore,
    required this.riskLevel,
    required this.message,
  });

  static Future<void> show(
    BuildContext context, {
    required double riskScore,
    required RiskLevel riskLevel,
    required String message,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RiskDetailsSheet(
        riskScore: riskScore,
        riskLevel: riskLevel,
        message: message,
      ),
    );
  }

  Color get _badgeColor {
    switch (riskLevel) {
      case RiskLevel.high:
        return AppColors.riskHigh;
      case RiskLevel.unusual:
        return const Color(0xFFF59E0B);
      case RiskLevel.normal:
        return AppColors.primary;
    }
  }

  Color get _badgeBgColor {
    switch (riskLevel) {
      case RiskLevel.high:
        return AppColors.riskHighBg;
      case RiskLevel.unusual:
        return const Color(0xFFFEF3C7);
      case RiskLevel.normal:
        return AppColors.primaryLight;
    }
  }

  String get _levelText {
    switch (riskLevel) {
      case RiskLevel.high:
        return 'High Risk';
      case RiskLevel.unusual:
        return 'Unusual Activity';
      case RiskLevel.normal:
        return 'Normal / Safe';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Safety Risk Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _badgeBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _levelText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Score Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _badgeBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      riskScore.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _badgeColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Risk Score Index',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${riskScore.toStringAsFixed(1)} / 10.0',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Assessment Note
          const Text(
            'Safety Assessment',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB), // Soft warm amber
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFFD97706)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message.isNotEmpty
                        ? message
                        : 'Elevated safety risk detected near your current route. Stay on well-lit main streets.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF92400E),
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to Journey Map', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
