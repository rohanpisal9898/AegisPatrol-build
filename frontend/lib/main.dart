import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'features/splash/splash_screen.dart';
import 'features/role_selection/role_selection_screen.dart';
import 'features/auth/civilian_auth/civilian_login_screen.dart';
import 'features/auth/civilian_auth/civilian_signup_screen.dart';
import 'features/auth/police_auth/police_login_screen.dart';
import 'features/auth/police_auth/police_signup_screen.dart';
import 'features/civilian/civilian_main_screen.dart';
import 'features/police/police_main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AegisPatrolApp());
}

class AegisPatrolApp extends StatelessWidget {
  const AegisPatrolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'AegisPatrol',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/role-selection': (context) => const RoleSelectionScreen(),
          '/civilian/auth': (context) => const CivilianLoginScreen(),
          '/civilian/signup': (context) => const CivilianSignupScreen(),
          '/civilian/home': (context) => const CivilianMainScreen(),
          '/police/auth': (context) => const PoliceLoginScreen(),
          '/police/signup': (context) => const PoliceSignupScreen(),
          '/police/home': (context) => const PoliceMainScreen(),
        },
      ),
    );
  }
}
