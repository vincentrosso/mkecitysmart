/// Night Parking Permission model for Milwaukee's 2 AM – 6 AM parking rules.
///
/// Milwaukee requires a Night Parking Permission for most residential streets
/// between 2:00 AM and 6:00 AM. This model tracks a user's permission status.
library;

enum NightParkingStatus {
  /// User has not applied or we don't know their status
  unknown,

  /// User's address does not require night parking permission (exempt zone)
  exempt,

  /// User has an active, valid night parking permission
  active,

  /// Permission exists but has expired
  expired,

  /// User applied but permission was denied
  denied,

  /// User's application is pending
  pending,
}

class NightParkingPermission {
  const NightParkingPermission({
    required this.id,
    required this.status,
    required this.address,
    this.zoneId,
    this.licensePlate,
    this.vehicleDescription,
    this.issueDate,
    this.expirationDate,
    this.reminderEnabled = true,
    this.lastReminderSent,
  });

  /// Unique identifier for this permission record
  final String id;

  /// Current status of the night parking permission
  final NightParkingStatus status;

  /// The address this permission is associated with
  final String address;

  /// Milwaukee parking zone identifier (if applicable)
  final String? zoneId;

  /// Vehicle license plate number
  final String? licensePlate;

  /// Vehicle description (make, model, color)
  final String? vehicleDescription;

  /// Date the permission was issued
  final DateTime? issueDate;

  /// Date the permission expires (typically annual renewal)
  final DateTime? expirationDate;

  /// Whether the user wants reminders about night parking
  final bool reminderEnabled;

  /// When we last sent a reminder to this user
  final DateTime? lastReminderSent;

  /// Check if the permission is currently valid
  bool get isValid {
    if (status != NightParkingStatus.active) return false;
    if (expirationDate == null) return false;
    return expirationDate!.isAfter(DateTime.now());
  }

  /// Check if the permission is expiring within the given number of days
  bool isExpiringSoon({int withinDays = 30}) {
    if (status != NightParkingStatus.active) return false;
    if (expirationDate == null) return false;
    final now = DateTime.now();
    return expirationDate!.isAfter(now) &&
        expirationDate!.difference(now).inDays <= withinDays;
  }

  /// Days until expiration (negative if already expired)
  int? get daysUntilExpiration {
    if (expirationDate == null) return null;
    return expirationDate!.difference(DateTime.now()).inDays;
  }

  NightParkingPermission copyWith({
    String? id,
    NightParkingStatus? status,
    String? address,
    String? zoneId,
    String? licensePlate,
    String? vehicleDescription,
    DateTime? issueDate,
    DateTime? expirationDate,
    bool? reminderEnabled,
    DateTime? lastReminderSent,
  }) {
    return NightParkingPermission(
      id: id ?? this.id,
      status: status ?? this.status,
      address: address ?? this.address,
      zoneId: zoneId ?? this.zoneId,
      licensePlate: licensePlate ?? this.licensePlate,
      vehicleDescription: vehicleDescription ?? this.vehicleDescription,
      issueDate: issueDate ?? this.issueDate,
      expirationDate: expirationDate ?? this.expirationDate,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      lastReminderSent: lastReminderSent ?? this.lastReminderSent,
    );
  }

  factory NightParkingPermission.fromJson(Map<String, dynamic> json) {
    return NightParkingPermission(
      id: json['id'] as String,
      status: NightParkingStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => NightParkingStatus.unknown,
      ),
      address: json['address'] as String? ?? '',
      zoneId: json['zoneId'] as String?,
      licensePlate: json['licensePlate'] as String?,
      vehicleDescription: json['vehicleDescription'] as String?,
      issueDate: json['issueDate'] != null
          ? DateTime.tryParse(json['issueDate'] as String)
          : null,
      expirationDate: json['expirationDate'] != null
          ? DateTime.tryParse(json['expirationDate'] as String)
          : null,
      reminderEnabled: json['reminderEnabled'] as bool? ?? true,
      lastReminderSent: json['lastReminderSent'] != null
          ? DateTime.tryParse(json['lastReminderSent'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status.name,
    'address': address,
    'zoneId': zoneId,
    'licensePlate': licensePlate,
    'vehicleDescription': vehicleDescription,
    'issueDate': issueDate?.toIso8601String(),
    'expirationDate': expirationDate?.toIso8601String(),
    'reminderEnabled': reminderEnabled,
    'lastReminderSent': lastReminderSent?.toIso8601String(),
  };

  @override
  String toString() =>
      'NightParkingPermission(id: $id, status: $status, address: $address, '
      'expires: $expirationDate)';
}

/// Result of checking whether an address requires night parking permission
class NightParkingZoneResult {
  const NightParkingZoneResult({
    required this.requiresPermission,
    required this.zoneName,
    this.zoneId,
    this.exemptionReason,
    this.enforcementHours = '2:00 AM - 6:00 AM',
  });

  /// Whether this location requires night parking permission
  final bool requiresPermission;

  /// Human-readable zone name
  final String zoneName;

  /// Zone identifier for permit applications
  final String? zoneId;

  /// If exempt, the reason why (e.g., "Metered zone", "Downtown exempt area")
  final String? exemptionReason;

  /// Enforcement hours for this zone
  final String enforcementHours;

  factory NightParkingZoneResult.requiresPermission({
    required String zoneName,
    String? zoneId,
  }) {
    return NightParkingZoneResult(
      requiresPermission: true,
      zoneName: zoneName,
      zoneId: zoneId,
    );
  }

  factory NightParkingZoneResult.exempt({
    required String zoneName,
    required String reason,
  }) {
    return NightParkingZoneResult(
      requiresPermission: false,
      zoneName: zoneName,
      exemptionReason: reason,
    );
  }
}
