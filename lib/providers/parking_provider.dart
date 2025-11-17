import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/parking_spot.dart';
import '../models/parking_reservation.dart';
import '../services/parking_service.dart';
import '../services/storage_service.dart';
import '../models/street_sweeping.dart';

class ParkingProvider extends ChangeNotifier {
  final ParkingService _parkingService = ParkingService();

  List<ParkingSpot> _parkingSpots = [];
  List<ParkingReservation> _reservations = [];
  List<ParkingReservation> _history = [];
  ParkingSpot? _selectedSpot;
  bool _isLoading = false;
  String? _errorMessage;

  List<ParkingSpot> get parkingSpots => _parkingSpots;
  List<ParkingReservation> get reservations => _reservations;
  List<ParkingReservation> get history => _history;
  ParkingSpot? get selectedSpot => _selectedSpot;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> searchParkingSpots({
    required double latitude,
    required double longitude,
    double radius = 1.0,
    SpotType? spotType,
    double? maxHourlyRate,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Try to load from cache first if no filters are applied
      if (spotType == null && maxHourlyRate == null) {
        final cachedSpots = await StorageService.getCachedParkingSpots();
        if (cachedSpots != null) {
          _parkingSpots = cachedSpots;
          _setLoading(false);
          notifyListeners();

          // Load fresh data in background
          _searchFreshParkingSpots(
            latitude: latitude,
            longitude: longitude,
            radius: radius,
            spotType: spotType,
            maxHourlyRate: maxHourlyRate,
          );
          return;
        }
      }

      // Load fresh data
      await _searchFreshParkingSpots(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        spotType: spotType,
        maxHourlyRate: maxHourlyRate,
      );
    } catch (e) {
      _setError('Error searching parking spots: ${e.toString()}');
      _setLoading(false);
    }
  }

  Future<void> _searchFreshParkingSpots({
    required double latitude,
    required double longitude,
    double radius = 1.0,
    SpotType? spotType,
    double? maxHourlyRate,
  }) async {
    try {
      _parkingSpots = await _parkingService.searchParkingSpots(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        spotType: spotType,
        maxHourlyRate: maxHourlyRate,
      );

      // Cache the results if no filters were applied
      if (spotType == null && maxHourlyRate == null) {
        await StorageService.cacheParkingSpots(_parkingSpots);
      }

      notifyListeners();
    } catch (e) {
      _setError('Error loading fresh parking data: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> selectParkingSpot(String spotId) async {
    _setLoading(true);
    _clearError();

    try {
      _selectedSpot = await _parkingService.getParkingSpotDetails(spotId);
      if (_selectedSpot == null) {
        _setError('Could not load spot details');
      }
    } catch (e) {
      _setError('Error loading spot details: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> reserveSpot({
    required String spotId,
    required String vehicleId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final reservation = await _parkingService.reserveParkingSpot(
        spotId: spotId,
        vehicleId: vehicleId,
        startTime: startTime,
        endTime: endTime,
      );

      if (reservation != null) {
        _reservations.add(reservation);
        return true;
      } else {
        _setError('Failed to reserve parking spot');
        return false;
      }
    } catch (e) {
      _setError('Error reserving spot: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> cancelReservation(String reservationId) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _parkingService.cancelReservation(reservationId);

      if (success) {
        _reservations.removeWhere((r) => r.id == reservationId);
        return true;
      } else {
        _setError('Failed to cancel reservation');
        return false;
      }
    } catch (e) {
      _setError('Error cancelling reservation: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadParkingHistory() async {
    _setLoading(true);
    _clearError();

    try {
      // Try to load from cache first
      final cachedReservations = await StorageService.getCachedReservations();
      if (cachedReservations != null) {
        _history = cachedReservations
            .where((r) => r.status == ReservationStatus.completed)
            .toList();
        _setLoading(false);
        notifyListeners();

        // Load fresh data in background
        _loadFreshHistory();
        return;
      }

      // Load fresh data if no cache
      await _loadFreshHistory();
    } catch (e) {
      _setError('Error loading parking history: ${e.toString()}');
      _setLoading(false);
    }
  }

  Future<void> _loadFreshHistory() async {
    try {
      _history = await _parkingService.getUserParkingHistory();

      // Cache the fresh data
      await StorageService.cacheReservations(_history);

      notifyListeners();
    } catch (e) {
      _setError('Error loading fresh history data: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  void clearSelectedSpot() {
    _selectedSpot = null;
    notifyListeners();
  }

  List<ParkingSpot> filterSpots({
    SpotType? type,
    double? maxRate,
    double? maxDistance,
  }) {
    return _parkingSpots.where((spot) {
      if (type != null && spot.type != type) return false;
      if (maxRate != null &&
          spot.hourlyRate != null &&
          spot.hourlyRate! > maxRate)
        return false;
      if (maxDistance != null && spot.distance > maxDistance) return false;
      return true;
    }).toList();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  List<StreetSweeping> getUpcomingStreetSweeping(
    double lat,
    double lng, {
    double radius = 1.0,
  }) {
    // Try to load from cache first
    _loadStreetSweepingFromCache(lat, lng, radius: radius);

    // Generate fresh mock street sweeping schedules for the area
    final now = DateTime.now();
    final mockSchedules = <StreetSweeping>[
      StreetSweeping(
        id: '1',
        streetName: 'Water Street',
        fromStreet: '1st Street',
        toStreet: '5th Street',
        side: SweepingSide.north,
        date: now.add(const Duration(days: 1)),
        startTime: DateTime(now.year, now.month, now.day + 1, 8, 0),
        endTime: DateTime(now.year, now.month, now.day + 1, 12, 0),
        latitude: 43.0389,
        longitude: -87.9065,
      ),
      StreetSweeping(
        id: '2',
        streetName: 'Wisconsin Avenue',
        fromStreet: '2nd Street',
        toStreet: '8th Street',
        side: SweepingSide.south,
        date: now.add(const Duration(days: 3)),
        startTime: DateTime(now.year, now.month, now.day + 3, 9, 0),
        endTime: DateTime(now.year, now.month, now.day + 3, 15, 0),
        latitude: 43.0395,
        longitude: -87.9070,
      ),
      StreetSweeping(
        id: '3',
        streetName: 'Brady Street',
        fromStreet: 'Humboldt Avenue',
        toStreet: 'Farwell Avenue',
        side: SweepingSide.both,
        date: now.add(const Duration(days: 5)),
        startTime: DateTime(now.year, now.month, now.day + 5, 7, 0),
        endTime: DateTime(now.year, now.month, now.day + 5, 11, 0),
        latitude: 43.0415,
        longitude: -87.9055,
      ),
      StreetSweeping(
        id: '4',
        streetName: 'North Avenue',
        fromStreet: 'Prospect Avenue',
        toStreet: 'Lake Drive',
        side: SweepingSide.east,
        date: now.add(const Duration(days: 7)),
        startTime: DateTime(now.year, now.month, now.day + 7, 8, 30),
        endTime: DateTime(now.year, now.month, now.day + 7, 13, 30),
        latitude: 43.0425,
        longitude: -87.9045,
      ),
    ];

    // Filter by proximity
    final filteredSchedules = mockSchedules.where((schedule) {
      final distance = _calculateDistance(
        lat,
        lng,
        schedule.latitude,
        schedule.longitude,
      );
      return distance <= radius;
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    // Cache the data
    StorageService.cacheStreetSweeping(filteredSchedules);

    return filteredSchedules;
  }

  Future<void> _loadStreetSweepingFromCache(
    double lat,
    double lng, {
    double radius = 1.0,
  }) async {
    final cachedSchedules = await StorageService.getCachedStreetSweeping();
    // This method exists for future expansion when we have real API integration
  }

  // Cache management methods
  Future<void> clearCache() async {
    await StorageService.clearCache();
    _parkingSpots = [];
    _reservations = [];
    _history = [];
    notifyListeners();
  }

  Future<Map<String, dynamic>> getCacheStatus() async {
    return await StorageService.getCacheStatus();
  }

  // Offline mode detection
  bool get hasOfflineData {
    return _parkingSpots.isNotEmpty || _history.isNotEmpty;
  }

  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    // Calculate distance using Geolocator (in meters)
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) /
        1609.34; // Convert to miles
  }
}
