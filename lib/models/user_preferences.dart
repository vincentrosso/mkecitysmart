class UserPreferences {
  const UserPreferences({
    required this.parkingNotifications,
    required this.towAlerts,
    required this.reminderNotifications,
    this.ticketRiskAlerts = true,
    this.geoRadiusMiles = 5,
    this.defaultVehicleId,
  });

  final bool parkingNotifications;
  final bool towAlerts;
  final bool reminderNotifications;
  final bool ticketRiskAlerts;
  final int geoRadiusMiles;
  final String? defaultVehicleId;

  factory UserPreferences.defaults() => const UserPreferences(
    parkingNotifications: true,
    towAlerts: true,
    reminderNotifications: true,
    ticketRiskAlerts: true,
    geoRadiusMiles: 5,
  );

  UserPreferences copyWith({
    bool? parkingNotifications,
    bool? towAlerts,
    bool? reminderNotifications,
    bool? ticketRiskAlerts,
    int? geoRadiusMiles,
    String? defaultVehicleId,
  }) {
    return UserPreferences(
      parkingNotifications: parkingNotifications ?? this.parkingNotifications,
      towAlerts: towAlerts ?? this.towAlerts,
      reminderNotifications:
          reminderNotifications ?? this.reminderNotifications,
      ticketRiskAlerts: ticketRiskAlerts ?? this.ticketRiskAlerts,
      geoRadiusMiles: geoRadiusMiles ?? this.geoRadiusMiles,
      defaultVehicleId: defaultVehicleId ?? this.defaultVehicleId,
    );
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      parkingNotifications: json['parkingNotifications'] as bool? ?? true,
      towAlerts: json['towAlerts'] as bool? ?? true,
      reminderNotifications: json['reminderNotifications'] as bool? ?? true,
      ticketRiskAlerts: json['ticketRiskAlerts'] as bool? ?? true,
      geoRadiusMiles: json['geoRadiusMiles'] as int? ?? 5,
      defaultVehicleId: json['defaultVehicleId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'parkingNotifications': parkingNotifications,
    'towAlerts': towAlerts,
    'reminderNotifications': reminderNotifications,
    'ticketRiskAlerts': ticketRiskAlerts,
    'geoRadiusMiles': geoRadiusMiles,
    'defaultVehicleId': defaultVehicleId,
  };
}
