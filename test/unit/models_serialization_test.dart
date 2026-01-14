import 'package:flutter_test/flutter_test.dart';
import 'package:mkecitysmart/models/ad_preferences.dart';
import 'package:mkecitysmart/models/city_rule_pack.dart';
import 'package:mkecitysmart/models/maintenance_report.dart';
import 'package:mkecitysmart/models/payment_receipt.dart';
import 'package:mkecitysmart/models/permit.dart';
import 'package:mkecitysmart/models/reservation.dart';
import 'package:mkecitysmart/models/sighting_report.dart';
import 'package:mkecitysmart/models/street_sweeping.dart';
import 'package:mkecitysmart/models/subscription_plan.dart';
import 'package:mkecitysmart/models/ticket.dart';
import 'package:mkecitysmart/models/user_preferences.dart';
import 'package:mkecitysmart/models/vehicle.dart';
import 'package:mkecitysmart/models/garbage_schedule.dart';

void main() {
  group('Model serialization', () {
    test('AdPreferences toggles and serializes', () {
      const prefs = AdPreferences(
        showParkingAds: false,
        showInsuranceAds: true,
        showMaintenanceAds: true,
        showLocalDeals: false,
      );
      final json = prefs.toJson();
      final from = AdPreferences.fromJson(json);

      expect(from.showParkingAds, isFalse);
      expect(from.showInsuranceAds, isTrue);
      expect(from.showMaintenanceAds, isTrue);
      expect(from.showLocalDeals, isFalse);
      expect(prefs.copyWith(showParkingAds: true).showParkingAds, isTrue);
    });

    test('CityRulePack holds limits', () {
      const pack = CityRulePack(
        cityId: 'mke',
        displayName: 'Milwaukee',
        maxVehicles: 3,
        defaultAlertRadius: 4,
        quotaRequestsPerHour: 10,
        rateLimitPerMinute: 2,
      );
      expect(pack.maxVehicles, 3);
      expect(pack.defaultAlertRadius, 4);
    });

    test('MaintenanceReport round-trips json', () {
      final now = DateTime(2024, 3, 1, 12);
      final report = MaintenanceReport(
        id: 'r1',
        category: MaintenanceCategory.streetlight,
        description: 'Out lamp',
        location: '123 Main',
        createdAt: now,
        latitude: 1.0,
        longitude: 2.0,
        photoPath: '/tmp/photo.jpg',
        department: 'Lights',
        status: 'In Progress',
      );
      final from = MaintenanceReport.fromJson(report.toJson());
      expect(from.category, MaintenanceCategory.streetlight);
      expect(from.department, 'Lights');
      expect(from.latitude, 1.0);
      expect(from.status, 'In Progress');
    });

    test('PaymentReceipt round-trips and retains amounts', () {
      final receipt = PaymentReceipt(
        id: 'p1',
        amountCharged: 20.5,
        waivedAmount: 2.0,
        method: 'card',
        reference: 'ref123',
        createdAt: DateTime(2024, 2, 1),
        description: 'Test',
        category: 'tickets',
      );
      final from = PaymentReceipt.fromJson(receipt.toJson());
      expect(from.amountCharged, 20.5);
      expect(from.waivedAmount, 2.0);
      expect(from.category, 'tickets');
    });

    test('Permit exposes helpers and json', () {
      final start = DateTime(2024, 1, 1);
      final end = DateTime.now().add(const Duration(days: 2));
      final permit = Permit(
        id: 'permit1',
        type: PermitType.residential,
        status: PermitStatus.active,
        zone: 'A',
        startDate: start,
        endDate: end,
        vehicleIds: const ['v1'],
        qrCodeData: 'qr',
        offlineAccess: true,
        autoRenew: true,
      );
      expect(permit.isExpiringSoon, isTrue);
      final from = Permit.fromJson(permit.toJson());
      expect(from.type, PermitType.residential);
      expect(from.offlineAccess, isTrue);
      expect(from.autoRenew, isTrue);
    });

    test('Reservation durations and totals', () {
      final start = DateTime(2024, 1, 1, 10);
      final end = DateTime(2024, 1, 1, 12, 30);
      final res = Reservation(
        id: 'res1',
        spotId: 'S1',
        location: 'Garage',
        status: ReservationStatus.reserved,
        startTime: start,
        endTime: end,
        ratePerHour: 4,
        vehiclePlate: 'ABC123',
        paymentMethod: 'card',
        transactionId: 't1',
        totalPaid: 10,
      );
      expect(res.duration.inMinutes, 150);
      expect(res.calculatedTotal, closeTo(10.0, 0.01));
      final updated = res.copyWith(status: ReservationStatus.completed);
      expect(updated.status, ReservationStatus.completed);
      final from = Reservation.fromJson(res.toJson());
      expect(from.location, 'Garage');
    });

    test('SightingReport serialization', () {
      final report = SightingReport(
        id: 's1',
        type: SightingType.towTruck,
        location: 'Main St',
        latitude: 1.0,
        longitude: 2.0,
        notes: 'Tow spotted',
        reportedAt: DateTime(2024, 1, 1),
        occurrences: 2,
      );
      final json = report.toJson();
      final from = SightingReport.fromJson(json);
      expect(from.type, SightingType.towTruck);
      expect(from.occurrences, 2);
      expect(from.location, 'Main St');
    });

    test('StreetSweepingSchedule copyWith and json', () {
      final schedule = StreetSweepingSchedule(
        id: 'ss1',
        zone: 'Z1',
        side: 'Odd',
        nextSweep: DateTime(2024, 4, 1),
        gpsMonitoring: true,
        advance24h: true,
        final2h: false,
        customMinutes: 90,
        alternativeParking: const ['Lot A'],
        cleanStreakDays: 3,
        violationsPrevented: 5,
      );
      final updated = schedule.copyWith(final2h: true, customMinutes: 30);
      expect(updated.final2h, isTrue);
      expect(updated.customMinutes, 30);
      final from = StreetSweepingSchedule.fromJson(schedule.toJson());
      expect(from.zone, 'Z1');
      expect(from.alternativeParking, contains('Lot A'));
    });

    test('SubscriptionPlan exposes limits', () {
      const plan = SubscriptionPlan(
        tier: SubscriptionTier.pro,
        maxAlertRadiusMiles: 15,
        alertVolumePerDay: 20,
        zeroProcessingFee: true,
        prioritySupport: true,
        monthlyPrice: 14.99,
      );
      expect(plan.prioritySupport, isTrue);
      expect(plan.label, 'Pro');
    });

    test('Ticket helpers and json', () {
      final due = DateTime.now().subtract(const Duration(days: 1));
      final ticket = Ticket(
        id: 't1',
        plate: 'ABC123',
        amount: 50,
        reason: 'Violation',
        location: 'Main St',
        issuedAt: DateTime(2024, 1, 1),
        dueDate: due,
        status: TicketStatus.open,
      );
      expect(ticket.isOverdue, isTrue);
      final paid = ticket.copyWith(
        status: TicketStatus.paid,
        paidAt: DateTime(2024, 1, 2),
        paymentMethod: 'card',
      );
      expect(paid.status, TicketStatus.paid);
      final from = Ticket.fromJson(ticket.toJson());
      expect(from.reason, 'Violation');
    });

    test('UserPreferences defaults and copy', () {
      final prefs = UserPreferences.defaults();
      expect(prefs.parkingNotifications, isTrue);
      final updated = prefs.copyWith(
        parkingNotifications: false,
        geoRadiusMiles: 10,
        defaultVehicleId: 'v1',
      );
      expect(updated.parkingNotifications, isFalse);
      expect(updated.geoRadiusMiles, 10);
      final from = UserPreferences.fromJson(updated.toJson());
      expect(from.defaultVehicleId, 'v1');
    });

    test('Vehicle json and defaults', () {
      final vehicle = Vehicle(
        id: 'v1',
        make: 'Tesla',
        model: 'Model 3',
        licensePlate: 'EV123',
        color: 'Blue',
        nickname: 'Daily',
      );
      final from = Vehicle.fromJson(vehicle.toJson());
      expect(from.licensePlate, 'EV123');
      expect(from.nickname, 'Daily');
    });

    test('GarbageSchedule serialization', () {
      final schedule = GarbageSchedule(
        routeId: 'R1',
        address: '123 Main',
        pickupDate: DateTime.now().add(const Duration(days: 3)),
        type: PickupType.garbage,
      );
      expect(schedule.isPast, isFalse);
    });
  });
}
