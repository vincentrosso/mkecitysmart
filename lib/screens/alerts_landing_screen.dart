import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_preferences.dart';
import '../providers/user_provider.dart';

class AlertsLandingScreen extends StatelessWidget {
  const AlertsLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        final prefs =
            provider.profile?.preferences ?? UserPreferences.defaults();

        return Scaffold(
          appBar: AppBar(title: const Text('Alerts & reminders')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: SwitchListTile(
                  title: const Text('Parking enforcer alerts'),
                  subtitle:
                      const Text('Notify when enforcer sightings are nearby'),
                  value: prefs.parkingNotifications,
                  onChanged: (v) =>
                      provider.updatePreferences(parkingNotifications: v),
                ),
              ),
              Card(
                child: SwitchListTile(
                  title: const Text('Tow truck alerts'),
                  subtitle: const Text('Notify when tow sightings are nearby'),
                  value: prefs.towAlerts,
                  onChanged: (v) => provider.updatePreferences(towAlerts: v),
                ),
              ),
              Card(
                child: SwitchListTile(
                  title: const Text('Ticket risk alerts'),
                  subtitle: const Text('Notify when ticket risk is high'),
                  value: prefs.ticketRiskAlerts,
                  onChanged: (v) =>
                      provider.updatePreferences(ticketRiskAlerts: v),
                ),
              ),
              Card(
                child: SwitchListTile(
                  title: const Text('Reminder notifications'),
                  subtitle:
                      const Text('General reminders for parking and permits'),
                  value: prefs.reminderNotifications,
                  onChanged: (v) =>
                      provider.updatePreferences(reminderNotifications: v),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Alert radius (miles)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${prefs.geoRadiusMiles} mi',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      Slider(
                        value: prefs.geoRadiusMiles.toDouble(),
                        min: 1,
                        max: 30,
                        divisions: 29,
                        label: '${prefs.geoRadiusMiles} mi',
                        onChanged: (v) =>
                            provider.updatePreferences(geoRadiusMiles: v.round()),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Alerts use your current location and radius. Enable notifications in system settings for best results.',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        );
      },
    );
  }
}
