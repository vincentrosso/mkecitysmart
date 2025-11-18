import 'package:flutter/foundation.dart';

import '../models/user_preferences.dart';
import '../models/user_profile.dart';
import '../models/vehicle.dart';
import '../services/user_repository.dart';

class UserProvider extends ChangeNotifier {
  UserProvider({required UserRepository userRepository})
    : _repository = userRepository;

  final UserRepository _repository;

  UserProfile? _profile;
  bool _initializing = true;

  bool get isInitializing => _initializing;
  bool get isLoggedIn => _profile != null;
  UserProfile? get profile => _profile;

  Future<void> initialize() async {
    _profile = await _repository.loadProfile();
    _initializing = false;
    notifyListeners();
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    if (_profile != null) {
      return 'An account is already signed in on this device.';
    }
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      return 'All fields are required.';
    }

    final newProfile = UserProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      password: password,
      phone: phone,
      preferences: UserPreferences.defaults(),
      vehicles: const [],
    );
    await _repository.saveProfile(newProfile);
    _profile = newProfile;
    notifyListeners();
    return null;
  }

  Future<String?> login(String email, String password) async {
    final stored = await _repository.loadProfile();
    if (stored == null) {
      return 'No account found on this device.';
    }
    if (stored.email.trim().toLowerCase() != email.trim().toLowerCase() ||
        stored.password != password) {
      return 'Invalid email or password.';
    }
    _profile = stored;
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    _profile = null;
    await _repository.clearProfile();
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? address,
  }) async {
    if (_profile == null) return;
    final updated = _profile!.copyWith(
      name: name ?? _profile!.name,
      email: email ?? _profile!.email,
      phone: phone ?? _profile!.phone,
      address: address ?? _profile!.address,
    );
    _profile = updated;
    await _repository.saveProfile(updated);
    notifyListeners();
  }

  Future<void> changePassword(String password) async {
    if (_profile == null || password.isEmpty) return;
    _profile = _profile!.copyWith(password: password);
    await _repository.saveProfile(_profile!);
    notifyListeners();
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    if (_profile == null) return;
    final currentVehicles = List<Vehicle>.from(_profile!.vehicles)
      ..add(vehicle);
    final prefs = _profile!.preferences.defaultVehicleId == null
        ? _profile!.preferences.copyWith(defaultVehicleId: vehicle.id)
        : _profile!.preferences;
    _profile = _profile!.copyWith(
      vehicles: currentVehicles,
      preferences: prefs,
    );
    await _repository.saveProfile(_profile!);
    notifyListeners();
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    if (_profile == null) return;
    final updatedVehicles = _profile!.vehicles
        .map((existing) => existing.id == vehicle.id ? vehicle : existing)
        .toList();
    _profile = _profile!.copyWith(vehicles: updatedVehicles);
    await _repository.saveProfile(_profile!);
    notifyListeners();
  }

  Future<void> removeVehicle(String vehicleId) async {
    if (_profile == null) return;
    final updatedVehicles = _profile!.vehicles
        .where((vehicle) => vehicle.id != vehicleId)
        .toList();
    var preferences = _profile!.preferences;
    if (preferences.defaultVehicleId == vehicleId) {
      preferences = preferences.copyWith(
        defaultVehicleId: updatedVehicles.isEmpty
            ? null
            : updatedVehicles.first.id,
      );
    }
    _profile = _profile!.copyWith(
      vehicles: updatedVehicles,
      preferences: preferences,
    );
    await _repository.saveProfile(_profile!);
    notifyListeners();
  }

  Future<void> updatePreferences({
    bool? parkingNotifications,
    bool? towAlerts,
    bool? reminderNotifications,
    String? defaultVehicleId,
  }) async {
    if (_profile == null) return;
    final prefs = _profile!.preferences.copyWith(
      parkingNotifications: parkingNotifications,
      towAlerts: towAlerts,
      reminderNotifications: reminderNotifications,
      defaultVehicleId: defaultVehicleId,
    );
    _profile = _profile!.copyWith(preferences: prefs);
    await _repository.saveProfile(_profile!);
    notifyListeners();
  }
}
