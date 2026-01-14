import 'package:flutter_test/flutter_test.dart';
import 'package:mkecitysmart/data/local/local_database.dart';
import 'package:mkecitysmart/models/user_profile.dart';
import 'package:mkecitysmart/models/user_preferences.dart';
import 'package:mkecitysmart/models/vehicle.dart';

void main() {
  group('LocalDatabase', () {
    late LocalDatabase db;

    setUp(() {
      db = LocalDatabase.test();
    });

    tearDown(() async {
      await db.close();
    });

    UserProfile sampleProfile({String id = 'u1'}) {
      return UserProfile(
        id: id,
        name: 'Test User',
        email: 'test@example.com',
        phone: '123',
        address: '123 Main',
        formattedAddress: '123 Main St, Milwaukee, WI',
        addressLatitude: 43.0,
        addressLongitude: -87.9,
        vehicles: const [
          Vehicle(
            id: 'v1',
            make: 'Ford',
            model: 'Focus',
            licensePlate: 'ABC123',
            color: 'Blue',
            nickname: 'Car',
          )
        ],
        preferences: UserPreferences.defaults(),
      );
    }

    test('upsert and fetch profile with vehicles', () async {
      final profile = sampleProfile();
      await db.upsertProfile(profile);

      final fetched = await db.fetchProfile('u1');
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Test User');
      expect(fetched.vehicles.single.licensePlate, 'ABC123');
      expect(fetched.rulePack.cityId, 'default');
    });

    test('clearProfile removes profile and vehicles', () async {
      await db.upsertProfile(sampleProfile());
      await db.clearProfile('u1');

      final fetched = await db.fetchProfile('u1');
      expect(fetched, isNull);
    });

    test('enqueueProfileSync stores pending mutation', () async {
      await db.enqueueProfileSync(sampleProfile());
      final pending = await db.pendingMutations();
      expect(pending.length, 1);
      await db.removePending(pending.first.id);
      final pendingAfter = await db.pendingMutations();
      expect(pendingAfter, isEmpty);
    });
  });
}
