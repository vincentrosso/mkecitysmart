import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vehicle.dart';
import '../providers/user_provider.dart';

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
                subtitle: const Text('Automatic alerts when ticket risk is high'),
                value: prefs.ticketRiskAlerts,
                onChanged: (value) =>
                    provider.updatePreferences(ticketRiskAlerts: value),
              ),
              const Divider(height: 32),
              Text(
                'Alert radius (miles)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              DropdownButton<int>(
                value: prefs.geoRadiusMiles,
                items: const [5, 10, 15, 20, 25, 30]
                    .map(
                      (radius) => DropdownMenuItem(
                        value: radius,
                        child: Text('$radius miles'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => provider.updatePreferences(
                  geoRadiusMiles: value,
                ),
                isExpanded: true,
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
