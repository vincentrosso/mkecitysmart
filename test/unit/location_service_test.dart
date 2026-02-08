import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:mkecitysmart/models/parking_zone.dart';
import 'package:mkecitysmart/services/location_service.dart';

void main() {
  group('LocationService', () {
    final service = LocationService();

    test('calculateDistanceKm returns reasonable distance', () {
      final km = service.calculateDistanceKm(
        startLat: 43.0389,
        startLng: -87.9065,
        endLat: 43.0527,
        endLng: -87.9000,
      );
      expect(km, greaterThan(1));
      expect(km, lessThan(5));
    });

    test('loadDefaultZones returns sample data with future sweeps', () {
      final zones = service.loadDefaultZones();
      expect(zones, isNotEmpty);
      expect(zones.every((z) => z.nextSweep.isAfter(DateTime.now())), isTrue);
    });

    test('searchAddresses filters sample addresses', () {
      final results = service.searchAddresses('Holton');
      expect(results, isNotEmpty);
      expect(results.first, contains('Holton'));
      final defaultResults = service.searchAddresses('');
      expect(defaultResults.length, 3);
    });

    test('buildWalkingDirections produces steps with ETA', () {
      final zone = ParkingZone(
        id: 'z1',
        name: 'Zone',
        description: 'd',
        side: 'Odd',
        latitude: 43.0,
        longitude: -87.0,
        radiusMeters: 100,
        nextSweep: DateTime.now(),
        frequency: 'weekly',
        allowedSide: 'Odd only',
      );
      final pos = Position(
        latitude: 43.001,
        longitude: -87.001,
        timestamp: DateTime.now(),
        accuracy: 1,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        headingAccuracy: 0,
        altitudeAccuracy: 0,
      );
      final steps = service.buildWalkingDirections(start: pos, destination: zone);
      expect(steps.length, 3);
      expect(steps.last, contains('min'));
    });
  });
}
