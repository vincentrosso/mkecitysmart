import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import 'main_drawer.dart';

/// Shared scaffold with CitySmart app bar, drawer, and optional bottom nav.
class CitySmartScaffold extends StatelessWidget {
  const CitySmartScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showBottomNav = true,
    this.currentIndex = 0,
    this.bottom,
    this.bottomBar,
    this.onProfileTap,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBottomNav;
  final int currentIndex;
  final PreferredSizeWidget? bottom;
  final Widget? bottomBar;
  final VoidCallback? onProfileTap;

  void _onNavTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/citysmart-map');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/citysmart-feed');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget? nav;
    if (showBottomNav) {
      nav = BottomNavigationBar(
        currentIndex: currentIndex.clamp(0, 2),
        onTap: (i) => _onNavTap(context, i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_list_outlined),
            label: 'Feed',
          ),
        ],
      );
    }

    Widget? bottomNav;
    if (bottomBar != null && nav != null) {
      bottomNav = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          bottomBar!,
          nav,
        ],
      );
    } else {
      bottomNav = bottomBar ?? nav;
    }

    return Scaffold(
      drawer: const MainDrawer(),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: kCitySmartCard,
        foregroundColor: kCitySmartText,
        centerTitle: false,
        actions: [
          ...?actions,
          _ProfileButton(onProfileTap: onProfileTap),
        ],
        bottom: bottom,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNav,
    );
  }
}

/// Profile button that shows user avatar when signed in, or sign-in icon when not
class _ProfileButton extends StatelessWidget {
  const _ProfileButton({this.onProfileTap});

  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        final isLoggedIn = provider.isLoggedIn;
        final profile = provider.profile;
        final userName = profile?.name ?? '';
        final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

        if (isLoggedIn && profile != null) {
          // User is signed in - show avatar with menu
          return PopupMenuButton<String>(
            offset: const Offset(0, 45),
            tooltip: 'Account',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: kCitySmartYellow,
                    child: Text(
                      userInitial,
                      style: const TextStyle(
                        color: kCitySmartGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 80),
                    child: Text(
                      userName.split(' ').first, // First name only
                      style: const TextStyle(
                        color: kCitySmartText,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: kCitySmartMuted, size: 20),
                ],
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'profile',
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('My Profile'),
                  subtitle: Text(
                    profile.email.isNotEmpty ? profile.email : 'View & edit profile',
                    style: const TextStyle(fontSize: 12),
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              PopupMenuItem<String>(
                value: 'settings',
                child: const ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text('Preferences'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'signout',
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
            onSelected: (value) async {
              switch (value) {
                case 'profile':
                  Navigator.pushNamed(context, '/profile');
                  break;
                case 'settings':
                  Navigator.pushNamed(context, '/preferences');
                  break;
                case 'signout':
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: kCitySmartCard,
                      title: const Text('Sign out?', style: TextStyle(color: kCitySmartText)),
                      content: const Text(
                        'You can sign back in anytime to access your saved data.',
                        style: TextStyle(color: kCitySmartMuted),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                          ),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    await provider.logout();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                        (route) => false,
                      );
                    }
                  }
                  break;
              }
            },
          );
        }

        // User not signed in - show sign-in button
        return IconButton(
          icon: const Icon(Icons.person_outline),
          tooltip: 'Sign in',
          onPressed: onProfileTap ??
              () => Navigator.pushNamed(
                    context,
                    '/auth',
                  ),
        );
      },
    );
  }
}
