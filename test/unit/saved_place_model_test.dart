import 'package:flutter_test/flutter_test.dart';
import 'package:mkecitysmart/models/saved_place.dart';

void main() {
  final now = DateTime(2026, 2, 7, 12, 0);

  SavedPlace makeSample({
    String id = 'place_1',
    PlaceType type = PlaceType.home,
    String? nickname,
  }) {
    return SavedPlace(
      id: id,
      userId: 'user_1',
      name: 'My House',
      nickname: nickname,
      type: type,
      latitude: 43.0389,
      longitude: -87.9065,
      address: '123 Water St, Milwaukee, WI',
      geohash: 'dp5xyz',
      notifyRadiusMiles: 0.5,
      notificationsEnabled: true,
      createdAt: now,
      updatedAt: now,
      metadata: {'floor': 2},
    );
  }

  group('SavedPlace constructor & fields', () {
    test('stores all fields', () {
      final place = makeSample();
      expect(place.id, 'place_1');
      expect(place.userId, 'user_1');
      expect(place.name, 'My House');
      expect(place.type, PlaceType.home);
      expect(place.latitude, closeTo(43.039, 0.001));
      expect(place.longitude, closeTo(-87.906, 0.001));
      expect(place.address, '123 Water St, Milwaukee, WI');
      expect(place.geohash, 'dp5xyz');
      expect(place.notifyRadiusMiles, 0.5);
      expect(place.notificationsEnabled, isTrue);
      expect(place.metadata, {'floor': 2});
    });
  });

  group('SavedPlace.fromJson / toJson', () {
    test('round-trip preserves values', () {
      final original = makeSample();
      final json = original.toJson();
      final restored = SavedPlace.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.name, original.name);
      expect(restored.nickname, original.nickname);
      expect(restored.type, original.type);
      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
      expect(restored.address, original.address);
      expect(restored.geohash, original.geohash);
      expect(restored.notifyRadiusMiles, original.notifyRadiusMiles);
      expect(restored.notificationsEnabled, original.notificationsEnabled);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
    });

    test('toJson serializes type as string name', () {
      final json = makeSample(type: PlaceType.work).toJson();
      expect(json['type'], 'work');
    });

    test('fromJson parses each PlaceType', () {
      for (final pt in PlaceType.values) {
        final json = makeSample(type: pt).toJson();
        final restored = SavedPlace.fromJson(json);
        expect(restored.type, pt);
      }
    });

    test('fromJson falls back to favorite for unknown type', () {
      final json = makeSample().toJson();
      json['type'] = 'unknown_type';
      final restored = SavedPlace.fromJson(json);
      expect(restored.type, PlaceType.favorite);
    });

    test('fromJson handles defaults for optional numeric fields', () {
      final json = makeSample().toJson();
      json.remove('notifyRadiusMiles');
      json.remove('notificationsEnabled');
      final restored = SavedPlace.fromJson(json);
      expect(restored.notifyRadiusMiles, 0.5);
      expect(restored.notificationsEnabled, isTrue);
    });
  });

  group('SavedPlace.copyWith', () {
    test('copies with new name only', () {
      final original = makeSample();
      final copy = original.copyWith(name: 'New Name');
      expect(copy.name, 'New Name');
      expect(copy.id, original.id); // unchanged
      expect(copy.latitude, original.latitude); // unchanged
    });

    test('copies with multiple fields', () {
      final original = makeSample();
      final copy = original.copyWith(
        notificationsEnabled: false,
        notifyRadiusMiles: 1.0,
      );
      expect(copy.notificationsEnabled, isFalse);
      expect(copy.notifyRadiusMiles, 1.0);
      expect(copy.name, original.name);
    });
  });

  group('SavedPlace.displayName', () {
    test('returns nickname when set', () {
      final place = makeSample(nickname: 'Home Sweet Home');
      expect(place.displayName, 'Home Sweet Home');
    });

    test('returns name when nickname is null', () {
      final place = makeSample(nickname: null);
      expect(place.displayName, 'My House');
    });

    test('returns name when nickname is empty', () {
      final place = makeSample(nickname: '');
      expect(place.displayName, 'My House');
    });
  });

  group('SavedPlace.icon', () {
    test('home returns house emoji', () {
      expect(makeSample(type: PlaceType.home).icon, '🏠');
    });

    test('work returns briefcase emoji', () {
      expect(makeSample(type: PlaceType.work).icon, '💼');
    });

    test('favorite returns star emoji', () {
      expect(makeSample(type: PlaceType.favorite).icon, '⭐');
    });
  });

  group('SavedPlace equality', () {
    test('two places with same id are equal', () {
      final a = makeSample(id: 'same_id');
      final b = makeSample(id: 'same_id');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('two places with different ids are not equal', () {
      final a = makeSample(id: 'id_a');
      final b = makeSample(id: 'id_b');
      expect(a, isNot(equals(b)));
    });
  });
}
