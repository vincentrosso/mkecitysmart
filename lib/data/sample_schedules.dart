import '../models/garbage_schedule.dart';

List<GarbageSchedule> sampleSchedules(String address) {
  final now = DateTime.now();
  DateTime nextWeekday(DateTime from, int weekday) {
    final daysToAdd = (weekday - from.weekday + 7) % 7;
    return from.add(Duration(days: daysToAdd == 0 ? 7 : daysToAdd));
  }

  return [
    GarbageSchedule(
      routeId: 'R1',
      address: address,
      pickupDate: nextWeekday(now, DateTime.monday).add(const Duration(hours: 6)),
      type: PickupType.garbage,
    ),
    GarbageSchedule(
      routeId: 'R2',
      address: address,
      pickupDate: nextWeekday(now, DateTime.thursday).add(const Duration(hours: 6)),
      type: PickupType.recycling,
    ),
  ];
}
