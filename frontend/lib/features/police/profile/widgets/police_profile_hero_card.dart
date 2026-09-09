import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'police_officer_avatar.dart';
import 'police_station_painter.dart';

/// Large rounded hero card matching the reference Police Profile screen
class PoliceProfileHeroCard extends StatelessWidget {
  final String name;
  final String role;
  final String motto;

  const PoliceProfileHeroCard({
    super.key,
    this.name = 'Rajesh Patil',
    this.role = 'Police Officer',
    this.motto = 'Serve • Protect • Support',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // Soft light-blue background
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFBFDBFE), // Soft blue border
          width: 1.2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Subtle decorative police station illustration on the right
            const Positioned(
              right: 2,
              top: 4,
              bottom: 4,
              width: 175,
              child: CustomPaint(
                painter: PoliceStationPainter(
                  tintColor: Color(0xFF93C5FD), // Soft blue tint
                ),
              ),
            ),

            // Card content: Avatar + Officer Details
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 26),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Circular police officer avatar with white border
                  const PoliceOfficerAvatar(size: 78),

                  const SizedBox(width: 16),

                  // Name, Status Badge, Motto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Prominent Officer Name
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Blue Status Badge / Pill: [shield icon] Police Officer
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE), // Light blue pill background
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.shield_rounded,
                                size: 14,
                                color: AppColors.policePrimary, // Police green
                              ),
                              const SizedBox(width: 4),
                              Text(
                                role,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.policePrimary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Subtitle: Serve • Protect • Support
                        Text(
                          motto,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF475569), // Muted dark slate
                          ),
                        ),
                      ],
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
}
