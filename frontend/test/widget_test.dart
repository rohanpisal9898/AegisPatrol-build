import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:aegispatrol/providers/auth_provider.dart';
import 'package:aegispatrol/features/role_selection/role_selection_screen.dart';
import 'package:aegispatrol/features/civilian/civilian_main_screen.dart';
import 'package:aegispatrol/features/police/police_main_screen.dart';
import 'package:aegispatrol/features/auth/civilian_auth/civilian_login_screen.dart';
import 'package:aegispatrol/features/auth/police_auth/police_login_screen.dart';

Widget createTestApp(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  testWidgets('RoleSelectionScreen renders Civilian and Police options', (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp(const RoleSelectionScreen()));

    expect(find.text('AEGISPATROL'), findsOneWidget);
    expect(find.text('Choose your role'), findsOneWidget);
    expect(find.text('CIVILIAN'), findsOneWidget);
    expect(find.text('POLICE'), findsOneWidget);
  });

  testWidgets('CivilianLoginScreen renders civilian login form', (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp(const CivilianLoginScreen()));

    expect(find.text('Welcome, Civilian'), findsOneWidget);
    expect(find.text('Phone Number'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });

  testWidgets('PoliceLoginScreen renders patrol unit login form', (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp(const PoliceLoginScreen()));

    expect(find.text('Welcome, Patrol Unit'), findsOneWidget);
    expect(find.text('Officer Phone Number'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Officer Log In'), findsOneWidget);
  });

  testWidgets('CivilianMainScreen renders exactly 3 navigation tabs: Home, Journeys, Profile', (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp(const CivilianMainScreen()));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Journeys'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Police Watch'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('SOS'), findsOneWidget);
    expect(find.text('Risk Map'), findsOneWidget);
    expect(find.text('Share Live'), findsOneWidget);
  });

  testWidgets('PoliceMainScreen renders exactly 4 navigation tabs: Home, Assignments, Journeys, Profile', (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp(const PoliceMainScreen()));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Assignments'), findsOneWidget);
    expect(find.text('Journeys'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Unit Home'), findsOneWidget);
    expect(find.text('Your Next Assignment'), findsOneWidget);
    expect(find.text('Go to Area'), findsOneWidget);
  });
}
