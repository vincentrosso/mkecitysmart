import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:mkecitysmart/models/parking_zone.dart';
import 'package:mkecitysmart/models/street_sweeping.dart';
import 'package:mkecitysmart/providers/location_provider.dart';
import 'package:mkecitysmart/services/location_service.dart';

class FakeLocationService extends LocationService {
  FakeLocationService({
    required this.position,
    required this.zones,
    this.searchResults = const ['123 Main St'],
    this.distanceKm = 0.05,
  });

  Position? position;
  List<ParkingZone> zones;
  List<String> searchResults;
  double distanceKm;

  @override
  Future<Position?> getCurrentPosition() async => position;

  @override
  List<ParkingZone> loadDefaultZones() => zones;

  @override
  List<String> searchAddresses(String query) => searchResults;

  @override
  List<String> buildWalkingDirections({
    required Position start,
    required ParkingZone destination,
  }) {
    return ['Walk to ${destination.name}'];
  }

  @override
  double calculateDistanceKm({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return distanceKm;
  }
}

Position _samplePosition() {
  return Position(
    longitude: -87.9,
    latitude: 43.0,
    timestamp: DateTime.now(),
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 1,
    heading: 0,
    headingAccuracy: 1,
    speed: 0,
    speedAccuracy: 1,
    isMocked: false,
  );
}

ParkingZone _zone(String id, double radiusMeters, Duration sweepIn) {
  return ParkingZone(
    id: id,
    name: 'Zone $id',
    description: 'Test zone $id',
    side: 'Odd',
    latitude: 43.0,
    longitude: -87.9,
    radiusMeters: radiusMeters,
    nextSweep: DateTime.now().add(sweepIn),
    frequency: 'Weekly',
    allowedSide: 'Odd',
  );
}

void main() {
  late FakeLocationService service;
  late LocationProvider provider;

  setUp(() async {
    service = FakeLocationService(
      position: _samplePosition(),
      zones: [
        _zone('a', 500, const Duration(hours: 2)),
        _zone('b', 200, const Duration(hours: 8)),
      ],
    );
    provider = LocationProvider(service: service);
    await provider.initialize();
  });

  tearDown(() {
    provider.dispose();
  });

  test('initialize loads zones and sets location', () async {
    expect(provider.zones, isNotEmpty);
    expect(provider.position, isNotNull);
    expect(provider.insideGeofence, isTrue);
  });

  test('refreshLocation flags GPS denied when service returns null', () async {
    service.position = null;

    await provider.refreshLocation();

    expect(provider.gpsDenied, isTrue);
  });

  test('selectZone sets selection and walking directions', () async {
    provider.selectZone(service.zones.last);

    expect(provider.selectedZone, service.zones.last);
    expect(provider.walkingDirections, isNotEmpty);
  });

  test('searchAddress populates suggestions', () {
    service.searchResults = ['456 Oak St'];

    provider.searchAddress('oak');

    expect(provider.addressSuggestions, contains('456 Oak St'));
  });

  test('searchAddress returns defaults when query is empty', () {
    service.searchResults = ['One', 'Two', 'Three'];

    provider.searchAddress('');

    expect(provider.addressSuggestions.length, 3);
  });

  test('updateSweepingNotifications toggles flags on schedule', () async {
    final id = provider.sweepingSchedules.first.id;

    await provider.updateSweepingNotifications(
      id,
      gpsMonitoring: false,
      advance24h: false,
      final2h: false,
      customMinutes: 15,
    );

    final updated =
        provider.sweepingSchedules.firstWhere((s) => s.id == id);
    expect(updated.gpsMonitoring, isFalse);
    expect(updated.advance24h, isFalse);
    expect(updated.final2h, isFalse);
    expect(updated.customMinutes, 15);
  });

  test('logVehicleMoved increments streak and prevention counts', () async {
    final id = provider.sweepingSchedules.first.id;
    final before = provider.sweepingSchedules.first;

    await provider.logVehicleMoved(id);

    final updated =
        provider.sweepingSchedules.firstWhere((s) => s.id == id);
    expect(updated.cleanStreakDays, before.cleanStreakDays + 1);
    expect(updated.violationsPrevented, before.violationsPrevented + 1);
  });

  test('cityParkingSuggestions aggregates alternative parking', () {
    expect(provider.cityParkingSuggestions, isNotEmpty);
  });

  test('violation stats expose prevented and received totals', () {
    expect(provider.preventedViolations, greaterThan(0));
    expect(provider.ticketsReceived, greaterThan(0));
  });

  test('sortedZones orders by next sweep time', () {
    final sorted = provider.sortedZones;
    expect(sorted.first.nextSweep.isBefore(sorted.last.nextSweep), isTrue);
  });

  test('geofence marks outside when distance exceeds radius', () async {
    final farService = FakeLocationService(
      position: _samplePosition(),
      zones: [_zone('far', 100, const Duration(hours: 1))],
      distanceKm: 5,
    );
    final farProvider = LocationProvider(service: farService);
    await farProvider.initialize();

    expect(farProvider.insideGeofence, isFalse);
    farProvider.dispose();
  });

  test('emergency alerts surface when sweep is imminent', () async {
    provider.sweepingSchedules
      ..clear()
      ..add(
        StreetSweepingSchedule(
          id: 'urgent',
          zone: 'Urgent Zone',
          side: 'All',
          nextSweep: DateTime.now().add(const Duration(hours: 2)),
          gpsMonitoring: true,
          advance24h: true,
          final2h: true,
          customMinutes: 30,
          alternativeParking: const ['Alt lot'],
          cleanStreakDays: 0,
          violationsPrevented: 0,
        ),
      );

    await provider.refreshLocation();

    expect(provider.emergencyMessage, isNotNull);
  });
}
