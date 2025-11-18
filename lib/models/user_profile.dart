import 'user_preferences.dart';
import 'vehicle.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.phone,
    this.address,
    this.vehicles = const [],
    this.preferences = const UserPreferences(
      parkingNotifications: true,
      towAlerts: true,
      reminderNotifications: true,
    ),
  });

  final String id;
  final String name;
  final String email;
  final String password;
  final String? phone;
  final String? address;
  final List<Vehicle> vehicles;
  final UserPreferences preferences;

  UserProfile copyWith({
    String? name,
    String? email,
    String? password,
    String? phone,
    String? address,
    List<Vehicle>? vehicles,
    UserPreferences? preferences,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      vehicles: vehicles ?? this.vehicles,
      preferences: preferences ?? this.preferences,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final vehiclesJson = json['vehicles'] as List<dynamic>? ?? [];
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      vehicles: vehiclesJson
          .map((vehicle) => Vehicle.fromJson(vehicle as Map<String, dynamic>))
          .toList(),
      preferences: json['preferences'] != null
          ? UserPreferences.fromJson(
              json['preferences'] as Map<String, dynamic>,
            )
          : UserPreferences.defaults(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'password': password,
    'phone': phone,
    'address': address,
    'vehicles': vehicles.map((vehicle) => vehicle.toJson()).toList(),
    'preferences': preferences.toJson(),
  };
}
