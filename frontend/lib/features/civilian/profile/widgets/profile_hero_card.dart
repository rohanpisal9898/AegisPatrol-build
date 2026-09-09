import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'city_skyline_painter.dart';
import 'female_avatar.dart';

/// Large rounded hero card matching the reference Profile screen
class ProfileHeroCard extends StatelessWidget {
  final String name;
  final String role;
  final String motto;

  const ProfileHeroCard({
    super.key,
    this.name = 'Ananya Sharma',
    this.role = 'Civilian',
    this.motto = 'Stay Safe, Always',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4EC), // Very light pink background
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFF8BBD0),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Soft decorative city skyline illustration at the bottom
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 70,
              child: CustomPaint(
                painter: CitySkylinePainter(
                  skylineColor: Color(0xFFF48FB1),
                ),
              ),
            ),

            // Card content: Avatar + User Details
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 26),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Circular female avatar with white border
                  const FemaleAvatar(size: 78),

                  const SizedBox(width: 16),

                  // Name, Status Badge, Subtext
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Prominent User Name
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

                        // Green Status Badge / Pill: [person icon] Civilian
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCE4EC), // Light pink pill background
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.person_rounded,
                                size: 14,
                                color: Color(0xFFE91E63),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                role,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFE91E63),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Subtitle: Stay Safe, Always
                        Text(
                          motto,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
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
