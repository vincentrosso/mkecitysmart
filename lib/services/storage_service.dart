import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/parking_spot.dart';
import '../models/parking_reservation.dart';
import '../models/user.dart';
import '../models/permit.dart';
import '../models/street_sweeping.dart';

class StorageService {
  static const String _userKey = 'user_data';
  static const String _parkingSpotsKey = 'parking_spots_cache';
  static const String _reservationsKey = 'reservations_cache';
  static const String _permitsKey = 'permits_cache';
  static const String _streetSweepingKey = 'street_sweeping_cache';
  static const String _lastUpdateKey = 'last_update_timestamp';
  static const String _settingsKey = 'app_settings';

  // Cache duration in hours
  static const int cacheValidityHours = 6;

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // User data storage
  static Future<void> saveUser(User user) async {
    final prefs = await StorageService.prefs;
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  static Future<User?> getUser() async {
    final prefs = await StorageService.prefs;
    final userString = prefs.getString(_userKey);
    if (userString != null) {
      return User.fromJson(jsonDecode(userString));
    }
    return null;
  }

  static Future<void> clearUser() async {
    final prefs = await StorageService.prefs;
    await prefs.remove(_userKey);
  }

  // Parking spots caching
  static Future<void> cacheParkingSpots(List<ParkingSpot> spots) async {
    final prefs = await StorageService.prefs;
    final spotsJson = spots.map((spot) => spot.toJson()).toList();
    await prefs.setString(_parkingSpotsKey, jsonEncode(spotsJson));
    await _updateTimestamp();
  }

  static Future<List<ParkingSpot>?> getCachedParkingSpots() async {
    if (!await _isCacheValid()) return null;

    final prefs = await StorageService.prefs;
    final spotsString = prefs.getString(_parkingSpotsKey);
    if (spotsString != null) {
      final List<dynamic> spotsJson = jsonDecode(spotsString);
      return spotsJson.map((json) => ParkingSpot.fromJson(json)).toList();
    }
    return null;
  }

  // Reservations caching
  static Future<void> cacheReservations(
    List<ParkingReservation> reservations,
  ) async {
    final prefs = await StorageService.prefs;
    final reservationsJson = reservations.map((r) => r.toJson()).toList();
    await prefs.setString(_reservationsKey, jsonEncode(reservationsJson));
  }

  static Future<List<ParkingReservation>?> getCachedReservations() async {
    if (!await _isCacheValid()) return null;

    final prefs = await StorageService.prefs;
    final reservationsString = prefs.getString(_reservationsKey);
    if (reservationsString != null) {
      final List<dynamic> reservationsJson = jsonDecode(reservationsString);
      return reservationsJson
          .map((json) => ParkingReservation.fromJson(json))
          .toList();
    }
    return null;
  }

  // Permits caching
  static Future<void> cachePermits(List<Permit> permits) async {
    final prefs = await StorageService.prefs;
    final permitsJson = permits.map((permit) => permit.toJson()).toList();
    await prefs.setString(_permitsKey, jsonEncode(permitsJson));
  }

  static Future<List<Permit>?> getCachedPermits() async {
    final prefs = await StorageService.prefs;
    final permitsString = prefs.getString(_permitsKey);
    if (permitsString != null) {
      final List<dynamic> permitsJson = jsonDecode(permitsString);
      return permitsJson.map((json) => Permit.fromJson(json)).toList();
    }
    return null;
  }

  // Street sweeping caching
  static Future<void> cacheStreetSweeping(
    List<StreetSweeping> schedules,
  ) async {
    final prefs = await StorageService.prefs;
    final schedulesJson = schedules.map((s) => s.toJson()).toList();
    await prefs.setString(_streetSweepingKey, jsonEncode(schedulesJson));
  }

  static Future<List<StreetSweeping>?> getCachedStreetSweeping() async {
    if (!await _isCacheValid()) return null;

    final prefs = await StorageService.prefs;
    final schedulesString = prefs.getString(_streetSweepingKey);
    if (schedulesString != null) {
      final List<dynamic> schedulesJson = jsonDecode(schedulesString);
      return schedulesJson
          .map((json) => StreetSweeping.fromJson(json))
          .toList();
    }
    return null;
  }

  // App settings
  static Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    final prefs = await StorageService.prefs;
    await prefs.setString(_settingsKey, jsonEncode(settings));
  }

  static Future<Map<String, dynamic>?> getAppSettings() async {
    final prefs = await StorageService.prefs;
    final settingsString = prefs.getString(_settingsKey);
    if (settingsString != null) {
      return Map<String, dynamic>.from(jsonDecode(settingsString));
    }
    return null;
  }

  // Notification settings
  static Future<void> setNotificationEnabled(String type, bool enabled) async {
    final settings = await getAppSettings() ?? <String, dynamic>{};
    settings['notifications_$type'] = enabled;
    await saveAppSettings(settings);
  }

  static Future<bool> isNotificationEnabled(String type) async {
    final settings = await getAppSettings();
    return settings?['notifications_$type'] ?? true; // Default to enabled
  }

  // Location settings
  static Future<void> saveLastKnownLocation(
    double latitude,
    double longitude,
  ) async {
    final settings = await getAppSettings() ?? <String, dynamic>{};
    settings['last_latitude'] = latitude;
    settings['last_longitude'] = longitude;
    settings['last_location_update'] = DateTime.now().millisecondsSinceEpoch;
    await saveAppSettings(settings);
  }

  static Future<Map<String, double>?> getLastKnownLocation() async {
    final settings = await getAppSettings();
    if (settings != null &&
        settings.containsKey('last_latitude') &&
        settings.containsKey('last_longitude')) {
      return {
        'latitude': settings['last_latitude'],
        'longitude': settings['last_longitude'],
      };
    }
    return null;
  }

  // Search history
  static Future<void> addSearchHistory(String searchQuery) async {
    final prefs = await StorageService.prefs;
    final history = prefs.getStringList('search_history') ?? [];

    // Remove if already exists to avoid duplicates
    history.remove(searchQuery);

    // Add to beginning
    history.insert(0, searchQuery);

    // Keep only last 10 searches
    if (history.length > 10) {
      history.removeLast();
    }

    await prefs.setStringList('search_history', history);
  }

  static Future<List<String>> getSearchHistory() async {
    final prefs = await StorageService.prefs;
    return prefs.getStringList('search_history') ?? [];
  }

  static Future<void> clearSearchHistory() async {
    final prefs = await StorageService.prefs;
    await prefs.remove('search_history');
  }

  // Favorites
  static Future<void> addFavoriteSpot(String spotId) async {
    final prefs = await StorageService.prefs;
    final favorites = prefs.getStringList('favorite_spots') ?? [];
    if (!favorites.contains(spotId)) {
      favorites.add(spotId);
      await prefs.setStringList('favorite_spots', favorites);
    }
  }

  static Future<void> removeFavoriteSpot(String spotId) async {
    final prefs = await StorageService.prefs;
    final favorites = prefs.getStringList('favorite_spots') ?? [];
    favorites.remove(spotId);
    await prefs.setStringList('favorite_spots', favorites);
  }

  static Future<List<String>> getFavoriteSpots() async {
    final prefs = await StorageService.prefs;
    return prefs.getStringList('favorite_spots') ?? [];
  }

  static Future<bool> isFavoriteSpot(String spotId) async {
    final favorites = await getFavoriteSpots();
    return favorites.contains(spotId);
  }

  // Cache management
  static Future<void> _updateTimestamp() async {
    final prefs = await StorageService.prefs;
    await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<bool> _isCacheValid() async {
    final prefs = await StorageService.prefs;
    final lastUpdate = prefs.getInt(_lastUpdateKey);
    if (lastUpdate == null) return false;

    final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
    final now = DateTime.now();
    final difference = now.difference(lastUpdateTime);

    return difference.inHours < cacheValidityHours;
  }

  static Future<void> clearCache() async {
    final prefs = await StorageService.prefs;
    await prefs.remove(_parkingSpotsKey);
    await prefs.remove(_reservationsKey);
    await prefs.remove(_streetSweepingKey);
    await prefs.remove(_lastUpdateKey);
  }

  static Future<void> clearAllData() async {
    final prefs = await StorageService.prefs;
    await prefs.clear();
  }

  // Cache status
  static Future<Map<String, dynamic>> getCacheStatus() async {
    final prefs = await StorageService.prefs;
    final lastUpdate = prefs.getInt(_lastUpdateKey);
    final isValid = await _isCacheValid();

    return {
      'isValid': isValid,
      'lastUpdate': lastUpdate != null
          ? DateTime.fromMillisecondsSinceEpoch(lastUpdate)
          : null,
      'hasParkingSpots': prefs.getString(_parkingSpotsKey) != null,
      'hasReservations': prefs.getString(_reservationsKey) != null,
      'hasPermits': prefs.getString(_permitsKey) != null,
      'hasStreetSweeping': prefs.getString(_streetSweepingKey) != null,
      'hasUser': prefs.getString(_userKey) != null,
    };
  }
}
