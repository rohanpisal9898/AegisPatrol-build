class ApiEndpoints {
  // Production Render Backend URL (with override support via --dart-define=BACKEND_URL=...)
  static const String baseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://d-h-a-a-l.onrender.com',
  );

  // Civilian Auth
  static const String civilianSignup = '$baseUrl/auth/civilian/signup';
  static const String civilianLogin = '$baseUrl/auth/civilian/login';

  // Police Auth
  static const String policeSignup = '$baseUrl/auth/police/signup';
  static const String policeLogin = '$baseUrl/auth/police/login';

  // Profile & Session
  static const String me = '$baseUrl/auth/me';
  static const String logout = '$baseUrl/auth/logout';

  // Civilian Journeys
  static const String journeys = '$baseUrl/journeys';
  static const String startJourney = '$baseUrl/journeys/start';
  static String journeyLocation(String id) => '$baseUrl/journeys/$id/location';
  static String endJourney(String id) => '$baseUrl/journeys/$id/end';
  static String getJourney(String id) => '$baseUrl/journeys/$id';
  static String searchPlaces(String q, {double? lat, double? lon}) {
    var url = '$baseUrl/journeys/places/search?q=${Uri.encodeComponent(q)}';
    if (lat != null && lon != null) {
      url += '&lat=$lat&lon=$lon';
    }
    return url;
  }

  // Police Stations & Journeys
  static const String policeJourneys = '$baseUrl/police/journeys';
  static String nearbyPolice(double lat, double lon, {double radiusKm = 10.0}) =>
      '$baseUrl/police/nearby?lat=$lat&lon=$lon&radius_km=$radiusKm';

  // Safety & SOS Alerts
  static const String alerts = '$baseUrl/alerts';
  static String getAlert(String alertId) => '$baseUrl/alerts/$alertId';
  static String alertLocation(String alertId) => '$baseUrl/alerts/$alertId/location';
  static String resolveAlert(String alertId) => '$baseUrl/alerts/$alertId/resolve';
  static String markJourneySafe(String journeyId) => '$baseUrl/alerts/journey/$journeyId/safe';
}
