import 'package:intl/intl.dart';

enum ParkingSide { odd, even }

enum NotificationType {
  morningReminder,
  eveningWarning,
  midnightAlert,
}

enum NotificationPriority { low, medium, high }

class ParkingDayInfo {
  ParkingDayInfo({
    required this.date,
    required this.side,
    required this.isToday,
    required this.isTomorrow,
  });

  final DateTime date;
  final ParkingSide side;
  final bool isToday;
  final bool isTomorrow;
}

class ParkingStatus {
  ParkingStatus({
    required this.now,
    required this.sideToday,
    required this.sideTomorrow,
    required this.nextSwitch,
    required this.timeUntilSwitch,
    required this.isSwitchSoon,
    required this.isPlacementCorrect,
  });

  final DateTime now;
  final ParkingSide sideToday;
  final ParkingSide sideTomorrow;
  final DateTime nextSwitch;
  final Duration timeUntilSwitch;
  final bool isSwitchSoon;
  final bool isPlacementCorrect;
}

class NotificationMessage {
  NotificationMessage({
    required this.title,
    required this.body,
    required this.type,
    required this.priority,
  });

  final String title;
  final String body;
  final NotificationType type;
  final NotificationPriority priority;
}

class AlternateSideParkingService {
  AlternateSideParkingService({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  ParkingSide sideForDate(DateTime date) {
    // Use day-of-year parity for continuous alternation; special-case Feb 29 as odd.
    if (date.month == 2 && date.day == 29) return ParkingSide.odd;
    final ordinal = _dayOfYear(date);
    return ordinal.isOdd ? ParkingSide.odd : ParkingSide.even;
  }

  DateTime nextSwitchTime(DateTime from) {
    final midnightNextDay = DateTime(from.year, from.month, from.day + 1);
    return midnightNextDay;
  }

  ParkingStatus status({required int addressNumber}) {
    final now = _clock();
    final sideToday = sideForDate(now);
    final sideTomorrow = sideForDate(now.add(const Duration(days: 1)));
    final nextSwitch = nextSwitchTime(now);
    final timeUntil = nextSwitch.difference(now);
    final isSwitchSoon = timeUntil <= const Duration(hours: 2);
    final isPlacementCorrect = _isPlacementCorrect(
      addressNumber: addressNumber,
      side: sideToday,
    );

    return ParkingStatus(
      now: now,
      sideToday: sideToday,
      sideTomorrow: sideTomorrow,
      nextSwitch: nextSwitch,
      timeUntilSwitch: timeUntil,
      isSwitchSoon: isSwitchSoon,
      isPlacementCorrect: isPlacementCorrect,
    );
  }

  bool _isPlacementCorrect({
    required int addressNumber,
    required ParkingSide side,
  }) {
    if (addressNumber == 0) return true; // fallback for unknown addresses.
    final isOddAddress = addressNumber.isOdd;
    return side == ParkingSide.odd ? isOddAddress : !isOddAddress;
  }

  List<ParkingDayInfo> schedule({
    DateTime? start,
    int days = 14,
  }) {
    final begin = start ?? _clock();
    return List.generate(days, (index) {
      final date = DateTime(begin.year, begin.month, begin.day + index);
      return ParkingDayInfo(
        date: date,
        side: sideForDate(date),
        isToday: index == 0,
        isTomorrow: index == 1,
      );
    });
  }

  NotificationMessage buildNotification({
    required NotificationType type,
    required int addressNumber,
    DateTime? at,
  }) {
    final now = at ?? _clock();
    final side = sideForDate(now);
    final friendlySide = side == ParkingSide.odd ? 'odd-numbered side' : 'even-numbered side';
    final isCorrect = _isPlacementCorrect(addressNumber: addressNumber, side: side);
    final nextSwitch = nextSwitchTime(now);
    final switchTimeFormatted = DateFormat('MMM d, h:mm a').format(nextSwitch);

    switch (type) {
      case NotificationType.morningReminder:
        return NotificationMessage(
          title: 'Morning parking check',
          body: 'Park on the $friendlySide today. Next switch at $switchTimeFormatted.',
          type: type,
          priority: NotificationPriority.low,
        );
      case NotificationType.eveningWarning:
        final statusText = isCorrect ? 'You are on the correct side.' : 'You are on the wrong side.';
        return NotificationMessage(
          title: 'Evening parking warning',
          body: '$statusText Switch sides by midnight. Current side: $friendlySide.',
          type: type,
          priority: NotificationPriority.medium,
        );
      case NotificationType.midnightAlert:
        return NotificationMessage(
          title: 'Midnight parking reset',
          body: 'Side just flipped. Move to the ${side == ParkingSide.odd ? 'even' : 'odd'} side now.',
          type: type,
          priority: NotificationPriority.high,
        );
    }
  }
}

int _dayOfYear(DateTime date) {
  final start = DateTime(date.year, 1, 1);
  return date.difference(start).inDays + 1;
}
