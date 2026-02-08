import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vehicle.dart';
import '../providers/user_provider.dart';
import '../services/notification_service.dart';

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        if (provider.isInitializing) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final profile = provider.profile;
        if (profile == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Preferences')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Sign in to manage preferences.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/auth'),
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ),
          );
        }

        final prefs = profile.preferences;
        final vehicles = profile.vehicles;
        return Scaffold(
          appBar: AppBar(title: const Text('Notifications & Preferences')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: const Text('Parking notifications'),
                subtitle: const Text('Get alerts for street parking rules'),
                value: prefs.parkingNotifications,
                onChanged: (value) =>
                    provider.updatePreferences(parkingNotifications: value),
              ),
              SwitchListTile(
                title: const Text('Tow alerts'),
                subtitle: const Text('Immediate notification if towing risk'),
                value: prefs.towAlerts,
                onChanged: (value) =>
                    provider.updatePreferences(towAlerts: value),
              ),
              SwitchListTile(
                title: const Text('Reminder emails'),
                subtitle: const Text('Receive reminders for permits & sweeps'),
                value: prefs.reminderNotifications,
                onChanged: (value) =>
                    provider.updatePreferences(reminderNotifications: value),
              ),
              SwitchListTile(
                title: const Text('Ticket risk alerts'),
                subtitle: const Text(
                  'Automatic alerts when ticket risk is high',
                ),
                value: prefs.ticketRiskAlerts,
                onChanged: (value) =>
                    provider.updatePreferences(ticketRiskAlerts: value),
              ),
              SwitchListTile(
                title: const Text('Ticket due date reminders'),
                subtitle: const Text(
                  'Get reminders before ticket payment deadlines',
                ),
                value: prefs.ticketDueDateReminders,
                onChanged: (value) =>
                    provider.updatePreferences(ticketDueDateReminders: value),
              ),
              const Divider(height: 32),
              Text(
                'Alternate Side Parking Reminders',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Get notified which side of the street to park on',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              SwitchListTile(
                title: const Text('Morning reminder'),
                subtitle: const Text('Daily at 7:00 AM'),
                secondary: const Icon(Icons.wb_sunny, color: Colors.orange),
                value: prefs.aspMorningReminder,
                onChanged: (value) {
                  provider.updatePreferences(aspMorningReminder: value);
                  NotificationService.instance.syncAspNotifications(
                    morningEnabled: value,
                    eveningEnabled: prefs.aspEveningWarning,
                    midnightEnabled: prefs.aspMidnightAlert,
                  );
                },
              ),
              SwitchListTile(
                title: const Text('Evening warning'),
                subtitle: const Text('Daily at 9:00 PM (before side changes)'),
                secondary: const Icon(
                  Icons.nightlight_round,
                  color: Colors.indigo,
                ),
                value: prefs.aspEveningWarning,
                onChanged: (value) {
                  provider.updatePreferences(aspEveningWarning: value);
                  NotificationService.instance.syncAspNotifications(
                    morningEnabled: prefs.aspMorningReminder,
                    eveningEnabled: value,
                    midnightEnabled: prefs.aspMidnightAlert,
                  );
                },
              ),
              SwitchListTile(
                title: const Text('Midnight alert'),
                subtitle: const Text('At 12:00 AM when side changes'),
                secondary: const Icon(Icons.alarm, color: Colors.red),
                value: prefs.aspMidnightAlert,
                onChanged: (value) {
                  provider.updatePreferences(aspMidnightAlert: value);
                  NotificationService.instance.syncAspNotifications(
                    morningEnabled: prefs.aspMorningReminder,
                    eveningEnabled: prefs.aspEveningWarning,
                    midnightEnabled: value,
                  );
                },
              ),
              const Divider(height: 32),
              Text(
                'Alert radius (miles)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  const validRadii = [5, 10, 15, 20, 25, 30];
                  // Ensure the current value is in the list, default to 10 if not
                  final currentRadius =
                      validRadii.contains(prefs.geoRadiusMiles)
                      ? prefs.geoRadiusMiles
                      : 10;
                  return DropdownButton<int>(
                    value: currentRadius,
                    items: validRadii
                        .map(
                          (radius) => DropdownMenuItem(
                            value: radius,
                            child: Text('$radius miles'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        provider.updatePreferences(geoRadiusMiles: value),
                    isExpanded: true,
                  );
                },
              ),
              const Divider(height: 32),
              Text(
                'Default vehicle',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              vehicles.isEmpty
                  ? const Text(
                      'Add at least one vehicle to set a default for alerts.',
                    )
                  : DropdownButton<String>(
                      value:
                          prefs.defaultVehicleId ??
                          (vehicles.isNotEmpty ? vehicles.first.id : null),
                      isExpanded: true,
                      items: vehicles
                          .map(
                            (Vehicle vehicle) => DropdownMenuItem<String>(
                              value: vehicle.id,
                              child: Text(
                                vehicle.nickname.isEmpty
                                    ? vehicle.licensePlate
                                    : vehicle.nickname,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          provider.updatePreferences(defaultVehicleId: value),
                    ),
            ],
          ),
        );
      },
    );
  }
}
