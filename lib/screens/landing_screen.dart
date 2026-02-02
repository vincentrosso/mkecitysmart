import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../services/risk_alert_service.dart';
import '../widgets/alternate_side_parking_card.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

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
        // Start in-app risk watcher (no-op if already running).
        RiskAlertService.instance.start(provider);
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
            title: const Text('Dashboard'),
            actions: [
              if (isGuest)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Chip(
                    label: const Text(
                      'Guest Mode',
                      style: TextStyle(fontSize: 12),
                    ),
                    avatar: const Icon(Icons.visibility_outlined, size: 16),
                    backgroundColor: const Color(0xFFE8F5E9),
                    labelStyle: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.account_circle_outlined),
                  onPressed: () => Navigator.pushNamed(context, '/profile'),
                  tooltip: 'Profile',
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Welcome Card with gradient
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF5E8A45),
                      Color(0xFF7CA726),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5E8A45).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, $name 👋',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                address,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _RiskBadge(score: provider.towRiskIndex),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.radar,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Alert radius: ${provider.profile?.preferences.geoRadiusMiles ?? 5} miles',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Alternate Side Parking Card
              const AlternateSideParkingTile(),
              
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
                    icon: Icons.badge,
                    label: 'Permit workflow',
                    value: 'Eligibility',
                    onTap: () => Navigator.pushNamed(context, '/permit-workflow'),
                  ),
                  _OverviewTile(
                    icon: Icons.insights,
                    label: 'Predictions',
                    value: 'Heatmap',
                    onTap: () => Navigator.pushNamed(context, '/predictions'),
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
                    icon: Icons.workspace_premium,
                    label: 'Plan',
                    value: 'Free/Plus/Pro',
                    onTap: () => Navigator.pushNamed(context, '/subscriptions'),
                  ),
                  _OverviewTile(
                    icon: Icons.insights,
                    label: 'Predictions',
                    value: 'Heatmap',
                    onTap: () => Navigator.pushNamed(context, '/predictions'),
                  ),
                  _OverviewTile(
                    icon: Icons.delete_outline,
                    label: 'Garbage day',
                    value: 'Schedule',
                    onTap: () => Navigator.pushNamed(context, '/garbage'),
                  ),
                  _OverviewTile(
                    icon: Icons.home_repair_service,
                    label: 'Maintenance',
                    value: 'Report',
                    onTap: () => Navigator.pushNamed(context, '/maintenance'),
                  ),
                  _OverviewTile(
                    icon: Icons.warning_amber_rounded,
                    label: 'Report sighting',
                    value: 'Tow/Enforcer',
                    onTap: () =>
                        Navigator.pushNamed(context, '/report-sighting'),
                  ),
                  _OverviewTile(
                    icon: Icons.receipt_long,
                    label: 'Tickets',
                    value: 'Lookup',
                    onTap: () => Navigator.pushNamed(context, '/tickets'),
                  ),
                  _OverviewTile(
                    icon: Icons.history_edu,
                    label: 'Receipts',
                    value: 'History',
                    onTap: () =>
                        Navigator.pushNamed(context, '/history/receipts'),
                  ),
                  _OverviewTile(
                    icon: Icons.public,
                    label: 'City & language',
                    value: 'Settings',
                    onTap: () => Navigator.pushNamed(context, '/city-settings'),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: width.clamp(150, double.infinity),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF5E8A45),
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF718096),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    Color color;
    if (score >= 70) {
      color = const Color(0xFFF56565);
    } else if (score >= 40) {
      color = const Color(0xFFED8936);
    } else {
      color = const Color(0xFF48BB78);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Risk',
                style: TextStyle(
                  color: const Color(0xFF718096),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$score',
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            score >= 70
                ? 'High'
                : score >= 40
                ? 'Moderate'
                : 'Low',
            style: TextStyle(
              color: const Color(0xFF4A5568),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
