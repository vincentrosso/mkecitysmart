import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';

class LandingScreen extends StatelessWidget {
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
        final isGuest = provider.isGuest;
        if (!isGuest && profile == null) {
          return Scaffold(
            backgroundColor: const Color(0xFF203731),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Please sign in to view your dashboard.',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/auth'),
                    child: const Text('Sign in'),
                  ),
                ],
              ),
            ),
          );
        }

        final vehicles = profile?.vehicles ?? const [];
        final name = profile?.name.split(' ').first ?? 'Guest';
        final address =
            profile?.address?.isNotEmpty == true
                ? profile!.address!
                : isGuest
                ? 'Exploring in guest mode. Sign in to personalize alerts.'
                : 'Set your address for hyper-local alerts.';
        final alertsLabel = isGuest
            ? 'Preview'
            : (profile?.preferences.parkingNotifications ?? false
                ? 'Enabled'
                : 'Muted');
        return Scaffold(
          appBar: AppBar(
            title: const Text('CitySmart Dashboard'),
            backgroundColor: const Color(0xFF203731),
            actions: [
              if (isGuest)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Chip(
                    label: const Text('Guest'),
                    avatar: const Icon(Icons.visibility_outlined, size: 18),
                    backgroundColor: Colors.white,
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: () => Navigator.pushNamed(context, '/profile'),
                ),
            ],
          ),
          backgroundColor: const Color(0xFF203731),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: const Color(0xFF003E29),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $name',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        address,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _OverviewTile(
                    icon: Icons.directions_car,
                    label: 'Vehicles',
                    value: vehicles.length.toString(),
                    onTap: () => Navigator.pushNamed(context, '/vehicles'),
                  ),
                  _OverviewTile(
                    icon: Icons.notifications_active_outlined,
                    label: 'Alerts',
                    value: alertsLabel,
                    onTap: () => Navigator.pushNamed(context, '/preferences'),
                  ),
                  _OverviewTile(
                    icon: Icons.electric_bolt,
                    label: 'EV charging',
                    value: 'Map',
                    onTap: () => Navigator.pushNamed(context, '/charging'),
                  ),
                  _OverviewTile(
                    icon: Icons.history,
                    label: 'History',
                    value: 'View',
                    onTap: () => Navigator.pushNamed(context, '/history'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Profile & settings'),
                      subtitle: Text(
                        isGuest
                            ? 'Sign in to save preferences'
                            : profile!.email,
                      ),
                      onTap: () {
                        if (isGuest) {
                          Navigator.pushReplacementNamed(context, '/auth');
                        } else {
                          Navigator.pushNamed(context, '/profile');
                        }
                      },
                    ),
                    const Divider(height: 0),
                    ListTile(
                      leading: const Icon(Icons.directions_car_filled),
                      title: const Text('Vehicle garage'),
                      subtitle: Text('${vehicles.length} vehicle(s) connected'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(context, '/vehicles'),
                    ),
                    const Divider(height: 0),
                    ListTile(
                      leading: const Icon(Icons.settings_suggest_outlined),
                      title: const Text('Notification preferences'),
                      subtitle: const Text('Customize tow alerts & reminders'),
                      onTap: () => Navigator.pushNamed(context, '/preferences'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OverviewTile extends StatelessWidget {
  const _OverviewTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 40) / 2;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width.clamp(150, double.infinity),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D4D3A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
