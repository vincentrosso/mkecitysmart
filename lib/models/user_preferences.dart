class UserPreferences {
  const UserPreferences({
    required this.parkingNotifications,
    required this.towAlerts,
    required this.reminderNotifications,
    this.ticketRiskAlerts = true,
    this.ticketDueDateReminders = true,
    this.aspMorningReminder = true,
    this.aspEveningWarning = true,
    this.aspMidnightAlert = false,
    this.geoRadiusMiles = 5,
    this.defaultVehicleId,
  });

  final bool parkingNotifications;
  final bool towAlerts;
  final bool reminderNotifications;
  final bool ticketRiskAlerts;
  final bool ticketDueDateReminders; // Privacy option for ticket reminders
  final bool aspMorningReminder; // Alternate side parking – 7 AM
  final bool aspEveningWarning; // Alternate side parking – 9 PM
  final bool aspMidnightAlert; // Alternate side parking – 12 AM
  final int geoRadiusMiles;
  final String? defaultVehicleId;

  factory UserPreferences.defaults() => const UserPreferences(
    parkingNotifications: true,
    towAlerts: true,
    reminderNotifications: true,
    ticketRiskAlerts: true,
    ticketDueDateReminders: true,
    aspMorningReminder: true,
    aspEveningWarning: true,
    aspMidnightAlert: false,
    geoRadiusMiles: 5,
  );

  UserPreferences copyWith({
    bool? parkingNotifications,
    bool? towAlerts,
    bool? reminderNotifications,
    bool? ticketRiskAlerts,
    bool? ticketDueDateReminders,
    bool? aspMorningReminder,
    bool? aspEveningWarning,
    bool? aspMidnightAlert,
    int? geoRadiusMiles,
    String? defaultVehicleId,
  }) {
    return UserPreferences(
      parkingNotifications: parkingNotifications ?? this.parkingNotifications,
      towAlerts: towAlerts ?? this.towAlerts,
      reminderNotifications:
          reminderNotifications ?? this.reminderNotifications,
      ticketRiskAlerts: ticketRiskAlerts ?? this.ticketRiskAlerts,
      ticketDueDateReminders:
          ticketDueDateReminders ?? this.ticketDueDateReminders,
      aspMorningReminder: aspMorningReminder ?? this.aspMorningReminder,
      aspEveningWarning: aspEveningWarning ?? this.aspEveningWarning,
      aspMidnightAlert: aspMidnightAlert ?? this.aspMidnightAlert,
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
      ticketDueDateReminders: json['ticketDueDateReminders'] as bool? ?? true,
      aspMorningReminder: json['aspMorningReminder'] as bool? ?? true,
      aspEveningWarning: json['aspEveningWarning'] as bool? ?? true,
      aspMidnightAlert: json['aspMidnightAlert'] as bool? ?? false,
      geoRadiusMiles: json['geoRadiusMiles'] as int? ?? 5,
      defaultVehicleId: json['defaultVehicleId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'parkingNotifications': parkingNotifications,
    'towAlerts': towAlerts,
    'reminderNotifications': reminderNotifications,
    'ticketRiskAlerts': ticketRiskAlerts,
    'ticketDueDateReminders': ticketDueDateReminders,
    'aspMorningReminder': aspMorningReminder,
    'aspEveningWarning': aspEveningWarning,
    'aspMidnightAlert': aspMidnightAlert,
    'geoRadiusMiles': geoRadiusMiles,
    'defaultVehicleId': defaultVehicleId,
  };
}
