import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/config.dart';

class LocationService {
  static LocationService? _instance;
  LocationService._internal();

  factory LocationService() {
    _instance ??= LocationService._internal();
    return _instance!;
  }

  Position? _lastKnownPosition;

  Position? get lastKnownPosition => _lastKnownPosition;

  Future<bool> requestLocationPermission() async {
    final permission = await Permission.location.status;

    if (permission.isDenied) {
      final result = await Permission.location.request();
      return result.isGranted;
    }

    return permission.isGranted;
  }

  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<Position?> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration? timeLimit,
  }) async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check permissions
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        throw Exception('Location permissions denied');
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: timeLimit,
      );

      _lastKnownPosition = position;
      return position;
    } catch (e) {
      print('Error getting location: $e');
      return _lastKnownPosition;
    }
  }

  Future<Position?> getLastKnownPosition() async {
    try {
      _lastKnownPosition = await Geolocator.getLastKnownPosition();
      return _lastKnownPosition;
    } catch (e) {
      print('Error getting last known position: $e');
      return null;
    }
  }

  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) {
    final locationSettings = LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings).map(
      (position) {
        _lastKnownPosition = position;
        return position;
      },
    );
  }

  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  double calculateDistanceFromCurrentLocation(
    double latitude,
    double longitude,
  ) {
    if (_lastKnownPosition == null) {
      return double.infinity;
    }

    return calculateDistance(
      _lastKnownPosition!.latitude,
      _lastKnownPosition!.longitude,
      latitude,
      longitude,
    );
  }

  bool isWithinRadius(double latitude, double longitude, double radiusInMiles) {
    final distance = calculateDistanceFromCurrentLocation(latitude, longitude);
    return distance <= (radiusInMiles * 1609.34); // Convert miles to meters
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}
