import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: kCitySmartCard),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MKE CitySmart',
                    style: textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'MKE CitySmart tools',
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/dashboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile / Sign in'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(
                  context,
                  '/auth',
                  arguments: const {'tab': 0},
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Preferences'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/preferences');
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_city_outlined),
              title: const Text('City & language'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/locale');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out / Guest'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/guest');
              },
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }
}