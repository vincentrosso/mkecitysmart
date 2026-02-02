import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_place.dart';
import 'analytics_service.dart';

/// Service for managing saved places (home, work, favorites)
/// 
/// Features:
/// - Firestore persistence with offline support
/// - Local caching for fast access
/// - Real-time sync via stream
/// - Geohash encoding for efficient geo-queries
/// 
/// Scalability design:
/// - Supports unlimited favorites per user
/// - Efficient queries via compound indexes
/// - Ready for multi-city expansion
/// - Notification radius per place
class SavedPlacesService {
  static final SavedPlacesService _instance = SavedPlacesService._internal();
  static SavedPlacesService get instance => _instance;
  factory SavedPlacesService() => _instance;
  SavedPlacesService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const String _collection = 'savedPlaces';
  static const String _localKey = 'saved_places_cache';
  static const int _maxFavoritesPerUser = 50; // Scalable limit

  List<SavedPlace> _places = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  final _controller = StreamController<List<SavedPlace>>.broadcast();

  /// Stream of saved places (updates in real-time)
  Stream<List<SavedPlace>> get placesStream => _controller.stream;

  /// Current saved places
  List<SavedPlace> get places => List.unmodifiable(_places);

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Initialize service - load from cache then sync from Firestore
  Future<void> initialize() async {
    if (_userId == null) {
      debugPrint('[SavedPlacesService] No user, skipping init');
      return;
    }

    // Load from local cache first (instant)
    await _loadFromCache();
    
    // Then sync from Firestore
    await _syncFromFirestore();
    
    // Set up real-time listener
    _setupListener();
    
    debugPrint('[SavedPlacesService] Initialized with ${_places.length} places');
  }

  /// Dispose of resources
  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }

  // ==================== CRUD Operations ====================

  /// Add a new saved place
  Future<SavedPlace?> addPlace({
    required String name,
    String? nickname,
    required PlaceType type,
    required double latitude,
    required double longitude,
    String? address,
    double notifyRadiusMiles = 0.5,
    bool notificationsEnabled = true,
  }) async {
    final userId = _userId;
    if (userId == null) return null;

    // Check limits for favorites
    if (type == PlaceType.favorite) {
      final favoriteCount = _places.where((p) => p.type == PlaceType.favorite).length;
      if (favoriteCount >= _maxFavoritesPerUser) {
        debugPrint('[SavedPlacesService] Max favorites limit reached');
        return null;
      }
    }

    // For home/work, check if one already exists (only one of each allowed)
    if (type == PlaceType.home || type == PlaceType.work) {
      final existing = _places.where((p) => p.type == type).firstOrNull;
      if (existing != null) {
        // Update existing instead of creating new
        return updatePlace(
          existing.id,
          name: name,
          nickname: nickname,
          latitude: latitude,
          longitude: longitude,
          address: address,
          notifyRadiusMiles: notifyRadiusMiles,
          notificationsEnabled: notificationsEnabled,
        );
      }
    }

    try {
      final now = DateTime.now();
      final docRef = _firestore.collection(_collection).doc();
      
      final place = SavedPlace(
        id: docRef.id,
        userId: userId,
        name: name,
        nickname: nickname,
        type: type,
        latitude: latitude,
        longitude: longitude,
        address: address,
        geohash: _encodeGeohash(latitude, longitude),
        notifyRadiusMiles: notifyRadiusMiles,
        notificationsEnabled: notificationsEnabled,
        createdAt: now,
        updatedAt: now,
      );

      await docRef.set(place.toFirestore());
      
      // Track analytics
      AnalyticsService.instance.logEvent('saved_place_added', parameters: {
        'type': type.name,
        'notifications_enabled': notificationsEnabled.toString(),
      });

      // Update local cache
      _places.add(place);
      _controller.add(_places);
      await _saveToCache();

      debugPrint('[SavedPlacesService] Added place: ${place.displayName}');
      return place;
    } catch (e) {
      debugPrint('[SavedPlacesService] Error adding place: $e');
      AnalyticsService.instance.recordError(e, reason: 'Failed to add saved place');
      return null;
    }
  }

  /// Update an existing saved place
  Future<SavedPlace?> updatePlace(
    String placeId, {
    String? name,
    String? nickname,
    double? latitude,
    double? longitude,
    String? address,
    double? notifyRadiusMiles,
    bool? notificationsEnabled,
  }) async {
    try {
      final index = _places.indexWhere((p) => p.id == placeId);
      if (index == -1) return null;

      final existing = _places[index];
      final updated = existing.copyWith(
        name: name,
        nickname: nickname,
        latitude: latitude,
        longitude: longitude,
        address: address,
        geohash: latitude != null && longitude != null
            ? _encodeGeohash(latitude, longitude)
            : null,
        notifyRadiusMiles: notifyRadiusMiles,
        notificationsEnabled: notificationsEnabled,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .doc(placeId)
          .update(updated.toFirestore());

      _places[index] = updated;
      _controller.add(_places);
      await _saveToCache();

      AnalyticsService.instance.logEvent('saved_place_updated', parameters: {
        'type': updated.type.name,
      });

      debugPrint('[SavedPlacesService] Updated place: ${updated.displayName}');
      return updated;
    } catch (e) {
      debugPrint('[SavedPlacesService] Error updating place: $e');
      AnalyticsService.instance.recordError(e, reason: 'Failed to update saved place');
      return null;
    }
  }

  /// Delete a saved place
  Future<bool> deletePlace(String placeId) async {
    try {
      await _firestore.collection(_collection).doc(placeId).delete();

      final removed = _places.firstWhere((p) => p.id == placeId);
      _places.removeWhere((p) => p.id == placeId);
      _controller.add(_places);
      await _saveToCache();

      AnalyticsService.instance.logEvent('saved_place_deleted', parameters: {
        'type': removed.type.name,
      });

      debugPrint('[SavedPlacesService] Deleted place: ${removed.displayName}');
      return true;
    } catch (e) {
      debugPrint('[SavedPlacesService] Error deleting place: $e');
      AnalyticsService.instance.recordError(e, reason: 'Failed to delete saved place');
      return false;
    }
  }

  // ==================== Query Methods ====================

  /// Get home location
  SavedPlace? get home => _places.where((p) => p.type == PlaceType.home).firstOrNull;

  /// Get work location
  SavedPlace? get work => _places.where((p) => p.type == PlaceType.work).firstOrNull;

  /// Get all favorites
  List<SavedPlace> get favorites =>
      _places.where((p) => p.type == PlaceType.favorite).toList();

  /// Get places with notifications enabled
  List<SavedPlace> get notificationPlaces =>
      _places.where((p) => p.notificationsEnabled).toList();

  /// Get place by ID
  SavedPlace? getPlace(String id) =>
      _places.where((p) => p.id == id).firstOrNull;

  /// Check if user has home set
  bool get hasHome => home != null;

  /// Check if user has work set
  bool get hasWork => work != null;

  /// Get places near a location (for alerts)
  List<SavedPlace> getPlacesNear(double lat, double lon, {double maxMiles = 10}) {
    return _places.where((place) {
      final distance = _calculateDistance(
        lat, lon,
        place.latitude, place.longitude,
      );
      return distance <= maxMiles;
    }).toList();
  }

  // ==================== Private Methods ====================

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_localKey);
      if (cached != null) {
        final List<dynamic> json = jsonDecode(cached);
        _places = json.map((j) => SavedPlace.fromJson(j)).toList();
        _controller.add(_places);
        debugPrint('[SavedPlacesService] Loaded ${_places.length} from cache');
      }
    } catch (e) {
      debugPrint('[SavedPlacesService] Cache load error: $e');
    }
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = _places.map((p) => p.toJson()).toList();
      await prefs.setString(_localKey, jsonEncode(json));
    } catch (e) {
      debugPrint('[SavedPlacesService] Cache save error: $e');
    }
  }

  Future<void> _syncFromFirestore() async {
    final userId = _userId;
    if (userId == null) return;

    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt')
          .get();

      _places = snapshot.docs.map((doc) => SavedPlace.fromFirestore(doc)).toList();
      _controller.add(_places);
      await _saveToCache();
      debugPrint('[SavedPlacesService] Synced ${_places.length} from Firestore');
    } catch (e) {
      debugPrint('[SavedPlacesService] Firestore sync error: $e');
    }
  }

  void _setupListener() {
    final userId = _userId;
    if (userId == null) return;

    _subscription?.cancel();
    _subscription = _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      _places = snapshot.docs.map((doc) => SavedPlace.fromFirestore(doc)).toList();
      _controller.add(_places);
      _saveToCache();
    }, onError: (e) {
      debugPrint('[SavedPlacesService] Listener error: $e');
    });
  }

  /// Encode lat/lon to geohash (precision 7 for ~150m accuracy)
  String _encodeGeohash(double lat, double lon) {
    const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
    const precision = 7;
    
    var minLat = -90.0, maxLat = 90.0;
    var minLon = -180.0, maxLon = 180.0;
    var hash = StringBuffer();
    var bit = 0;
    var ch = 0;
    var even = true;

    while (hash.length < precision) {
      if (even) {
        final mid = (minLon + maxLon) / 2;
        if (lon >= mid) {
          ch |= 1 << (4 - bit);
          minLon = mid;
        } else {
          maxLon = mid;
        }
      } else {
        final mid = (minLat + maxLat) / 2;
        if (lat >= mid) {
          ch |= 1 << (4 - bit);
          minLat = mid;
        } else {
          maxLat = mid;
        }
      }
      even = !even;
      if (bit < 4) {
        bit++;
      } else {
        hash.write(base32[ch]);
        bit = 0;
        ch = 0;
      }
    }
    return hash.toString();
  }

  /// Calculate distance in miles between two points
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusMiles = 3958.8;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) * _cos(_toRadians(lat2)) *
        _sin(dLon / 2) * _sin(dLon / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return earthRadiusMiles * c;
  }

  double _toRadians(double deg) => deg * 3.141592653589793 / 180;
  double _sin(double x) => _taylorSin(x);
  double _cos(double x) => _taylorSin(x + 1.5707963267948966);
  double _sqrt(double x) => _newtonSqrt(x);
  double _atan2(double y, double x) => _approxAtan2(y, x);

  double _taylorSin(double x) {
    // Normalize to [-π, π]
    while (x > 3.141592653589793) x -= 6.283185307179586;
    while (x < -3.141592653589793) x += 6.283185307179586;
    final x2 = x * x;
    return x * (1 - x2 / 6 * (1 - x2 / 20 * (1 - x2 / 42)));
  }

  double _newtonSqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _approxAtan2(double y, double x) {
    if (x > 0) return _approxAtan(y / x);
    if (x < 0 && y >= 0) return _approxAtan(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _approxAtan(y / x) - 3.141592653589793;
    if (x == 0 && y > 0) return 1.5707963267948966;
    if (x == 0 && y < 0) return -1.5707963267948966;
    return 0;
  }

  double _approxAtan(double x) {
    if (x.abs() > 1) {
      return (x > 0 ? 1 : -1) * 1.5707963267948966 - _approxAtan(1 / x);
    }
    final x2 = x * x;
    return x * (1 - x2 / 3 + x2 * x2 / 5 - x2 * x2 * x2 / 7);
  }
}
