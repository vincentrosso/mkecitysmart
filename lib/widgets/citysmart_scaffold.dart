import 'package:flutter/material.dart';

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
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile / Sign in',
            onPressed: onProfileTap ??
                () => Navigator.pushReplacementNamed(
                      context,
                      '/auth',
                      arguments: const {'tab': 0},
                    ),
          ),
        ],
        bottom: bottom,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNav,
    );
  }
}
