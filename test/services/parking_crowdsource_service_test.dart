import 'package:flutter_test/flutter_test.dart';
import 'package:mkecitysmart/models/parking_report.dart';
import 'package:mkecitysmart/services/parking_crowdsource_service.dart';

void main() {
  group('ParkingCrowdsourceService.encodeGeohash', () {
    test('Milwaukee downtown encodes to expected prefix', () {
      // Milwaukee City Hall: 43.0389, -87.9065
      final hash = ParkingCrowdsourceService.encodeGeohash(43.0389, -87.9065, 7);
      expect(hash.length, 7);
      // Milwaukee should start with 'dp5' at precision 3
      expect(hash.substring(0, 3), 'dp5');
    });

    test('different precisions produce shorter/longer hashes', () {
      final h5 = ParkingCrowdsourceService.encodeGeohash(43.0389, -87.9065, 5);
      final h7 = ParkingCrowdsourceService.encodeGeohash(43.0389, -87.9065, 7);
      expect(h5.length, 5);
      expect(h7.length, 7);
      // Longer hash should start with shorter hash
      expect(h7.startsWith(h5), isTrue);
    });

    test('nearby locations share geohash prefix', () {
      // Two spots ~50m apart on Water St, Milwaukee
      final hash1 =
          ParkingCrowdsourceService.encodeGeohash(43.0389, -87.9065, 5);
      final hash2 =
          ParkingCrowdsourceService.encodeGeohash(43.0392, -87.9063, 5);
      expect(hash1, hash2); // Same at precision 5 (~4.9km cell)
    });

    test('distant locations have different prefixes', () {
      // Milwaukee vs Chicago
      final mke =
          ParkingCrowdsourceService.encodeGeohash(43.0389, -87.9065, 5);
      final chi =
          ParkingCrowdsourceService.encodeGeohash(41.8781, -87.6298, 5);
      expect(mke, isNot(chi));
    });

    test('equator and prime meridian produce valid geohash', () {
      final hash = ParkingCrowdsourceService.encodeGeohash(0.0, 0.0, 7);
      expect(hash.length, 7);
      expect(hash, 's000000'); // Known geohash for 0,0
    });

    test('extreme coordinates produce valid geohashes', () {
      final north = ParkingCrowdsourceService.encodeGeohash(90.0, 180.0, 5);
      final south = ParkingCrowdsourceService.encodeGeohash(-90.0, -180.0, 5);
      expect(north.length, 5);
      expect(south.length, 5);
      expect(north, isNot(south));
    });
  });

  group('ParkingCrowdsourceService.aggregateAvailability', () {
    final service = ParkingCrowdsourceService.instance;
    final now = DateTime.now();

    ParkingReport makeReport(
      ReportType type, {
      int upvotes = 0,
      int downvotes = 0,
      int ageMinutes = 0,
    }) {
      return ParkingReport(
        id: 'rpt_${type.name}_$ageMinutes',
        userId: 'user_1',
        reportType: type,
        latitude: 43.0389,
        longitude: -87.9065,
        geohash: 'dp5dtpp',
        timestamp: now.subtract(Duration(minutes: ageMinutes)),
        expiresAt: now.add(Duration(minutes: type.ttlMinutes - ageMinutes)),
        upvotes: upvotes,
        downvotes: downvotes,
      );
    }

    test('empty reports produce neutral availability', () {
      final result = service.aggregateAvailability([]);
      expect(result.totalReports, 0);
      expect(result.availabilityScore, 0.5);
      expect(result.label, 'Limited spots');
    });

    test('mostly available signals produce high score', () {
      final reports = [
        makeReport(ReportType.leavingSpot),
        makeReport(ReportType.spotAvailable),
        makeReport(ReportType.spotAvailable),
        makeReport(ReportType.leavingSpot),
        makeReport(ReportType.spotTaken),
      ];
      final result = service.aggregateAvailability(reports);
      expect(result.availableSignals, 4);
      expect(result.takenSignals, 1);
      expect(result.availabilityScore, greaterThan(0.6));
    });

    test('mostly taken signals produce low score', () {
      final reports = [
        makeReport(ReportType.spotTaken),
        makeReport(ReportType.spotTaken),
        makeReport(ReportType.parkedHere),
        makeReport(ReportType.parkedHere),
        makeReport(ReportType.spotAvailable),
      ];
      final result = service.aggregateAvailability(reports);
      expect(result.availableSignals, 1);
      expect(result.takenSignals, 4);
      expect(result.availabilityScore, lessThan(0.4));
    });

    test('enforcement spotted is counted separately', () {
      final reports = [
        makeReport(ReportType.enforcementSpotted),
        makeReport(ReportType.towTruckSpotted),
        makeReport(ReportType.spotAvailable),
      ];
      final result = service.aggregateAvailability(reports);
      expect(result.enforcementSignals, 2);
      expect(result.hasEnforcement, isTrue);
    });

    test('geohashPrefix is extracted from reports', () {
      final reports = [
        makeReport(ReportType.spotAvailable),
      ];
      final result = service.aggregateAvailability(reports);
      expect(result.geohashPrefix, 'dp5dt');
    });

    test('lastUpdated is the most recent timestamp', () {
      final reports = [
        makeReport(ReportType.spotAvailable, ageMinutes: 5),
        makeReport(ReportType.spotTaken, ageMinutes: 0), // Most recent
        makeReport(ReportType.leavingSpot, ageMinutes: 10),
      ];
      final result = service.aggregateAvailability(reports);
      // The most recent should be ageMinutes=0
      expect(
        result.lastUpdated.difference(now).inSeconds.abs(),
        lessThan(2),
      );
    });

    test('street sweeping counts as taken', () {
      final reports = [
        makeReport(ReportType.streetSweepingActive),
      ];
      final result = service.aggregateAvailability(reports);
      expect(result.takenSignals, 1);
      expect(result.availableSignals, 0);
    });

    test('parking blocked counts as taken', () {
      final reports = [
        makeReport(ReportType.parkingBlocked),
      ];
      final result = service.aggregateAvailability(reports);
      expect(result.takenSignals, 1);
    });
  });
}
