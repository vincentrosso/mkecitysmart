import 'package:add_2_calendar/add_2_calendar.dart';

import '../models/garbage_schedule.dart';

/// Service for adding garbage/recycling pickup events to the system calendar
class CalendarService {
  CalendarService._();
  static final CalendarService instance = CalendarService._();

  /// Add a garbage pickup event to the system calendar
  Future<bool> addGarbagePickupToCalendar(GarbageSchedule schedule) async {
    final typeLabel = schedule.type == PickupType.garbage ? 'Garbage' : 'Recycling';
    final pickupTime = schedule.pickupDate;
    
    final event = Event(
      title: '🚛 $typeLabel Pickup - Route ${schedule.routeId}',
      description: 'Put out your $typeLabel bins before the truck arrives.\n'
          'Address: ${schedule.address}\n'
          'Route: ${schedule.routeId}',
      location: schedule.address,
      startDate: pickupTime.subtract(const Duration(hours: 1)),
      endDate: pickupTime,
      allDay: false,
      iosParams: const IOSParams(
        reminder: Duration(hours: 12), // Night before reminder
      ),
      androidParams: const AndroidParams(
        emailInvites: [],
      ),
    );

    return Add2Calendar.addEvent2Cal(event);
  }

  /// Add multiple garbage pickup events to the calendar
  Future<void> addAllPickupsToCalendar(List<GarbageSchedule> schedules) async {
    for (final schedule in schedules) {
      if (schedule.pickupDate.isAfter(DateTime.now())) {
        await addGarbagePickupToCalendar(schedule);
      }
    }
  }
}
