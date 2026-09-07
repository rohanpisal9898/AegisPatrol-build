import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'home/civilian_home_screen.dart';
import 'journeys/civilian_journeys_screen.dart';
import 'profile/civilian_profile_screen.dart';

class CivilianMainScreen extends StatefulWidget {
  const CivilianMainScreen({super.key});

  @override
  State<CivilianMainScreen> createState() => _CivilianMainScreenState();
}

class _CivilianMainScreenState extends State<CivilianMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const CivilianHomeScreen(),
    CivilianJourneysScreen(key: civilianJourneysKey),
    const CivilianProfileScreen(),
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
            if (index == 1) {
              civilianJourneysKey.currentState?.loadJourneys();
            }
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
              icon: Icon(Icons.route_outlined),
              activeIcon: Icon(Icons.route_rounded),
              label: 'Journeys',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
