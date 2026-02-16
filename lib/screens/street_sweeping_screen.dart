import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/street_sweeping.dart';
import '../providers/location_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/data_source_attribution.dart';

class StreetSweepingScreen extends StatefulWidget {
  const StreetSweepingScreen({super.key});

  @override
  State<StreetSweepingScreen> createState() => _StreetSweepingScreenState();
}

class _StreetSweepingScreenState extends State<StreetSweepingScreen> {
  final _dateFormat = DateFormat('EEE, MMM d • h:mm a');
  int _pageIndex = 0;
  bool _isLoading = false;

  Future<void> _fetchForCurrentLocation() async {
    final locationProvider = context.read<LocationProvider>();
    final userProvider = context.read<UserProvider>();
    final position = locationProvider.position;

    if (position == null) {
      setState(() => _isLoading = true);
      await locationProvider.refreshLocation();
      setState(() => _isLoading = false);
      if (!mounted) return;
      final newPos = locationProvider.position;
      if (newPos == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get your location')),
        );
        return;
      }
      await _doFetch(userProvider, newPos.latitude, newPos.longitude);
    } else {
      await _doFetch(userProvider, position.latitude, position.longitude);
    }
  }

  Future<void> _doFetch(UserProvider provider, double lat, double lng) async {
    setState(() => _isLoading = true);
    final routeCode = await provider.fetchRouteForLocation(lat: lat, lng: lng);
    setState(() => _isLoading = false);
    if (!mounted) return;
    if (routeCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No sweeping route found for this location'),
        ),
      );
    } else {
      // Show schedule entry dialog
      await _showScheduleEntryDialog(routeCode);
    }
  }

  Future<void> _showScheduleEntryDialog(String routeCode) async {
    int? selectedDay;
    List<int>? selectedWeekPattern;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Route $routeCode',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check your street signs for the sweeping schedule, then enter it below.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Sweeping Day',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final entry in {
                        1: 'Mon',
                        2: 'Tue',
                        3: 'Wed',
                        4: 'Thu',
                        5: 'Fri',
                      }.entries)
                        ChoiceChip(
                          label: Text(entry.value),
                          selected: selectedDay == entry.key,
                          onSelected: (selected) {
                            setModalState(() {
                              selectedDay = selected ? entry.key : null;
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Week Pattern',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('1st & 3rd weeks'),
                        selected:
                            selectedWeekPattern != null &&
                            selectedWeekPattern!.contains(1),
                        onSelected: (selected) {
                          setModalState(() {
                            selectedWeekPattern = selected ? [1, 3] : null;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('2nd & 4th weeks'),
                        selected:
                            selectedWeekPattern != null &&
                            selectedWeekPattern!.contains(2),
                        onSelected: (selected) {
                          setModalState(() {
                            selectedWeekPattern = selected ? [2, 4] : null;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          selectedDay != null && selectedWeekPattern != null
                          ? () => Navigator.of(context).pop(true)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A86B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Save Schedule'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == true &&
        selectedDay != null &&
        selectedWeekPattern != null &&
        mounted) {
      final provider = context.read<UserProvider>();
      final schedule = await provider.addSweepingScheduleFromUserEntry(
        broomCode: routeCode,
        sweepDay: selectedDay!,
        weekPattern: selectedWeekPattern!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Schedule saved for route ${schedule.zone}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    final schedules = provider.sweepingSchedules;
    if (schedules.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Street Sweeping')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cleaning_services_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text('No sweeping schedules configured.'),
              const SizedBox(height: 24),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: _fetchForCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Find My Schedule'),
                ),
            ],
          ),
        ),
      );
    }

    final schedule = schedules[_pageIndex.clamp(0, schedules.length - 1)];

    return Scaffold(
      backgroundColor: const Color(0xFF003E29),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003E29),
        title: const Text('Street Sweeping Alerts'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.9),
                onPageChanged: (value) => setState(() => _pageIndex = value),
                itemCount: schedules.length,
                itemBuilder: (context, index) => _SweepingCard(
                  schedule: schedules[index],
                  isActive: index == _pageIndex,
                  dateFormat: _dateFormat,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _NotificationPanel(
              schedule: schedule,
              onToggleGPS: (value) => provider.updateSweepingNotifications(
                schedule.id,
                gpsMonitoring: value,
              ),
              onToggle24h: (value) => provider.updateSweepingNotifications(
                schedule.id,
                advance24h: value,
              ),
              onToggle2h: (value) => provider.updateSweepingNotifications(
                schedule.id,
                final2h: value,
              ),
              onCustomChanged: (value) => provider.updateSweepingNotifications(
                schedule.id,
                customMinutes: value,
              ),
            ),
            const SizedBox(height: 12),
            _ParkingSuggestions(
              schedule: schedule,
              suggestions: provider.cityParkingSuggestions,
            ),
            const SizedBox(height: 12),
            _ViolationPanel(
              schedule: schedule,
              onMoved: () => provider.logVehicleMoved(schedule.id),
            ),
            const DataSourceAttribution(
              source: 'City of Milwaukee DPW (city.milwaukee.gov)',
              url:
                  'https://city.milwaukee.gov/dpw/infrastructure/Street-Maintenance/Street-Sweeping',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _fetchForCurrentLocation,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add_location),
        label: const Text('Add Location'),
        backgroundColor: const Color(0xFF00A86B),
      ),
    );
  }
}

class _SweepingCard extends StatelessWidget {
  const _SweepingCard({
    required this.schedule,
    required this.isActive,
    required this.dateFormat,
  });

  final StreetSweepingSchedule schedule;
  final bool isActive;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final hoursUntil = schedule.nextSweep.difference(DateTime.now()).inHours;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: isActive ? 8 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (isActive)
            const BoxShadow(
              color: Colors.black26,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(schedule.zone, style: Theme.of(context).textTheme.titleLarge),
          Text('Next sweep ${dateFormat.format(schedule.nextSweep)}'),
          const SizedBox(height: 12),
          Chip(
            avatar: const Icon(Icons.swap_horiz),
            label: Text('${schedule.side} • in $hoursUntil hr'),
          ),
          const Spacer(),
          Row(
            children: [
              Icon(
                schedule.gpsMonitoring ? Icons.location_on : Icons.location_off,
                color: schedule.gpsMonitoring ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                schedule.gpsMonitoring
                    ? 'GPS monitoring active'
                    : 'GPS monitoring paused',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationPanel extends StatelessWidget {
  const _NotificationPanel({
    required this.schedule,
    required this.onToggleGPS,
    required this.onToggle24h,
    required this.onToggle2h,
    required this.onCustomChanged,
  });

  final StreetSweepingSchedule schedule;
  final ValueChanged<bool> onToggleGPS;
  final ValueChanged<bool> onToggle24h;
  final ValueChanged<bool> onToggle2h;
  final ValueChanged<int> onCustomChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Multi-stage notifications',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SwitchListTile(
              value: schedule.gpsMonitoring,
              title: const Text('GPS-based monitoring'),
              subtitle: const Text(
                'Automatically detect when you park in-zone',
              ),
              onChanged: onToggleGPS,
            ),
            SwitchListTile(
              value: schedule.advance24h,
              title: const Text('24-hour warning'),
              onChanged: onToggle24h,
            ),
            SwitchListTile(
              value: schedule.final2h,
              title: const Text('2-hour final reminder'),
              onChanged: onToggle2h,
            ),
            const SizedBox(height: 8),
            Text('Custom reminder: ${schedule.customMinutes} minutes'),
            Slider(
              value: schedule.customMinutes.toDouble(),
              min: 15,
              max: 180,
              divisions: 11,
              label: '${schedule.customMinutes} min',
              onChanged: (value) => onCustomChanged(value.round()),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParkingSuggestions extends StatelessWidget {
  const _ParkingSuggestions({
    required this.schedule,
    required this.suggestions,
  });

  final StreetSweepingSchedule schedule;
  final List<String> suggestions;

  @override
  Widget build(BuildContext context) {
    final combined = {...schedule.alternativeParking, ...suggestions}.toList();
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Alternative parking',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...combined.map(
            (suggestion) => ListTile(
              leading: const Icon(Icons.local_parking),
              title: Text(suggestion),
              trailing: const Icon(Icons.navigation),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViolationPanel extends StatelessWidget {
  const _ViolationPanel({required this.schedule, required this.onMoved});

  final StreetSweepingSchedule schedule;
  final VoidCallback onMoved;

  @override
  Widget build(BuildContext context) {
    final goal = 30;
    final double progress = (schedule.cleanStreakDays / goal).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Violation prevention',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
            Text(
              '${schedule.cleanStreakDays} clean days • ${schedule.violationsPrevented} avoided tickets',
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onMoved,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Mark vehicle moved'),
            ),
          ],
        ),
      ),
    );
  }
}
