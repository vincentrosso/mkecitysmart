import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';

import '../models/garbage_schedule.dart';
import '../providers/user_provider.dart';
import '../services/garbage_schedule_service.dart';
import '../services/location_service.dart';

class GarbageScheduleScreen extends StatefulWidget {
  const GarbageScheduleScreen({super.key});

  @override
  State<GarbageScheduleScreen> createState() => _GarbageScheduleScreenState();
}

class _GarbageScheduleScreenState extends State<GarbageScheduleScreen> {
  final _addressController = TextEditingController(text: '1234 E Sample St');
  bool _nightBefore = true;
  bool _morningOf = true;
  String _language = 'en';
  bool _loading = false;
  String? _error;
  late final GarbageScheduleService _service;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        final schedules = provider.garbageSchedules;
        return Scaffold(
          appBar: AppBar(title: const Text('Garbage & recycling')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Address',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Enter address to match route',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _useLocation,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Use my location'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _useAddress,
                      icon: const Icon(Icons.search),
                      label: const Text('Search by address'),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.orangeAccent),
                ),
              ],
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Smart reminders',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SwitchListTile(
                        title: const Text('Night before'),
                        value: _nightBefore,
                        onChanged: (value) => setState(() => _nightBefore = value),
                      ),
                      SwitchListTile(
                        title: const Text('Morning of'),
                        value: _morningOf,
                        onChanged: (value) => setState(() => _morningOf = value),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _language,
                        decoration: const InputDecoration(labelText: 'Language'),
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text('English')),
                          DropdownMenuItem(value: 'zh', child: Text('中文')),
                          DropdownMenuItem(value: 'fr', child: Text('Français')),
                          DropdownMenuItem(value: 'hi', child: Text('हिन्दी')),
                          DropdownMenuItem(value: 'el', child: Text('Ελληνικά')),
                        ],
                        onChanged: (value) => setState(() => _language = value ?? 'en'),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () {
                          provider.scheduleGarbageReminders(
                            nightBefore: _nightBefore
                                ? const Duration(hours: 12)
                                : const Duration(hours: 0),
                            morningOf: _morningOf
                                ? const Duration(hours: 2)
                                : const Duration(hours: 0),
                            languageCode: _language,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reminders scheduled.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.notifications_active),
                    label: const Text('Schedule reminders'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Upcoming pickups (${schedules.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
              const SizedBox(height: 8),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (schedules.isEmpty)
                const Text('No upcoming pickups found.')
              else
                ...schedules.map(
                  (s) => Card(
                    child: ListTile(
                      leading: Icon(
                        s.type == PickupType.garbage
                            ? Icons.delete
                            : Icons.recycling,
                      ),
                      title: Text(
                        '${s.type == PickupType.garbage ? 'Garbage' : 'Recycling'} • ${s.pickupDate.month}/${s.pickupDate.day} ${s.pickupDate.hour.toString().padLeft(2, '0')}:00',
                      ),
                      subtitle: Text('Route ${s.routeId} • ${s.address}'),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _service = GarbageScheduleService(
      baseUrl: 'https://itmdapps.milwaukee.gov/DPWServletsPublic/garbage_day',
    );
  }

  Future<void> _useLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final loc = await LocationService().getCurrentPosition();
      if (loc == null) {
        setState(() {
          _error = 'Location unavailable.';
          _loading = false;
        });
        return;
      }
      final placemarks = await placemarkFromCoordinates(
        loc.latitude,
        loc.longitude,
      );
      final street = placemarks.isNotEmpty ? placemarks.first.street : null;
      if (street == null || street.isEmpty) {
        setState(() {
          _error = 'Could not resolve your address from location.';
          _loading = false;
        });
        return;
      }
      _addressController.text = street;
      final schedules = await _service.fetchByAddress(street);
      if (!mounted) return;
      await context.read<UserProvider>().setGarbageSchedules(schedules);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error =
              'Failed to load schedule. Please retry or enter an address. Details: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _useAddress() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final addr = _addressController.text.trim();
      final schedules = await _service.fetchByAddress(addr);
      if (!mounted) return;
      await context.read<UserProvider>().setGarbageSchedules(schedules);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load schedule: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }
}
