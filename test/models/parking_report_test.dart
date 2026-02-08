import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mkecitysmart/models/parking_report.dart';

void main() {
  group('ReportType', () {
    test('displayName returns human-readable label', () {
      expect(ReportType.leavingSpot.displayName, 'Leaving Spot');
      expect(ReportType.parkedHere.displayName, 'Parked Here');
      expect(ReportType.spotAvailable.displayName, 'Spot Available');
      expect(ReportType.spotTaken.displayName, 'Spot Taken');
      expect(ReportType.enforcementSpotted.displayName, 'Enforcement Spotted');
      expect(ReportType.towTruckSpotted.displayName, 'Tow Truck Spotted');
      expect(
          ReportType.streetSweepingActive.displayName, 'Street Sweeping Active');
      expect(ReportType.parkingBlocked.displayName, 'Parking Blocked');
    });

    test('ttlMinutes varies by severity', () {
      // Quick-to-change events have short TTLs
      expect(ReportType.leavingSpot.ttlMinutes, 10);
      expect(ReportType.spotAvailable.ttlMinutes, 15);
      // Long-duration events have longer TTLs
      expect(ReportType.streetSweepingActive.ttlMinutes, 180);
      expect(ReportType.parkingBlocked.ttlMinutes, 480);
    });

    test('isPositiveSignal correct for each type', () {
      expect(ReportType.leavingSpot.isPositiveSignal, isTrue);
      expect(ReportType.spotAvailable.isPositiveSignal, isTrue);
      expect(ReportType.parkedHere.isPositiveSignal, isFalse);
      expect(ReportType.spotTaken.isPositiveSignal, isFalse);
      expect(ReportType.enforcementSpotted.isPositiveSignal, isFalse);
      expect(ReportType.towTruckSpotted.isPositiveSignal, isFalse);
      expect(ReportType.streetSweepingActive.isPositiveSignal, isFalse);
      expect(ReportType.parkingBlocked.isPositiveSignal, isFalse);
    });

    test('icon is non-null for every type', () {
      for (final type in ReportType.values) {
        expect(type.icon, isNotNull);
      }
    });
  });

  group('ParkingReport', () {
    late ParkingReport report;
    late DateTime now;

    setUp(() {
      now = DateTime(2025, 2, 7, 14, 30);
      report = ParkingReport(
        id: 'rpt_001',
        userId: 'user_123',
        reportType: ReportType.leavingSpot,
        latitude: 43.0389,
        longitude: -87.9065,
        geohash: 'dp5dtpp',
        timestamp: now,
        expiresAt: now.add(const Duration(minutes: 10)),
        accuracyMeters: 8.5,
        note: 'By the meter on Water St',
        upvotes: 3,
        downvotes: 1,
      );
    });

    test('basic properties', () {
      expect(report.id, 'rpt_001');
      expect(report.userId, 'user_123');
      expect(report.reportType, ReportType.leavingSpot);
      expect(report.latitude, 43.0389);
      expect(report.longitude, -87.9065);
      expect(report.geohash, 'dp5dtpp');
      expect(report.accuracyMeters, 8.5);
      expect(report.note, 'By the meter on Water St');
      expect(report.upvotes, 3);
      expect(report.downvotes, 1);
      expect(report.isExpired, isFalse);
    });

    test('reliabilityScore calculates correctly', () {
      // 3 upvotes, 1 downvote = 3/4 = 0.75
      expect(report.reliabilityScore, 0.75);

      // Zero votes = neutral 0.5
      final noVotes = report.copyWith(upvotes: 0, downvotes: 0);
      expect(noVotes.reliabilityScore, 0.5);

      // All upvotes
      final allUp = report.copyWith(upvotes: 10, downvotes: 0);
      expect(allUp.reliabilityScore, 1.0);

      // All downvotes
      final allDown = report.copyWith(upvotes: 0, downvotes: 5);
      expect(allDown.reliabilityScore, 0.0);
    });

    test('toJson / fromJson round-trip', () {
      final json = report.toJson();

      expect(json['id'], 'rpt_001');
      expect(json['userId'], 'user_123');
      expect(json['reportType'], 'leavingSpot');
      expect(json['latitude'], 43.0389);
      expect(json['longitude'], -87.9065);
      expect(json['geohash'], 'dp5dtpp');
      expect(json['accuracyMeters'], 8.5);
      expect(json['note'], 'By the meter on Water St');
      expect(json['upvotes'], 3);
      expect(json['downvotes'], 1);
      expect(json['isExpired'], isFalse);

      final restored = ParkingReport.fromJson(json);
      expect(restored.id, report.id);
      expect(restored.userId, report.userId);
      expect(restored.reportType, report.reportType);
      expect(restored.latitude, report.latitude);
      expect(restored.longitude, report.longitude);
      expect(restored.geohash, report.geohash);
      expect(restored.timestamp, report.timestamp);
      expect(restored.expiresAt, report.expiresAt);
      expect(restored.accuracyMeters, report.accuracyMeters);
      expect(restored.note, report.note);
      expect(restored.upvotes, report.upvotes);
      expect(restored.downvotes, report.downvotes);
      expect(restored.isExpired, report.isExpired);
    });

    test('fromJson handles missing optional fields', () {
      final minimal = {
        'id': 'rpt_002',
        'userId': 'user_456',
        'reportType': 'spotAvailable',
        'latitude': 43.04,
        'longitude': -87.91,
        'geohash': 'dp5dtq0',
        'timestamp': now.toIso8601String(),
        'expiresAt': now.add(const Duration(minutes: 15)).toIso8601String(),
      };

      final parsed = ParkingReport.fromJson(minimal);
      expect(parsed.accuracyMeters, isNull);
      expect(parsed.note, isNull);
      expect(parsed.upvotes, 0);
      expect(parsed.downvotes, 0);
      expect(parsed.isExpired, isFalse);
    });

    test('fromJson handles unknown reportType gracefully', () {
      final json = report.toJson();
      json['reportType'] = 'unknownType';
      final parsed = ParkingReport.fromJson(json);
      expect(parsed.reportType, ReportType.spotTaken); // default fallback
    });

    test('copyWith creates a modified copy', () {
      final updated = report.copyWith(
        upvotes: 10,
        note: 'Updated note',
        isExpired: true,
      );
      expect(updated.upvotes, 10);
      expect(updated.note, 'Updated note');
      expect(updated.isExpired, isTrue);
      // Unchanged fields preserved
      expect(updated.id, report.id);
      expect(updated.userId, report.userId);
      expect(updated.reportType, report.reportType);
      expect(updated.latitude, report.latitude);
      expect(updated.timestamp, report.timestamp);
    });

    test('equality based on id', () {
      final duplicate = ParkingReport(
        id: 'rpt_001',
        userId: 'different_user',
        reportType: ReportType.spotTaken,
        latitude: 0,
        longitude: 0,
        geohash: 'abc',
        timestamp: DateTime.now(),
        expiresAt: DateTime.now(),
      );
      expect(report, equals(duplicate)); // Same id
      expect(report.hashCode, duplicate.hashCode);

      // To test inequality, build one with different id
      final other = ParkingReport(
        id: 'rpt_999',
        userId: 'user_123',
        reportType: ReportType.leavingSpot,
        latitude: 43.0389,
        longitude: -87.9065,
        geohash: 'dp5dtpp',
        timestamp: now,
        expiresAt: now.add(const Duration(minutes: 10)),
      );
      expect(report, isNot(equals(other)));
    });

    test('toString includes useful info', () {
      final str = report.toString();
      expect(str, contains('rpt_001'));
      expect(str, contains('Leaving Spot'));
      expect(str, contains('43.0389'));
    });
  });

  group('SpotAvailability', () {
    test('availabilityScore is 0.5 when no reports', () {
      final empty = SpotAvailability(
        geohashPrefix: 'dp5dt',
        totalReports: 0,
        availableSignals: 0,
        takenSignals: 0,
        enforcementSignals: 0,
        lastUpdated: DateTime.now(),
      );
      expect(empty.availabilityScore, 0.5);
    });

    test('availabilityScore high when mostly available', () {
      final good = SpotAvailability(
        geohashPrefix: 'dp5dt',
        totalReports: 10,
        availableSignals: 8,
        takenSignals: 2,
        enforcementSignals: 0,
        lastUpdated: DateTime.now(),
      );
      expect(good.availabilityScore, greaterThan(0.7));
      expect(good.label, 'Good availability');
    });

    test('availabilityScore low when mostly taken', () {
      final bad = SpotAvailability(
        geohashPrefix: 'dp5dt',
        totalReports: 10,
        availableSignals: 1,
        takenSignals: 9,
        enforcementSignals: 0,
        lastUpdated: DateTime.now(),
      );
      expect(bad.availabilityScore, lessThan(0.4));
    });

    test('enforcement penalty reduces score', () {
      final withEnforcement = SpotAvailability(
        geohashPrefix: 'dp5dt',
        totalReports: 10,
        availableSignals: 5,
        takenSignals: 5,
        enforcementSignals: 2,
        lastUpdated: DateTime.now(),
      );
      final withoutEnforcement = SpotAvailability(
        geohashPrefix: 'dp5dt',
        totalReports: 10,
        availableSignals: 5,
        takenSignals: 5,
        enforcementSignals: 0,
        lastUpdated: DateTime.now(),
      );
      expect(withEnforcement.availabilityScore,
          lessThan(withoutEnforcement.availabilityScore));
      expect(withEnforcement.hasEnforcement, isTrue);
      expect(withoutEnforcement.hasEnforcement, isFalse);
    });

    test('label reflects availability level', () {
      final scores = [
        (8, 2, 'Good availability'),
        (4, 4, 'Limited spots'), // 0.5 neutral
        (2, 8, 'Very few spots'),
        (0, 10, 'No spots reported'),
      ];
      for (final (avail, taken, label) in scores) {
        final sa = SpotAvailability(
          geohashPrefix: 'dp5dt',
          totalReports: 10,
          availableSignals: avail,
          takenSignals: taken,
          enforcementSignals: 0,
          lastUpdated: DateTime.now(),
        );
        expect(sa.label, label,
            reason: 'avail=$avail, taken=$taken should be "$label"');
      }
    });

    test('color reflects availability level', () {
      final good = SpotAvailability(
        geohashPrefix: 'dp5dt',
        totalReports: 10,
        availableSignals: 9,
        takenSignals: 1,
        enforcementSignals: 0,
        lastUpdated: DateTime.now(),
      );
      expect(good.color, equals(Colors.green));

      final bad = SpotAvailability(
        geohashPrefix: 'dp5dt',
        totalReports: 10,
        availableSignals: 0,
        takenSignals: 10,
        enforcementSignals: 0,
        lastUpdated: DateTime.now(),
      );
      expect(bad.color, equals(Colors.red));
    });
  });
}
