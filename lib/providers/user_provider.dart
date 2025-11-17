import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/permit.dart';
import '../services/storage_service.dart';
import '../utils/config.dart';

class UserProvider extends ChangeNotifier {
  User? _currentUser;
  List<Vehicle> _vehicles = [];
  List<Permit> _permits = [];
  UserPreferences? _preferences;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  List<Vehicle> get vehicles => _vehicles;
  List<Permit> get permits => _permits;
  UserPreferences? get preferences => _preferences;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;

  Future<void> initializeUser() async {
    _setLoading(true);
    _clearError();

    try {
      // Try to load user from storage service first
      final cachedUser = await StorageService.getUser();
      if (cachedUser != null) {
        _currentUser = cachedUser;
        _isAuthenticated = true;

        // Load additional data
        await _loadUserVehicles();
        await _loadUserPermits();
        await _loadUserPreferences();

        _setLoading(false);
        notifyListeners();
        return;
      }

      // Check for token in preferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(PreferenceKeys.userToken);

      if (token != null) {
        _isAuthenticated = true;
        await _loadUserProfile();
        await _loadUserVehicles();
        await _loadUserPermits();
        await _loadUserPreferences();

        // Cache the user data
        if (_currentUser != null) {
          await StorageService.saveUser(_currentUser!);
        }
      } else {
        _createMockUser(); // For development
        if (_currentUser != null) {
          await StorageService.saveUser(_currentUser!);
        }
      }
    } catch (e) {
      _setError('Error initializing user: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loginUser(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      // Mock login for development
      await Future.delayed(Duration(seconds: 1)); // Simulate API call

      _isAuthenticated = true;
      _createMockUser();

      // Save token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PreferenceKeys.userToken, 'mock_token_123');

      return true;
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logoutUser() async {
    _setLoading(true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(PreferenceKeys.userToken);
      await prefs.remove(PreferenceKeys.userProfile);

      // Clear storage service data
      await StorageService.clearUser();
      await StorageService.clearCache();

      _currentUser = null;
      _vehicles.clear();
      _permits.clear();
      _preferences = null;
      _isAuthenticated = false;
    } catch (e) {
      _setError('Error logging out: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    _setLoading(true);
    _clearError();

    try {
      // Mock API call
      await Future.delayed(Duration(milliseconds: 500));

      _vehicles.add(vehicle);
      await _saveVehiclesToStorage();
    } catch (e) {
      _setError('Error adding vehicle: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeVehicle(String vehicleId) async {
    _setLoading(true);
    _clearError();

    try {
      _vehicles.removeWhere((v) => v.id == vehicleId);
      await _saveVehiclesToStorage();
    } catch (e) {
      _setError('Error removing vehicle: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updatePreferences(UserPreferences newPreferences) async {
    _setLoading(true);
    _clearError();

    try {
      _preferences = newPreferences;
      await _savePreferencesToStorage();
    } catch (e) {
      _setError('Error updating preferences: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Vehicle? getDefaultVehicle() {
    return _vehicles.firstWhere(
      (vehicle) => vehicle.isDefault,
      orElse: () => _vehicles.isNotEmpty
          ? _vehicles.first
          : Vehicle(
              id: 'mock_vehicle',
              licensePlate: 'MOCK123',
              make: 'Toyota',
              model: 'Camry',
              year: 2020,
              color: 'Blue',
              type: VehicleType.car,
              isDefault: true,
            ),
    );
  }

  List<Permit> getActivePermits() {
    return _permits.where((permit) => permit.isActive).toList();
  }

  // Private methods
  Future<void> _loadUserProfile() async {
    // Mock implementation - would normally load from API
    _createMockUser();
  }

  Future<void> _loadUserVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    // Load vehicles from storage or create mock data
    _createMockVehicles();
  }

  Future<void> _loadUserPermits() async {
    // Try to load from cache first
    final cachedPermits = await StorageService.getCachedPermits();
    if (cachedPermits != null) {
      _permits = cachedPermits;
      notifyListeners();
      return;
    }

    // Load permits from API or create mock data
    _createMockPermits();

    // Cache the permits
    if (_permits.isNotEmpty) {
      await StorageService.cachePermits(_permits);
    }
  }

  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    // Load preferences from storage or create defaults
    _preferences = UserPreferences(
      pushNotifications: prefs.getBool('push_notifications') ?? true,
      streetSweepingAlerts: prefs.getBool('street_sweeping_alerts') ?? true,
      parkingReminders: prefs.getBool('parking_reminders') ?? true,
      preferredPaymentMethod:
          prefs.getString('payment_method') ?? 'credit_card',
      searchRadius: prefs.getDouble('search_radius') ?? 1.0,
    );
  }

  Future<void> _saveVehiclesToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final vehiclesJson = _vehicles.map((v) => v.toJson()).toList();
    await prefs.setString('vehicles', vehiclesJson.toString());
  }

  Future<void> _savePreferencesToStorage() async {
    if (_preferences == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications', _preferences!.pushNotifications);
    await prefs.setBool(
      'street_sweeping_alerts',
      _preferences!.streetSweepingAlerts,
    );
    await prefs.setBool('parking_reminders', _preferences!.parkingReminders);
    await prefs.setString(
      'payment_method',
      _preferences!.preferredPaymentMethod,
    );
    await prefs.setDouble('search_radius', _preferences!.searchRadius);
  }

  void _createMockUser() {
    _currentUser = User(
      id: 'user_123',
      email: 'user@milwaukee.gov',
      firstName: 'John',
      lastName: 'Doe',
      phoneNumber: '(414) 555-0123',
      vehicles: [],
      preferences: UserPreferences(
        pushNotifications: true,
        streetSweepingAlerts: true,
        parkingReminders: true,
        preferredPaymentMethod: 'credit_card',
        searchRadius: 1.0,
      ),
      createdAt: DateTime.now().subtract(Duration(days: 30)),
      updatedAt: DateTime.now(),
    );
  }

  void _createMockVehicles() {
    _vehicles = [
      Vehicle(
        id: 'vehicle_1',
        licensePlate: 'ABC123',
        make: 'Toyota',
        model: 'Camry',
        year: 2020,
        color: 'Blue',
        type: VehicleType.car,
        isDefault: true,
      ),
    ];
  }

  void _createMockPermits() {
    final now = DateTime.now();
    _permits = [
      Permit(
        id: 'permit_1',
        permitNumber: 'MKE2024-001',
        type: PermitType.residential,
        startDate: now.subtract(Duration(days: 10)),
        endDate: now.add(Duration(days: 355)),
        status: PermitStatus.active,
        vehicle: _vehicles.first,
        zone: 'Zone A',
        cost: 85.00,
        qrCode: 'QR_CODE_DATA_HERE',
      ),
    ];
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
