import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'home/police_home_screen.dart';
import 'assignments/police_assignments_screen.dart';
import 'journeys/police_journeys_screen.dart';
import 'profile/police_profile_screen.dart';

class PoliceMainScreen extends StatefulWidget {
  const PoliceMainScreen({super.key});

  @override
  State<PoliceMainScreen> createState() => _PoliceMainScreenState();
}

class _PoliceMainScreenState extends State<PoliceMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    PoliceHomeScreen(),
    PoliceAssignmentsScreen(),
    PoliceJourneysScreen(),
    PoliceProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
          },
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment_rounded),
              label: 'Assignments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.navigation_outlined),
              activeIcon: Icon(Icons.navigation_rounded),
              label: 'Journeys',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.badge_outlined),
              activeIcon: Icon(Icons.badge_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
