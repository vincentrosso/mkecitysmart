class UserPreferences {
  const UserPreferences({
    required this.parkingNotifications,
    required this.towAlerts,
    required this.reminderNotifications,
    this.defaultVehicleId,
  });

  final bool parkingNotifications;
  final bool towAlerts;
  final bool reminderNotifications;
  final String? defaultVehicleId;

  factory UserPreferences.defaults() => const UserPreferences(
    parkingNotifications: true,
    towAlerts: true,
    reminderNotifications: true,
  );

  UserPreferences copyWith({
    bool? parkingNotifications,
    bool? towAlerts,
    bool? reminderNotifications,
    String? defaultVehicleId,
  }) {
    return UserPreferences(
      parkingNotifications: parkingNotifications ?? this.parkingNotifications,
      towAlerts: towAlerts ?? this.towAlerts,
      reminderNotifications:
          reminderNotifications ?? this.reminderNotifications,
      defaultVehicleId: defaultVehicleId ?? this.defaultVehicleId,
    );
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      parkingNotifications: json['parkingNotifications'] as bool? ?? true,
      towAlerts: json['towAlerts'] as bool? ?? true,
      reminderNotifications: json['reminderNotifications'] as bool? ?? true,
      defaultVehicleId: json['defaultVehicleId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'parkingNotifications': parkingNotifications,
    'towAlerts': towAlerts,
    'reminderNotifications': reminderNotifications,
    'defaultVehicleId': defaultVehicleId,
  };
}
