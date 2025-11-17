import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();

  Position? _currentPosition;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasPermission = false;

  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasPermission => _hasPermission;

  Future<void> initializeLocation() async {
    _setLoading(true);
    _clearError();

    try {
      // Request permissions
      _hasPermission = await _locationService.requestLocationPermission();

      if (!_hasPermission) {
        _setError('Location permission denied');
        return;
      }

      // Get current position
      _currentPosition = await _locationService.getCurrentPosition();

      if (_currentPosition == null) {
        // Try to get last known position
        _currentPosition = await _locationService.getLastKnownPosition();
      }

      if (_currentPosition == null) {
        _setError('Could not determine location');
      }
    } catch (e) {
      _setError('Error getting location: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshLocation() async {
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      _currentPosition = await _locationService.getCurrentPosition();
      if (_currentPosition == null) {
        _setError('Could not update location');
      }
    } catch (e) {
      _setError('Error refreshing location: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  void startLocationTracking() {
    if (!_hasPermission) return;

    _locationService.getPositionStream().listen(
      (position) {
        _currentPosition = position;
        notifyListeners();
      },
      onError: (error) {
        _setError('Location tracking error: ${error.toString()}');
      },
    );
  }

  double? getDistanceTo(double latitude, double longitude) {
    if (_currentPosition == null) return null;

    return _locationService.calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      latitude,
      longitude,
    );
  }

  bool isWithinRadius(double latitude, double longitude, double radiusInMiles) {
    if (_currentPosition == null) return false;
    return _locationService.isWithinRadius(latitude, longitude, radiusInMiles);
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
}
