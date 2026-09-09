import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../role_selection/role_selection_screen.dart';
import 'widgets/profile_hero_card.dart';
import 'widgets/personal_info_card.dart';

/// Portrait Mobile-First Civilian Profile Screen matching reference screenshot
class CivilianProfileScreen extends StatelessWidget {
  const CivilianProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Confirm Logout',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'Are you sure you want to log out of AegisPatrol?',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(100, 42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Log Out',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    // Use current user data if available; fallback to exact reference values
    final fullName = (user?.name != null && user!.name.trim().isNotEmpty)
        ? user.name
        : 'Ananya Sharma';

    final phoneNumber = (user?.phone != null && user!.phone!.trim().isNotEmpty)
        ? user.phone!
        : '+91 98765 43210';

    final district = (user?.district != null && user!.district.trim().isNotEmpty)
        ? (user.district.contains(',') ? user.district : '${user.district}, Maharashtra')
        : 'Mumbai Suburban, Maharashtra';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light neutral background
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              children: [
                // Centered "Profile" Title Header matching reference
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Center(
                    child: Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A), // Dark slate title
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),

                // Main Content Scrollable View
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    child: Column(
                      children: [
                        // Profile Hero Card (Mint, Avatar, Name, Badge, Skyline)
                        ProfileHeroCard(
                          name: fullName,
                          role: 'Civilian',
                          motto: 'Stay Safe, Always',
                        ),

                        const SizedBox(height: 16),

                        // Personal Information Card (3 rows with mint icons)
                        PersonalInfoCard(
                          fullName: fullName,
                          phoneNumber: phoneNumber,
                          district: district,
                        ),

                        const SizedBox(height: 20),

                        // Full-width Logout Button
                        _buildLogoutButton(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Material(
      color: const Color(0xFFFCE4EC), // Soft pink background
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _handleLogout(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout_rounded,
                color: Color(0xFFE91E63), // Pink logout icon
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Logout',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE91E63), // Pink bold text
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
