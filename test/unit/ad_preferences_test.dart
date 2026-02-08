import 'package:flutter_test/flutter_test.dart';
import 'package:mkecitysmart/models/ad_preferences.dart';

void main() {
  group('AdPreferences', () {
    test('default constructor has sensible defaults', () {
      const prefs = AdPreferences();
      expect(prefs.showParkingAds, isTrue);
      expect(prefs.showInsuranceAds, isFalse);
      expect(prefs.showMaintenanceAds, isFalse);
      expect(prefs.showLocalDeals, isTrue);
    });

    test('copyWith overrides specified fields only', () {
      const original = AdPreferences();
      final modified = original.copyWith(
        showInsuranceAds: true,
        showLocalDeals: false,
      );
      expect(modified.showParkingAds, isTrue); // unchanged
      expect(modified.showInsuranceAds, isTrue); // changed
      expect(modified.showMaintenanceAds, isFalse); // unchanged
      expect(modified.showLocalDeals, isFalse); // changed
    });

    test('toJson serializes all fields', () {
      const prefs = AdPreferences(
        showParkingAds: false,
        showInsuranceAds: true,
        showMaintenanceAds: true,
        showLocalDeals: false,
      );
      final json = prefs.toJson();
      expect(json['showParkingAds'], isFalse);
      expect(json['showInsuranceAds'], isTrue);
      expect(json['showMaintenanceAds'], isTrue);
      expect(json['showLocalDeals'], isFalse);
    });

    test('fromJson deserializes all fields', () {
      final prefs = AdPreferences.fromJson({
        'showParkingAds': false,
        'showInsuranceAds': true,
        'showMaintenanceAds': true,
        'showLocalDeals': false,
      });
      expect(prefs.showParkingAds, isFalse);
      expect(prefs.showInsuranceAds, isTrue);
      expect(prefs.showMaintenanceAds, isTrue);
      expect(prefs.showLocalDeals, isFalse);
    });

    test('fromJson uses defaults when fields are missing', () {
      final prefs = AdPreferences.fromJson({});
      expect(prefs.showParkingAds, isTrue);
      expect(prefs.showInsuranceAds, isFalse);
      expect(prefs.showMaintenanceAds, isFalse);
      expect(prefs.showLocalDeals, isTrue);
    });

    test('round-trip toJson → fromJson preserves values', () {
      const original = AdPreferences(
        showParkingAds: true,
        showInsuranceAds: true,
        showMaintenanceAds: false,
        showLocalDeals: false,
      );
      final roundTripped = AdPreferences.fromJson(original.toJson());
      expect(roundTripped.showParkingAds, original.showParkingAds);
      expect(roundTripped.showInsuranceAds, original.showInsuranceAds);
      expect(roundTripped.showMaintenanceAds, original.showMaintenanceAds);
      expect(roundTripped.showLocalDeals, original.showLocalDeals);
    });
  });
}
