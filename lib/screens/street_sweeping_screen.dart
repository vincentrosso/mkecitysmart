import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../providers/parking_provider.dart';
import '../models/street_sweeping.dart';
import '../citysmart/theme.dart';

class StreetSweepingScreen extends StatefulWidget {
  const StreetSweepingScreen({Key? key}) : super(key: key);

  @override
  State<StreetSweepingScreen> createState() => _StreetSweepingScreenState();
}

class _StreetSweepingScreenState extends State<StreetSweepingScreen> {
  List<StreetSweeping> _upcomingSchedules = [];
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadStreetSweepingData();
  }

  void _loadStreetSweepingData() {
    final parkingProvider = context.read<ParkingProvider>();
    final locationProvider = context.read<LocationProvider>();

    setState(() {
      _upcomingSchedules = parkingProvider.getUpcomingStreetSweeping(
        locationProvider.currentPosition?.latitude ?? 43.0389,
        locationProvider.currentPosition?.longitude ?? -87.9065,
        radius: 1.0, // 1 mile radius
      );
    });
  }

  void _toggleNotifications() {
    setState(() {
      _notificationsEnabled = !_notificationsEnabled;
    });

    if (_notificationsEnabled) {
      _scheduleNotifications();
    } else {
      _cancelNotifications();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _notificationsEnabled
              ? 'Street sweeping notifications enabled'
              : 'Street sweeping notifications disabled',
        ),
        backgroundColor: _notificationsEnabled
            ? CitySmartTheme.primaryGreen
            : Colors.grey,
      ),
    );
  }

  void _scheduleNotifications() {
    // TODO: Implement actual push notification scheduling
    // This would integrate with flutter_local_notifications
    for (var schedule in _upcomingSchedules) {
      // Schedule notification 24 hours before and 1 hour before
      print(
        'Scheduling notification for ${schedule.streetName} on ${schedule.date}',
      );
    }
  }

  void _cancelNotifications() {
    // TODO: Cancel all scheduled notifications
    print('Canceling all street sweeping notifications');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CitySmartTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Street Sweeping',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: CitySmartTheme.primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              _notificationsEnabled
                  ? Icons.notifications
                  : Icons.notifications_off,
            ),
            onPressed: _toggleNotifications,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadStreetSweepingData();
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          _notificationsEnabled
                              ? Icons.notifications_active
                              : Icons.notifications_off,
                          color: _notificationsEnabled
                              ? CitySmartTheme.primaryGreen
                              : Colors.grey,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Street Sweeping Alerts',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _notificationsEnabled
                                    ? 'You\'ll receive alerts 24 hours and 1 hour before sweeping'
                                    : 'Enable notifications to get sweeping alerts',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _notificationsEnabled,
                          onChanged: (value) => _toggleNotifications(),
                          activeColor: CitySmartTheme.primaryGreen,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Upcoming Street Sweeping',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            _upcomingSchedules.isEmpty
                ? SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.cleaning_services,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No upcoming street sweeping',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'We\'ll notify you when street sweeping is scheduled in your area',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey[500]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final schedule = _upcomingSchedules[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
                        ),
                        child: _StreetSweepingCard(schedule: schedule),
                      );
                    }, childCount: _upcomingSchedules.length),
                  ),
          ],
        ),
      ),
    );
  }
}

class _StreetSweepingCard extends StatelessWidget {
  final StreetSweeping schedule;

  const _StreetSweepingCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysUntil = schedule.date.difference(now).inDays;
    final isToday = daysUntil == 0;
    final isTomorrow = daysUntil == 1;

    Color cardColor = Colors.white;
    Color borderColor = Colors.grey.shade300;
    Color textColor = Colors.black87;

    if (isToday) {
      cardColor = Colors.red.shade50;
      borderColor = Colors.red.shade300;
      textColor = Colors.red.shade800;
    } else if (isTomorrow) {
      cardColor = Colors.orange.shade50;
      borderColor = Colors.orange.shade300;
      textColor = Colors.orange.shade800;
    } else if (daysUntil <= 3) {
      cardColor = Colors.yellow.shade50;
      borderColor = CitySmartTheme.secondaryYellow;
      textColor = Colors.orange.shade700;
    }

    String timeText = '';
    if (isToday) {
      timeText = 'Today';
    } else if (isTomorrow) {
      timeText = 'Tomorrow';
    } else if (daysUntil <= 7) {
      timeText = 'In $daysUntil days';
    } else {
      timeText =
          '${schedule.date.month}/${schedule.date.day}/${schedule.date.year}';
    }

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cleaning_services, color: textColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    schedule.streetName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    timeText,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${_formatTime(schedule.startTime)} - ${_formatTime(schedule.endTime)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${schedule.fromStreet} to ${schedule.toStreet}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            if (schedule.side != SweepingSide.both) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.compare_arrows, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${schedule.side.toString().split('.').last.toUpperCase()} side only',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
            if (daysUntil <= 1) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: borderColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: textColor, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isToday
                            ? 'Move your vehicle before ${_formatTime(schedule.startTime)} today!'
                            : 'Remember to move your vehicle tomorrow',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }
}
