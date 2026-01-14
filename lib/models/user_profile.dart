import 'permit.dart';
import 'reservation.dart';
import 'street_sweeping.dart';
import 'user_preferences.dart';
import 'ad_preferences.dart';
import 'subscription_plan.dart';
import 'vehicle.dart';
import 'city_rule_pack.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.formattedAddress,
    this.addressLatitude,
    this.addressLongitude,
    this.vehicles = const [],
    this.preferences = const UserPreferences(
      parkingNotifications: true,
      towAlerts: true,
      reminderNotifications: true,
    ),
    this.permits = const [],
    this.reservations = const [],
    this.sweepingSchedules = const [],
    this.adPreferences = const AdPreferences(),
    this.tier = SubscriptionTier.free,
    this.cityId = 'default',
    this.tenantId = 'default',
    this.rulePack = const CityRulePack(
      cityId: 'default',
      displayName: 'Default City',
    ),
    this.languageCode = 'en',
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? formattedAddress;
  final double? addressLatitude;
  final double? addressLongitude;
  final List<Vehicle> vehicles;
  final UserPreferences preferences;
  final AdPreferences adPreferences;
  final SubscriptionTier tier;
  final String cityId;
  final String tenantId;
  final CityRulePack rulePack;
  final String languageCode;
  final List<Permit> permits;
  final List<Reservation> reservations;
  final List<StreetSweepingSchedule> sweepingSchedules;

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? formattedAddress,
    double? addressLatitude,
    double? addressLongitude,
    List<Vehicle>? vehicles,
    UserPreferences? preferences,
    List<Permit>? permits,
    List<Reservation>? reservations,
    List<StreetSweepingSchedule>? sweepingSchedules,
    AdPreferences? adPreferences,
    SubscriptionTier? tier,
    String? cityId,
    String? tenantId,
    CityRulePack? rulePack,
    String? languageCode,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      addressLatitude: addressLatitude ?? this.addressLatitude,
      addressLongitude: addressLongitude ?? this.addressLongitude,
      vehicles: vehicles ?? this.vehicles,
      preferences: preferences ?? this.preferences,
      adPreferences: adPreferences ?? this.adPreferences,
      tier: tier ?? this.tier,
      cityId: cityId ?? this.cityId,
      tenantId: tenantId ?? this.tenantId,
      rulePack: rulePack ?? this.rulePack,
      languageCode: languageCode ?? this.languageCode,
      permits: permits ?? this.permits,
      reservations: reservations ?? this.reservations,
      sweepingSchedules: sweepingSchedules ?? this.sweepingSchedules,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final vehiclesJson = json['vehicles'] as List<dynamic>? ?? [];
    final permitsJson = json['permits'] as List<dynamic>? ?? [];
    final reservationsJson = json['reservations'] as List<dynamic>? ?? [];
    final sweepingJson = json['sweepingSchedules'] as List<dynamic>? ?? [];
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      formattedAddress: json['formattedAddress'] as String?,
      addressLatitude: (json['addressLatitude'] as num?)?.toDouble(),
      addressLongitude: (json['addressLongitude'] as num?)?.toDouble(),
      vehicles: vehiclesJson
          .map((vehicle) => Vehicle.fromJson(vehicle as Map<String, dynamic>))
          .toList(),
      preferences: json['preferences'] != null
          ? UserPreferences.fromJson(
              json['preferences'] as Map<String, dynamic>,
            )
          : UserPreferences.defaults(),
      adPreferences: json['adPreferences'] != null
          ? AdPreferences.fromJson(
              json['adPreferences'] as Map<String, dynamic>,
            )
          : const AdPreferences(),
      tier: SubscriptionTier.values.firstWhere(
        (value) => value.name == (json['tier'] as String? ?? 'free'),
        orElse: () => SubscriptionTier.free,
      ),
      cityId: json['cityId'] as String? ?? 'default',
      tenantId: json['tenantId'] as String? ?? 'default',
      rulePack: CityRulePack(
        cityId:
            (json['rulePack'] as Map<String, dynamic>?)?['cityId'] as String? ??
            'default',
        displayName:
            (json['rulePack'] as Map<String, dynamic>?)?['displayName']
                as String? ??
            'Default City',
        maxVehicles:
            (json['rulePack'] as Map<String, dynamic>?)?['maxVehicles']
                as int? ??
            5,
        defaultAlertRadius:
            (json['rulePack'] as Map<String, dynamic>?)?['defaultAlertRadius']
                as int? ??
            5,
        quotaRequestsPerHour:
            (json['rulePack'] as Map<String, dynamic>?)?['quotaRequestsPerHour']
                as int? ??
            100,
        rateLimitPerMinute:
            (json['rulePack'] as Map<String, dynamic>?)?['rateLimitPerMinute']
                as int? ??
            30,
      ),
      languageCode: json['languageCode'] as String? ?? 'en',
      permits: permitsJson
          .map((permit) => Permit.fromJson(permit as Map<String, dynamic>))
          .toList(),
      reservations: reservationsJson
          .map(
            (reservation) =>
                Reservation.fromJson(reservation as Map<String, dynamic>),
          )
          .toList(),
      sweepingSchedules: sweepingJson
          .map(
            (schedule) => StreetSweepingSchedule.fromJson(
              schedule as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'address': address,
    'formattedAddress': formattedAddress,
    'addressLatitude': addressLatitude,
    'addressLongitude': addressLongitude,
    'vehicles': vehicles.map((vehicle) => vehicle.toJson()).toList(),
    'preferences': preferences.toJson(),
    'adPreferences': adPreferences.toJson(),
    'tier': tier.name,
    'cityId': cityId,
    'tenantId': tenantId,
    'rulePack': {
      'cityId': rulePack.cityId,
      'displayName': rulePack.displayName,
      'maxVehicles': rulePack.maxVehicles,
      'defaultAlertRadius': rulePack.defaultAlertRadius,
      'quotaRequestsPerHour': rulePack.quotaRequestsPerHour,
      'rateLimitPerMinute': rulePack.rateLimitPerMinute,
    },
    'languageCode': languageCode,
    'permits': permits.map((permit) => permit.toJson()).toList(),
    'reservations': reservations.map((r) => r.toJson()).toList(),
    'sweepingSchedules': sweepingSchedules
        .map((schedule) => schedule.toJson())
        .toList(),
  };
}
