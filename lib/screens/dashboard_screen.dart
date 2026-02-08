import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../services/location_service.dart';
import '../services/parking_risk_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ad_widgets.dart';
import '../widgets/citysmart_scaffold.dart';
import '../widgets/crowdsource_widgets.dart';
import 'alerts_landing_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  LocationRisk? _locationRisk;
  bool _loadingRisk = true;
  bool _hasBeenBackgrounded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRiskData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App went to background
      _hasBeenBackgrounded = true;
      debugPrint('Dashboard: App went to background');
    } else if (state == AppLifecycleState.resumed && _hasBeenBackgrounded) {
      // App came back from background - show welcome back
      _hasBeenBackgrounded = false;
      debugPrint('Dashboard: App resumed from background');
      _showWelcomeBack();
    }
  }

  void _showWelcomeBack() {
    final userProvider = context.read<UserProvider>();

    // Show welcome if user is logged in (not a guest)
    if (userProvider.isLoggedIn && !userProvider.isGuest) {
      final name = userProvider.profile?.name;
      final greeting = name != null && name.isNotEmpty
          ? 'Welcome back, $name!'
          : 'Welcome back!';

      debugPrint('Dashboard: Showing welcome message: $greeting');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.waving_hand, color: Colors.amber),
              const SizedBox(width: 12),
              Expanded(child: Text(greeting)),
            ],
          ),
          backgroundColor: kCitySmartGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _loadRiskData() async {
    // Default to downtown Milwaukee if location unavailable
    double lat = 43.0389;
    double lng = -87.9065;

    try {
      final loc = await LocationService().getCurrentPosition().timeout(
        const Duration(seconds: 8),
      );
      if (loc != null) {
        lat = loc.latitude;
        lng = loc.longitude;
        debugPrint('Dashboard: Using device location: $lat, $lng');
      } else {
        debugPrint('Dashboard: Location unavailable, using default Milwaukee');
      }
    } catch (e) {
      debugPrint('Dashboard: Location error: $e, using default Milwaukee');
    }

    try {
      final risk = await ParkingRiskService.instance.getRiskForLocation(
        lat,
        lng,
      );
      if (mounted) {
        setState(() {
          _locationRisk = risk;
          _loadingRisk = false;
        });
      }
    } catch (e) {
      debugPrint('Dashboard: Risk load error: $e');
      if (mounted) setState(() => _loadingRisk = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Watch the provider for reactive updates
    context.watch<UserProvider>();

    return CitySmartScaffold(
      title: 'MKE CitySmart',
      currentIndex: 0,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard', style: textTheme.headlineMedium),
            const SizedBox(height: 12),
            // Risk Badge Card
            if (_loadingRisk)
              const _RiskBadgeCardLoading()
            else if (_locationRisk != null)
              _RiskBadgeCard(risk: _locationRisk!)
            else
              _RiskBadgeCardError(onRetry: _loadRiskData),
            const SizedBox(height: 12),
            // Live crowdsource parking availability + report button
            const CrowdsourceAvailabilityBanner(),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  HomeTile(
                    icon: Icons.local_parking,
                    title: 'Overview',
                    onTap: () => Navigator.pushNamed(context, '/parking'),
                  ),
                  HomeTile(
                    icon: Icons.delete_outline,
                    title: 'Garbage Day',
                    onTap: () => Navigator.pushNamed(context, '/garbage'),
                  ),
                  HomeTile(
                    icon: Icons.compare_arrows,
                    title: 'Alt-side parking',
                    subtitle: 'Odd/Even side',
                    onTap: () =>
                        Navigator.pushNamed(context, '/alternate-parking'),
                  ),
                  HomeTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'Risk & reminders',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AlertsLandingScreen(),
                      ),
                    ),
                  ),
                  HomeTile(
                    icon: Icons.map,
                    title: 'Parking heatmap',
                    onTap: () =>
                        Navigator.pushNamed(context, '/parking-heatmap'),
                  ),
                  HomeTile(
                    icon: Icons.warning_amber_rounded,
                    title: 'Report sighting',
                    onTap: () =>
                        Navigator.pushNamed(context, '/report-sighting'),
                  ),
                  HomeTile(
                    icon: Icons.receipt_long,
                    title: 'My tickets',
                    onTap: () =>
                        Navigator.pushNamed(context, '/ticket-tracker'),
                  ),
                  HomeTile(
                    icon: Icons.workspace_premium,
                    title: 'Subscriptions',
                    subtitle: 'Plans & perks',
                    onTap: () => Navigator.pushNamed(context, '/subscriptions'),
                  ),
                  HomeTile(
                    icon: Icons.build_circle_outlined,
                    title: 'Report maintenance',
                    comingSoon: true,
                  ),
                  HomeTile(
                    icon: Icons.history,
                    title: 'History',
                    onTap: () => Navigator.pushNamed(context, '/history'),
                  ),
                  HomeTile(
                    icon: Icons.settings,
                    title: 'City settings',
                    onTap: () => Navigator.pushNamed(context, '/city-settings'),
                  ),
                  HomeTile(
                    icon: Icons.ev_station_outlined,
                    title: 'EV Chargers',
                    onTap: () => Navigator.pushNamed(context, '/charging'),
                  ),
                  HomeTile(
                    icon: Icons.local_shipping,
                    title: 'Tow Helper',
                    onTap: () => Navigator.pushNamed(context, '/tow-helper'),
                  ),
                  HomeTile(
                    icon: Icons.place,
                    title: 'Saved Places',
                    onTap: () => Navigator.pushNamed(context, '/saved-places'),
                  ),
                  HomeTile(
                    icon: Icons.local_offer,
                    title: 'Deals & Sponsors',
                    onTap: () => Navigator.pushNamed(context, '/sponsors'),
                  ),
                  HomeTile(
                    icon: Icons.card_giftcard,
                    title: 'Invite Friends',
                    subtitle: 'Earn free Premium',
                    onTap: () => Navigator.pushNamed(context, '/referrals'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // AdMob banner ad for free tier users
            const AdBannerWidget(
              adSize: AdSize.largeBanner,
              showPlaceholder: false,
            ),
          ],
        ),
      ),
    );
  }
}

class HomeTile extends StatelessWidget {
  const HomeTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.comingSoon = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    const tileBg = Color(0xFF0D2A26);
    const tileBorder = Color(0xFF174139);
    const accent = Color(0xFFF8C660);
    const textColor = Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: comingSoon
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            : (onTap ?? () {}),
        child: Ink(
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tileBorder, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    size: 36,
                    color: comingSoon ? accent.withValues(alpha: 0.5) : accent,
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: comingSoon
                            ? textColor.withValues(alpha: 0.5)
                            : textColor,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Flexible(
                      child: Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: comingSoon
                              ? textColor.withValues(alpha: 0.5)
                              : textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              if (comingSoon)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'SOON',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D2A26),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Risk badge card for dashboard
class _RiskBadgeCard extends StatelessWidget {
  const _RiskBadgeCard({required this.risk});
  final LocationRisk risk;

  Color get _color {
    switch (risk.riskLevel) {
      case RiskLevel.high:
        return const Color(0xFFE53935);
      case RiskLevel.medium:
        return const Color(0xFFFFA726);
      case RiskLevel.low:
        return const Color(0xFF66BB6A);
    }
  }

  String get _label {
    switch (risk.riskLevel) {
      case RiskLevel.high:
        return 'HIGH RISK';
      case RiskLevel.medium:
        return 'MEDIUM RISK';
      case RiskLevel.low:
        return 'LOW RISK';
    }
  }

  IconData get _icon {
    switch (risk.riskLevel) {
      case RiskLevel.high:
        return Icons.warning_rounded;
      case RiskLevel.medium:
        return Icons.info_rounded;
      case RiskLevel.low:
        return Icons.check_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
            child: Icon(_icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${risk.riskScore}% citation probability',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Your current location • Based on 466K+ citations',
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskBadgeCardLoading extends StatelessWidget {
  const _RiskBadgeCardLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Loading citation risk for your area...',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

class _RiskBadgeCardError extends StatelessWidget {
  const _RiskBadgeCardError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_off_rounded,
              color: Colors.orange,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unable to load citation risk',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[300],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Check location permissions and try again',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
