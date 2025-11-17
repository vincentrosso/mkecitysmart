class User {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final List<Vehicle> vehicles;
  final UserPreferences preferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    required this.vehicles,
    required this.preferences,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      vehicles: (json['vehicles'] as List<dynamic>)
          .map((v) => Vehicle.fromJson(v as Map<String, dynamic>))
          .toList(),
      preferences: UserPreferences.fromJson(
        json['preferences'] as Map<String, dynamic>,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'vehicles': vehicles.map((v) => v.toJson()).toList(),
      'preferences': preferences.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class Vehicle {
  final String id;
  final String licensePlate;
  final String make;
  final String model;
  final int year;
  final String color;
  final VehicleType type;
  final bool isDefault;

  const Vehicle({
    required this.id,
    required this.licensePlate,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.type,
    required this.isDefault,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      licensePlate: json['licensePlate'] as String,
      make: json['make'] as String,
      model: json['model'] as String,
      year: json['year'] as int,
      color: json['color'] as String,
      type: VehicleType.values.firstWhere((e) => e.name == json['type']),
      isDefault: json['isDefault'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'licensePlate': licensePlate,
      'make': make,
      'model': model,
      'year': year,
      'color': color,
      'type': type.name,
      'isDefault': isDefault,
    };
  }
}

class UserPreferences {
  final bool pushNotifications;
  final bool streetSweepingAlerts;
  final bool parkingReminders;
  final String preferredPaymentMethod;
  final double searchRadius;

  const UserPreferences({
    required this.pushNotifications,
    required this.streetSweepingAlerts,
    required this.parkingReminders,
    required this.preferredPaymentMethod,
    required this.searchRadius,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      pushNotifications: json['pushNotifications'] as bool,
      streetSweepingAlerts: json['streetSweepingAlerts'] as bool,
      parkingReminders: json['parkingReminders'] as bool,
      preferredPaymentMethod: json['preferredPaymentMethod'] as String,
      searchRadius: (json['searchRadius'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushNotifications': pushNotifications,
      'streetSweepingAlerts': streetSweepingAlerts,
      'parkingReminders': parkingReminders,
      'preferredPaymentMethod': preferredPaymentMethod,
      'searchRadius': searchRadius,
    };
  }
}

enum VehicleType { car, truck, motorcycle, suv, van }
