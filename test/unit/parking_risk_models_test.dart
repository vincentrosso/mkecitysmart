import 'package:flutter_test/flutter_test.dart';
import 'package:mkecitysmart/services/parking_risk_service.dart';

void main() {
  group('RiskLevel', () {
    test('fromString parses "high"', () {
      expect(RiskLevel.fromString('high'), RiskLevel.high);
      expect(RiskLevel.fromString('HIGH'), RiskLevel.high);
      expect(RiskLevel.fromString('High'), RiskLevel.high);
    });

    test('fromString parses "medium"', () {
      expect(RiskLevel.fromString('medium'), RiskLevel.medium);
      expect(RiskLevel.fromString('Medium'), RiskLevel.medium);
    });

    test('fromString defaults to low for unrecognized or null', () {
      expect(RiskLevel.fromString('low'), RiskLevel.low);
      expect(RiskLevel.fromString('unknown'), RiskLevel.low);
      expect(RiskLevel.fromString(null), RiskLevel.low);
      expect(RiskLevel.fromString(''), RiskLevel.low);
    });
  });

  group('RiskZone.fromMap', () {
    test('parses a complete map', () {
      final zone = RiskZone.fromMap({
        'geohash': 'dp5xyz',
        'lat': 43.038,
        'lng': -87.906,
        'riskScore': 72,
        'riskLevel': 'high',
        'totalCitations': 150,
      });

      expect(zone.geohash, 'dp5xyz');
      expect(zone.lat, closeTo(43.038, 0.001));
      expect(zone.lng, closeTo(-87.906, 0.001));
      expect(zone.riskScore, 72);
      expect(zone.riskLevel, RiskLevel.high);
      expect(zone.totalCitations, 150);
    });

    test('uses defaults for missing fields', () {
      final zone = RiskZone.fromMap({});
      expect(zone.geohash, '');
      expect(zone.lat, 0.0);
      expect(zone.lng, 0.0);
      expect(zone.riskScore, 0);
      expect(zone.riskLevel, RiskLevel.low);
      expect(zone.totalCitations, 0);
    });

    test('handles integer lat/lng', () {
      final zone = RiskZone.fromMap({
        'geohash': 'abc',
        'lat': 43,
        'lng': -88,
        'riskScore': 10,
        'riskLevel': 'low',
        'totalCitations': 5,
      });
      expect(zone.lat, 43.0);
      expect(zone.lng, -88.0);
    });
  });

  group('LocationRisk.fromMap', () {
    test('parses a full response including hourlyRisk', () {
      final risk = LocationRisk.fromMap({
        'riskScore': 85,
        'riskLevel': 'high',
        'riskPercentage': 85,
        'message': 'High citation activity in this area',
        'hourlyRisk': {'currentHour': 14, 'hourlyMultiplier': 1.5},
        'peakHours': [8, 12, 17],
        'topViolations': ['expired_meter', 'no_parking'],
        'totalCitations': 300,
      });

      expect(risk.riskScore, 85);
      expect(risk.riskLevel, RiskLevel.high);
      expect(risk.riskPercentage, 85);
      expect(risk.message, 'High citation activity in this area');
      expect(risk.currentHour, 14);
      expect(risk.hourlyMultiplier, 1.5);
      expect(risk.peakHours, [8, 12, 17]);
      expect(risk.topViolations, ['expired_meter', 'no_parking']);
      expect(risk.totalCitations, 300);
    });

    test('handles missing optional fields', () {
      final risk = LocationRisk.fromMap({
        'riskScore': 20,
        'riskLevel': 'low',
        'riskPercentage': 20,
        'message': 'Low risk',
        'totalCitations': 10,
      });

      expect(risk.currentHour, isNull);
      expect(risk.hourlyMultiplier, isNull);
      expect(risk.peakHours, isEmpty);
      expect(risk.topViolations, isEmpty);
    });

    test('handles completely empty map gracefully', () {
      final risk = LocationRisk.fromMap({});
      expect(risk.riskScore, 0);
      expect(risk.riskLevel, RiskLevel.low);
      expect(risk.riskPercentage, 0);
      expect(risk.message, '');
      expect(risk.totalCitations, 0);
    });
  });

  group('LocationRisk.colorValue', () {
    test('returns red for high risk', () {
      final risk = LocationRisk.fromMap({
        'riskScore': 90,
        'riskLevel': 'high',
        'riskPercentage': 90,
        'message': 'High',
        'totalCitations': 100,
      });
      expect(risk.colorValue, 0xFFE53935);
    });

    test('returns orange for medium risk', () {
      final risk = LocationRisk.fromMap({
        'riskScore': 50,
        'riskLevel': 'medium',
        'riskPercentage': 50,
        'message': 'Medium',
        'totalCitations': 50,
      });
      expect(risk.colorValue, 0xFFFFA726);
    });

    test('returns green for low risk', () {
      final risk = LocationRisk.fromMap({
        'riskScore': 10,
        'riskLevel': 'low',
        'riskPercentage': 10,
        'message': 'Low',
        'totalCitations': 5,
      });
      expect(risk.colorValue, 0xFF66BB6A);
    });
  });

  group('ParkingRiskService.formatRiskNotification', () {
    test('formats notification with violations and peak hours', () {
      final risk = LocationRisk.fromMap({
        'riskScore': 75,
        'riskLevel': 'high',
        'riskPercentage': 75,
        'message': 'Busy area',
        'peakHours': [8, 12, 17],
        'topViolations': ['expired_meter'],
        'totalCitations': 200,
      });

      final msg = ParkingRiskService.formatRiskNotification(risk);
      expect(msg, contains('HIGH RISK'));
      expect(msg, contains('75%'));
      expect(msg, contains('Busy area'));
      expect(msg, contains('expired meter'));
      expect(msg, contains('8:00'));
    });

    test('formats notification without violations or peak hours', () {
      final risk = LocationRisk.fromMap({
        'riskScore': 10,
        'riskLevel': 'low',
        'riskPercentage': 10,
        'message': 'Safe zone',
        'totalCitations': 2,
      });

      final msg = ParkingRiskService.formatRiskNotification(risk);
      expect(msg, contains('LOW RISK'));
      expect(msg, contains('10%'));
      expect(msg, contains('Safe zone'));
      expect(msg, isNot(contains('Watch for')));
      expect(msg, isNot(contains('Peak times')));
    });
  });
}
