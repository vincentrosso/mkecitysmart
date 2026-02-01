import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../theme/app_theme.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        final isLoggedIn = provider.isLoggedIn;
        final profile = provider.profile;
        final userName = profile?.name ?? 'Guest';
        final userEmail = profile?.email ?? '';
        final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'G';

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
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: isLoggedIn ? kCitySmartYellow : kCitySmartMuted,
                            child: Text(
                              userInitial,
                              style: TextStyle(
                                color: isLoggedIn ? kCitySmartGreen : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (userEmail.isNotEmpty)
                                  Text(
                                    userEmail,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: Colors.white70,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (!isLoggedIn)
                                  Text(
                                    'Tap to sign in',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: kCitySmartYellow,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'MKE CitySmart',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white54,
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
                  leading: Icon(isLoggedIn ? Icons.person : Icons.login),
                  title: Text(isLoggedIn ? 'My Profile' : 'Sign In'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      isLoggedIn ? '/profile' : '/auth',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Preferences'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/preferences');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.location_city_outlined),
                  title: const Text('City & language'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/city-settings');
                  },
                ),
                const Divider(),
                if (isLoggedIn)
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
                    onTap: () async {
                      Navigator.pop(context);
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: kCitySmartCard,
                          title: const Text('Sign out?', style: TextStyle(color: kCitySmartText)),
                          content: const Text(
                            'You can sign back in anytime.',
                            style: TextStyle(color: kCitySmartMuted),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                              child: const Text('Sign Out'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        await provider.logout();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
                        }
                      }
                    },
                  ),
                const Divider(),
              ],
            ),
          ),
        );
      },
    );
  }
}