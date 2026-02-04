import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../models/user_profile.dart' as models;
import '../../models/user_preferences.dart';
import '../../models/ad_preferences.dart';
import '../../models/city_rule_pack.dart';
import '../../models/subscription_plan.dart';
import '../../models/vehicle.dart';

part 'local_database.g.dart';

class DbUserProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get email => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get formattedAddress => text().nullable()();
  RealColumn get addressLatitude => real().nullable()();
  RealColumn get addressLongitude => real().nullable()();
  TextColumn get preferencesJson => text()();
  TextColumn get adPreferencesJson => text()();
  TextColumn get tier => text()();
  TextColumn get cityId => text().withDefault(const Constant('default'))();
  TextColumn get tenantId => text().withDefault(const Constant('default'))();
  TextColumn get rulePackJson => text()();
  TextColumn get languageCode => text().withDefault(const Constant('en'))();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class DbVehicles extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text()();
  TextColumn get make => text()();
  TextColumn get model => text()();
  TextColumn get licensePlate => text()();
  TextColumn get color => text()();
  TextColumn get nickname => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class DbPendingMutations extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [DbUserProfiles, DbVehicles, DbPendingMutations])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase({QueryExecutor? executor})
    : super(executor ?? _openConnection());

  factory LocalDatabase.test() {
    return LocalDatabase(executor: NativeDatabase.memory());
  }

  @override
  int get schemaVersion => 1;

  Future<void> clearProfile(String userId) async {
    await transaction(() async {
      await (delete(
        dbUserProfiles,
      )..where((row) => row.id.equals(userId))).go();
      await (delete(
        dbVehicles,
      )..where((row) => row.profileId.equals(userId))).go();
    });
  }

  Future<void> upsertProfile(models.UserProfile profile) async {
    await transaction(() async {
      await into(dbUserProfiles).insertOnConflictUpdate(
        DbUserProfilesCompanion.insert(
          id: profile.id,
          name: profile.name,
          email: profile.email,
          phone: Value(profile.phone),
          address: Value(profile.address),
          formattedAddress: Value(profile.formattedAddress),
          addressLatitude: Value(profile.addressLatitude),
          addressLongitude: Value(profile.addressLongitude),
          preferencesJson: jsonEncode(profile.preferences.toJson()),
          adPreferencesJson: jsonEncode(profile.adPreferences.toJson()),
          tier: profile.tier.name,
          cityId: Value(profile.cityId),
          tenantId: Value(profile.tenantId),
          rulePackJson: jsonEncode({
            'cityId': profile.rulePack.cityId,
            'displayName': profile.rulePack.displayName,
            'maxVehicles': profile.rulePack.maxVehicles,
            'defaultAlertRadius': profile.rulePack.defaultAlertRadius,
            'quotaRequestsPerHour': profile.rulePack.quotaRequestsPerHour,
            'rateLimitPerMinute': profile.rulePack.rateLimitPerMinute,
          }),
          languageCode: Value(profile.languageCode),
          updatedAt: Value(DateTime.now()),
        ),
      );

      await (delete(
        dbVehicles,
      )..where((v) => v.profileId.equals(profile.id))).go();
      if (profile.vehicles.isNotEmpty) {
        await batch((b) {
          b.insertAllOnConflictUpdate(
            dbVehicles,
            profile.vehicles
                .map(
                  (vehicle) => DbVehiclesCompanion.insert(
                    id: vehicle.id,
                    profileId: profile.id,
                    make: vehicle.make,
                    model: vehicle.model,
                    licensePlate: vehicle.licensePlate,
                    color: vehicle.color,
                    nickname: vehicle.nickname,
                  ),
                )
                .toList(),
          );
        });
      }
    });
  }

  Future<models.UserProfile?> fetchProfile(String userId) async {
    final row =
        await (select(dbUserProfiles)
              ..where((tbl) => tbl.id.equals(userId))
              ..limit(1))
            .getSingleOrNull();
    if (row == null) return null;

    final profileVehicles = await (select(
      dbVehicles,
    )..where((v) => v.profileId.equals(userId))).get();

    final preferences = UserPreferences.fromJson(
      jsonDecode(row.preferencesJson),
    );
    final adPrefs = AdPreferences.fromJson(jsonDecode(row.adPreferencesJson));
    final rulePackJson = jsonDecode(row.rulePackJson) as Map<String, dynamic>;
    final rulePack = CityRulePack(
      cityId: rulePackJson['cityId'] as String? ?? 'default',
      displayName: rulePackJson['displayName'] as String? ?? 'Default City',
      maxVehicles: rulePackJson['maxVehicles'] as int? ?? 5,
      defaultAlertRadius: rulePackJson['defaultAlertRadius'] as int? ?? 5,
      quotaRequestsPerHour: rulePackJson['quotaRequestsPerHour'] as int? ?? 100,
      rateLimitPerMinute: rulePackJson['rateLimitPerMinute'] as int? ?? 30,
    );

    return models.UserProfile(
      id: row.id,
      name: row.name,
      email: row.email,
      phone: row.phone,
      address: row.address,
      formattedAddress: row.formattedAddress,
      addressLatitude: row.addressLatitude,
      addressLongitude: row.addressLongitude,
      vehicles: profileVehicles
          .map(
            (v) => Vehicle(
              id: v.id,
              make: v.make,
              model: v.model,
              licensePlate: v.licensePlate,
              color: v.color,
              nickname: v.nickname,
            ),
          )
          .toList(),
      preferences: preferences,
      adPreferences: adPrefs,
      tier: SubscriptionTier.values.firstWhere(
        (t) => t.name == row.tier,
        orElse: () => SubscriptionTier.free,
      ),
      cityId: row.cityId,
      tenantId: row.tenantId,
      rulePack: rulePack,
      languageCode: row.languageCode,
    );
  }

  Future<void> enqueueProfileSync(models.UserProfile profile) async {
    final payload = jsonEncode({
      'type': 'profile_upsert',
      'profile': profile.toJson(),
    });
    final mutationId = 'profile_upsert_${profile.id}';
    await into(dbPendingMutations).insertOnConflictUpdate(
      DbPendingMutationsCompanion.insert(
        id: mutationId,
        type: 'profile_upsert',
        payload: payload,
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<DbPendingMutation>> pendingMutations() async {
    return select(dbPendingMutations).get();
  }

  Future<void> removePending(String id) async {
    await (delete(dbPendingMutations)..where((tbl) => tbl.id.equals(id))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'mkecitysmart.db');
    final file = File(dbPath);
    return NativeDatabase.createInBackground(file);
  });
}
