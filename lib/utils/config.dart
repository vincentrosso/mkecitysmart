class ApiConfig {
  static const String baseUrl = 'https://api.citysmart-milwaukee.com/v1';
  static const String mapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  static const String firebaseApiKey = 'YOUR_FIREBASE_API_KEY';
  static const int timeoutSeconds = 30;

  // Mock data endpoints for development
  static const bool useMockData = true;

  // Milwaukee-specific coordinates
  static const double milwaukeeLatitude = 43.0389;
  static const double milwaukeeLongitude = -87.9065;
  static const double defaultSearchRadius = 1.0; // miles
}

class ApiEndpoints {
  // Authentication
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/profile';

  // Parking
  static const String parkingSearch = '/parking/search';
  static const String parkingSpot = '/parking/spot';
  static const String parkingReserve = '/parking/reserve';
  static const String parkingHistory = '/parking/history';
  static const String parkingPayment = '/parking/payment';

  // Permits
  static const String permits = '/permits';
  static const String permitRenew = '/permits/renew';
  static const String permitQr = '/permits/qr';
  static const String permitHistory = '/permits/history';

  // Street Sweeping
  static const String streetSweepingSchedule = '/street-sweeping/schedule';
  static const String streetSweepingAlert = '/street-sweeping/alert';
  static const String streetSweepingViolations = '/street-sweeping/violations';
}

class PreferenceKeys {
  static const String userToken = 'user_token';
  static const String refreshToken = 'refresh_token';
  static const String lastKnownLocation = 'last_known_location';
  static const String notificationSettings = 'notification_settings';
  static const String mapSettings = 'map_settings';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String userProfile = 'user_profile';
  static const String cachedParkingSpots = 'cached_parking_spots';
}
