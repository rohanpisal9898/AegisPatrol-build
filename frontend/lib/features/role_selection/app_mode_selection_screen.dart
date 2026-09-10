import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../providers/auth_provider.dart';
import '../civilian/civilian_main_screen.dart';
import '../police/police_main_screen.dart';

class AppModeSelectionScreen extends StatelessWidget {
  const AppModeSelectionScreen({super.key});

  Future<void> _selectMode(BuildContext context, String mode) async {
    await SecureStorageService.saveAppMode(mode);
    if (!context.mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final targetRole = (mode == 'patrol') ? 'police' : 'civilian';
    await auth.ensureRoleSession(targetRole);

    if (!context.mounted) return;

    if (mode == 'patrol') {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PoliceMainScreen()),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CivilianMainScreen()),
        (route) => false,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071A2E), // Deep navy command center background
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),

                  // Header Badge & Shield
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E263D),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF147DF5).withValues(alpha: 0.3), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF147DF5).withValues(alpha: 0.25),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.shield_rounded,
                        size: 44,
                        color: Color(0xFF20C7E8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Product Title
                  const Text(
                    'NIRBHAY • GUARDIAN',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Safer Cities. Stronger Communities.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Question Title Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E263D),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF1E3A5F)),
                    ),
                    child: const Text(
                      'How are you using the app?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFCBD5E1),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Option 1: POLICE PATROL (Recommended & Prominent)
                  _ModeChoiceCard(
                    title: 'POLICE PATROL',
                    subtitle: 'For authorized patrol and operational intelligence',
                    badge: 'COMMAND CENTER',
                    badgeColor: const Color(0xFF20C7E8),
                    badgeBg: const Color(0xFF0B3356),
                    icon: Icons.local_police_rounded,
                    iconColor: const Color(0xFF20C7E8),
                    iconBg: const Color(0xFF0E2E4E),
                    borderColor: const Color(0xFF147DF5),
                    backgroundColor: const Color(0xFF0A223B),
                    onTap: () => _selectMode(context, 'patrol'),
                  ),

                  const SizedBox(height: 16),

                  // Option 2: CITIZEN
                  _ModeChoiceCard(
                    title: 'CITIZEN',
                    subtitle: 'For public safety, journeys and existing citizen features',
                    badge: 'PUBLIC ACCESS',
                    badgeColor: const Color(0xFF10B981),
                    badgeBg: const Color(0xFF063327),
                    icon: Icons.person_pin_circle_rounded,
                    iconColor: const Color(0xFF10B981),
                    iconBg: const Color(0xFF0A2E24),
                    borderColor: const Color(0xFF1E3A5F),
                    backgroundColor: const Color(0xFF091F35),
                    onTap: () => _selectMode(context, 'citizen'),
                  ),

                  const SizedBox(height: 28),

                  // Security / Regulatory Note
                  const Text(
                    'Operational public safety system • Mumbai Police PS ID: R1-06\nYou can switch modes anytime in Settings.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeChoiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final Color badgeBg;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color borderColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _ModeChoiceCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.badgeBg,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.borderColor,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor.withValues(alpha: 0.4)),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15.0,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: badgeColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFF64748B),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
