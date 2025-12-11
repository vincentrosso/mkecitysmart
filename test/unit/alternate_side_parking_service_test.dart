import 'package:flutter_test/flutter_test.dart';

import 'package:mkecitysmart/services/alternate_side_parking_service.dart';

void main() {
  group('AlternateSideParkingService', () {
    test('uses day-of-year parity and special-cases Feb 29', () {
      final service = AlternateSideParkingService();

      expect(
        service.sideForDate(DateTime(2024, 2, 29)),
        ParkingSide.odd,
      );
      expect(
        service.sideForDate(DateTime(2024, 3, 1)),
        ParkingSide.even,
      );
      expect(
        service.sideForDate(DateTime(2024, 3, 2)),
        ParkingSide.odd,
      );
    });

    test('status reports switch timing and placement correctness', () {
      final fixedNow = DateTime(2024, 5, 1, 23, 10); // < 2h before midnight
      final service =
          AlternateSideParkingService(clock: () => fixedNow); // deterministic

      final status = service.status(addressNumber: 222);

      expect(status.sideToday, ParkingSide.even); // day 122 of leap year
      expect(status.sideTomorrow, ParkingSide.odd);
      expect(status.isSwitchSoon, isTrue);
      expect(status.isPlacementCorrect, isTrue); // even address on even day
      expect(
        status.nextSwitch,
        DateTime(fixedNow.year, fixedNow.month, fixedNow.day + 1),
      );
    });

    test('schedule generates consecutive days with flags', () {
      final anchor = DateTime(2024, 1, 15);
      final service = AlternateSideParkingService(clock: () => anchor);

      final days = service.schedule(days: 3);

      expect(days, hasLength(3));
      expect(days.first.isToday, isTrue);
      expect(days[1].isTomorrow, isTrue);
      expect(days.last.date.day, 17);
    });

    test('buildNotification crafts message per type and priority', () {
      final anchor = DateTime(2024, 6, 10, 8, 30);
      final service = AlternateSideParkingService(clock: () => anchor);

      final morning = service.buildNotification(
        type: NotificationType.morningReminder,
        addressNumber: 101,
      );
      expect(morning.title, contains('Morning'));
      expect(morning.priority, NotificationPriority.low);
      expect(morning.body, contains('odd-numbered side'));

      final evening = service.buildNotification(
        type: NotificationType.eveningWarning,
        addressNumber: 100, // even address on odd day => wrong side
      );
      expect(evening.priority, NotificationPriority.medium);
      expect(evening.body, contains('wrong side'));

      final midnight = service.buildNotification(
        type: NotificationType.midnightAlert,
        addressNumber: 100,
        at: DateTime(2024, 6, 10, 23, 59),
      );
      expect(midnight.priority, NotificationPriority.high);
      expect(midnight.body, contains('Move to the'));
    });
  });
}
