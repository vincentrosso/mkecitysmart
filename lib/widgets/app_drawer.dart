import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF003E29),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF003E29)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_city, color: Colors.white, size: 40),
                SizedBox(height: 16),
                Text(
                  'CitySmart Parking App',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Milwaukee, WI',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.dashboard,
            title: 'Dashboard',
            route: '/landing',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.local_parking,
            title: 'Find Parking',
            route: '/parking',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.credit_card,
            title: 'Permits',
            route: '/permits',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.cleaning_services,
            title: 'Street Sweeping',
            route: '/street-sweeping',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.history,
            title: 'History',
            route: '/history',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.payment,
            title: 'Payment & Billing',
            route: '/payment',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.notifications,
            title: 'Notifications',
            route: '/notifications',
          ),
          const Divider(color: Colors.white24),
          _buildDrawerItem(
            context,
            icon: Icons.person,
            title: 'Profile',
            route: '/profile',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.settings,
            title: 'Settings',
            route: '/settings',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.brush_outlined,
            title: 'Branding Preview',
            route: '/branding',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    final currentLocation = GoRouterState.of(context).uri.toString();
    final isSelected =
        currentLocation == route ||
        (route != '/' && currentLocation.startsWith(route));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: isSelected ? const Color(0xFF006A3B) : null,
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          context.go(route);
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    );
  }
}
