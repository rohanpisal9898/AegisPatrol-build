import 'package:flutter/material.dart';
import 'home/police_home_screen.dart';
import 'assignments/police_assignments_screen.dart';
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
            },
            backgroundColor: Colors.white,
            elevation: 0,
            selectedItemColor: const Color(0xFF0D7A48), // Police green theme
            unselectedItemColor: const Color(0xFF64748B), // Slate gray inactive
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: Color(0xFF0D7A48),
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
                icon: Icon(Icons.person_outline_rounded),
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
