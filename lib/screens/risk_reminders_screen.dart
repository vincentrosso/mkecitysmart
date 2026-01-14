import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_preferences.dart';
import '../models/sighting_report.dart';
import '../providers/user_provider.dart';

class RiskRemindersScreen extends StatelessWidget {
  const RiskRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        final profile = provider.profile;
        final prefs = profile?.preferences ?? UserPreferences.defaults();
        final mutedUntil = provider.alertsMutedUntil;
        if (profile == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Risk & reminders')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Sign in to manage alerts and reminders.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/auth'),
                    child: const Text('Sign in'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Risk & reminders')),
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
                  title: const Text('Tow alerts'),
                  subtitle: const Text('Notify when tow sightings are nearby'),
                  value: prefs.towAlerts,
                  onChanged: (v) =>
                      provider.updatePreferences(towAlerts: v),
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
                                fontSize: 16, fontWeight: FontWeight.w600),
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
                        onChanged: (v) => provider.updatePreferences(
                          geoRadiusMiles: v.round(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: SwitchListTile(
                  title: const Text('Reminder notifications'),
                  subtitle: const Text('General reminders for parking tasks'),
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
                      const Text(
                        'Mute alerts',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (mutedUntil != null)
                        Text(
                          'Muted until ${mutedUntil.toLocal().toString().substring(0, 16)}',
                          style: const TextStyle(color: Colors.orange),
                        )
                      else
                        const Text(
                          'Alerts are active',
                          style: TextStyle(color: Colors.green),
                        ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () => provider.muteAlerts(
                              const Duration(hours: 1),
                            ),
                            child: const Text('Mute 1h'),
                          ),
                          OutlinedButton(
                            onPressed: () => provider.muteAlerts(
                              const Duration(hours: 4),
                            ),
                            child: const Text('Mute 4h'),
                          ),
                          OutlinedButton(
                            onPressed: () => provider.muteAlerts(
                              const Duration(hours: 8),
                            ),
                            child: const Text('Mute 8h'),
                          ),
                          if (mutedUntil != null)
                            TextButton(
                              onPressed: provider.unmuteAlerts,
                              child: const Text('Unmute'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Recent alerts',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...provider.sightings.take(5).map(
                (s) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    s.type == SightingType.towTruck
                        ? Icons.local_shipping_outlined
                        : Icons.shield_moon_outlined,
                    color: s.type == SightingType.towTruck
                        ? Colors.redAccent
                        : Colors.blueGrey,
                  ),
                  title: Text(s.location),
                  subtitle: Text(_formatAgo(s.reportedAt)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Alerts use your current location and radius. '
                'Make sure notifications are allowed in system settings.',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatAgo(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }
}
