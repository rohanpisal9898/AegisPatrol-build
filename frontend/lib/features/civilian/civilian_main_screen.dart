import 'package:flutter/material.dart';
import 'home/civilian_home_screen.dart';
import 'journeys/civilian_journeys_screen.dart';
import 'profile/civilian_profile_screen.dart';

class CivilianMainScreen extends StatefulWidget {
  final int initialIndex;

  const CivilianMainScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<CivilianMainScreen> createState() => _CivilianMainScreenState();
}

class _CivilianMainScreenState extends State<CivilianMainScreen> {
  late int _currentIndex;

  late final List<Widget> _screens = [
    const CivilianHomeScreen(),
    CivilianJourneysScreen(key: civilianJourneysKey),
    const CivilianProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

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
            top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
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
              if (index == 1) {
                civilianJourneysKey.currentState?.loadJourneys();
              }
            },
            backgroundColor: Colors.white,
            elevation: 0,
            selectedItemColor: const Color(0xFFE91E63), // Civilian pink
            unselectedItemColor: const Color(0xFF64748B), // Slate gray inactive
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: Color(0xFFE91E63),
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.offline_bolt_outlined),
                activeIcon: Icon(Icons.offline_bolt_rounded),
                label: 'Journeys',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
