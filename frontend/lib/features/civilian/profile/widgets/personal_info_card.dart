import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Personal Information card with exactly three rows matching reference
class PersonalInfoCard extends StatelessWidget {
  final String fullName;
  final String phoneNumber;
  final String district;

  const PersonalInfoCard({
    super.key,
    this.fullName = 'Ananya Sharma',
    this.phoneNumber = '+91 98765 43210',
    this.district = 'Mumbai Suburban, Maharashtra',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Heading
          const Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 18),

          // Row 1: Full Name
          _buildInfoRow(
            icon: Icons.person_rounded,
            label: 'Full Name',
            value: fullName,
          ),

          const Divider(
            height: 26,
            thickness: 1,
            color: Color(0xFFF1F5F9),
          ),

          // Row 2: Phone Number
          _buildInfoRow(
            icon: Icons.phone_rounded,
            label: 'Phone Number',
            value: phoneNumber,
          ),

          const Divider(
            height: 26,
            thickness: 1,
            color: Color(0xFFF1F5F9),
          ),

          // Row 3: District
          _buildInfoRow(
            icon: Icons.location_on_rounded,
            label: 'District',
            value: district,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        // Rounded-square mint icon container
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F7EE), // Soft mint icon background
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 22,
            color: const Color(0xFF0D7A48), // Deep safety emerald
          ),
        ),

        const SizedBox(width: 14),

        // Text Column: Muted label above prominent value
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
