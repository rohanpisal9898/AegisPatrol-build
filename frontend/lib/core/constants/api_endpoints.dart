class ApiEndpoints {
  // In Android emulator use 10.0.2.2, for iOS/Web/Desktop use 127.0.0.1 or your LAN IP.
  // We can provide a configurable or sensible default.
  static const String baseUrl = 'http://127.0.0.1:8000';

  // Civilian Auth
  static const String civilianSignup = '$baseUrl/auth/civilian/signup';
  static const String civilianLogin = '$baseUrl/auth/civilian/login';

  // Police Auth
  static const String policeSignup = '$baseUrl/auth/police/signup';
  static const String policeLogin = '$baseUrl/auth/police/login';

  // Profile & Session
  static const String me = '$baseUrl/auth/me';
  static const String logout = '$baseUrl/auth/logout';
}
