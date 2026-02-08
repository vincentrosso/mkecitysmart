import 'package:flutter_test/flutter_test.dart';
import 'package:mkecitysmart/models/parking_prediction.dart';

void main() {
  group('ParkingPrediction', () {
    test('constructor stores all fields', () {
      const p = ParkingPrediction(
        id: 'pred_1',
        blockId: 'blk_water_st',
        lat: 43.038,
        lng: -87.906,
        score: 0.72,
        hour: 14,
        dayOfWeek: 3,
        eventScore: 0.1,
        weatherScore: 0.05,
      );
      expect(p.id, 'pred_1');
      expect(p.blockId, 'blk_water_st');
      expect(p.lat, closeTo(43.038, 0.001));
      expect(p.lng, closeTo(-87.906, 0.001));
      expect(p.score, 0.72);
      expect(p.hour, 14);
      expect(p.dayOfWeek, 3);
      expect(p.eventScore, 0.1);
      expect(p.weatherScore, 0.05);
    });

    test('default optional fields are zero', () {
      const p = ParkingPrediction(
        id: 'x',
        blockId: 'y',
        lat: 0,
        lng: 0,
        score: 0.5,
        hour: 8,
        dayOfWeek: 1,
      );
      expect(p.eventScore, 0.0);
      expect(p.weatherScore, 0.0);
    });

    test('toJson serializes all fields', () {
      const p = ParkingPrediction(
        id: 'pred_2',
        blockId: 'blk_broadway',
        lat: 43.04,
        lng: -87.91,
        score: 0.35,
        hour: 9,
        dayOfWeek: 5,
        eventScore: 0.2,
        weatherScore: 0.15,
      );
      final json = p.toJson();
      expect(json['id'], 'pred_2');
      expect(json['blockId'], 'blk_broadway');
      expect(json['lat'], 43.04);
      expect(json['lng'], -87.91);
      expect(json['score'], 0.35);
      expect(json['hour'], 9);
      expect(json['dayOfWeek'], 5);
      expect(json['eventScore'], 0.2);
      expect(json['weatherScore'], 0.15);
    });

    test('fromJson parses a complete map', () {
      final p = ParkingPrediction.fromJson({
        'id': 'pred_3',
        'blockId': 'blk_wisconsin',
        'lat': 43.039,
        'lng': -87.907,
        'score': 0.88,
        'hour': 17,
        'dayOfWeek': 2,
        'eventScore': 0.3,
        'weatherScore': 0.0,
      });
      expect(p.id, 'pred_3');
      expect(p.blockId, 'blk_wisconsin');
      expect(p.score, 0.88);
      expect(p.hour, 17);
      expect(p.dayOfWeek, 2);
      expect(p.eventScore, 0.3);
      expect(p.weatherScore, 0.0);
    });

    test('fromJson uses defaults when fields are missing', () {
      final p = ParkingPrediction.fromJson({});
      expect(p.id, '');
      expect(p.blockId, '');
      expect(p.lat, 0.0);
      expect(p.lng, 0.0);
      expect(p.score, 0.0);
      expect(p.hour, 0);
      expect(p.dayOfWeek, 0);
      expect(p.eventScore, 0.0);
      expect(p.weatherScore, 0.0);
    });

    test('fromJson handles integer values for doubles', () {
      final p = ParkingPrediction.fromJson({
        'id': 'int_test',
        'blockId': 'blk',
        'lat': 43,
        'lng': -88,
        'score': 1,
        'hour': 12,
        'dayOfWeek': 4,
        'eventScore': 0,
        'weatherScore': 0,
      });
      expect(p.lat, 43.0);
      expect(p.lng, -88.0);
      expect(p.score, 1.0);
    });

    test('round-trip toJson → fromJson preserves values', () {
      const original = ParkingPrediction(
        id: 'rt',
        blockId: 'blk_rt',
        lat: 43.0389,
        lng: -87.9065,
        score: 0.65,
        hour: 10,
        dayOfWeek: 6,
        eventScore: 0.4,
        weatherScore: 0.25,
      );
      final roundTripped = ParkingPrediction.fromJson(original.toJson());
      expect(roundTripped.id, original.id);
      expect(roundTripped.blockId, original.blockId);
      expect(roundTripped.lat, original.lat);
      expect(roundTripped.lng, original.lng);
      expect(roundTripped.score, original.score);
      expect(roundTripped.hour, original.hour);
      expect(roundTripped.dayOfWeek, original.dayOfWeek);
      expect(roundTripped.eventScore, original.eventScore);
      expect(roundTripped.weatherScore, original.weatherScore);
    });
  });
}
