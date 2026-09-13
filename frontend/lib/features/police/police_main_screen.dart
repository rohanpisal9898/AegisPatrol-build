import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/patrol_intelligence_provider.dart';
import 'home/police_home_screen.dart';
import 'assignments/police_assignments_screen.dart';
import 'alerts/police_alerts_screen.dart';
import 'journeys/police_journeys_screen.dart';
import 'profile/police_profile_screen.dart';

class PoliceMainScreen extends StatefulWidget {
  final int initialIndex;

  const PoliceMainScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<PoliceMainScreen> createState() => _PoliceMainScreenState();
}

class _PoliceMainScreenState extends State<PoliceMainScreen> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    PoliceHomeScreen(),
    PoliceAssignmentsScreen(),
    PoliceAlertsScreen(),
    PoliceJourneysScreen(),
    PoliceProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PatrolIntelligenceProvider>(context);
    final isDarkMode = provider.isDarkMode;

    final barBg = isDarkMode ? const Color(0xFF071A2E) : Colors.white;
    final borderTop = isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFFF1F5F9);
    const selectedColor = Color(0xFF147DF5);
    final unselectedColor = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final activeAlertsCount = provider.alerts.where((a) => a.status == 'Active').length;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: barBg,
          border: Border(
            top: BorderSide(color: borderTop, width: 1.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() => _currentIndex = index);
            },
            backgroundColor: barBg,
            elevation: 0,
            selectedItemColor: selectedColor,
            unselectedItemColor: unselectedColor,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
              color: selectedColor,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 10,
              color: unselectedColor,
            ),
            type: BottomNavigationBarType.fixed,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.shield_outlined, size: 22),
                activeIcon: Icon(Icons.shield_rounded, size: 22),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.assignment_outlined, size: 22),
                activeIcon: Icon(Icons.assignment_rounded, size: 22),
                label: 'Tasks',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none_rounded, size: 22),
                    if (activeAlertsCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEA3F4F),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                activeIcon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_rounded, size: 22),
                    if (activeAlertsCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEA3F4F),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Alerts',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.directions_walk_rounded, size: 22),
                activeIcon: Icon(Icons.transfer_within_a_station_rounded, size: 22),
                label: 'Journeys',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded, size: 22),
                activeIcon: Icon(Icons.person_rounded, size: 22),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
