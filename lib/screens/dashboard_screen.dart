import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../providers/user_provider.dart';
import '../services/alternate_side_parking_service.dart';
import '../services/location_service.dart';
import '../services/parking_risk_service.dart';
import '../theme/app_theme.dart';
import 'alerts_landing_screen.dart';
import '../widgets/citysmart_scaffold.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  LocationRisk? _locationRisk;
  bool _loadingRisk = true;

  @override
  void initState() {
    super.initState();
    _loadRiskData();
  }

  Future<void> _loadRiskData() async {
    try {
      final loc = await LocationService().getCurrentPosition();
      if (loc != null && mounted) {
        final risk = await ParkingRiskService.instance.getRiskForLocation(
          loc.latitude,
          loc.longitude,
        );
        if (mounted) {
          setState(() {
            _locationRisk = risk;
            _loadingRisk = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingRisk = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loadingRisk = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final provider = context.watch<UserProvider>();

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
            if (!_loadingRisk && _locationRisk != null)
              _RiskBadgeCard(risk: _locationRisk!)
            else if (_loadingRisk)
              const _RiskBadgeCardLoading(),
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
                  FutureBuilder<String>(
                    future: _resolveAltSubtitle(provider),
                    builder: (context, snapshot) {
                      return HomeTile(
                        icon: Icons.compare_arrows,
                        title: 'Alt-side parking',
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/alternate-parking',
                        ),
                      );
                    },
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
                    title: 'Tickets',
                    onTap: () => Navigator.pushNamed(context, '/tickets'),
                  ),
                  HomeTile(
                    icon: Icons.workspace_premium,
                    title: 'Subscriptions',
                    subtitle: 'Plans & perks',
                    onTap: () =>
                        Navigator.pushNamed(context, '/subscriptions'),
                  ),
                  HomeTile(
                    icon: Icons.build_circle_outlined,
                    title: 'Report maintenance',
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/maintenance',
                    ),
                  ),
                  HomeTile(
                    icon: Icons.history,
                    title: 'History',
                    onTap: () => Navigator.pushNamed(context, '/history'),
                  ),
                  HomeTile(
                    icon: Icons.settings,
                    title: 'City settings',
                    onTap: () =>
                        Navigator.pushNamed(context, '/city-settings'),
                  ),
                  HomeTile(
                    icon: Icons.ev_station_outlined,
                    title: 'EV Chargers',
                    onTap: () => Navigator.pushNamed(context, '/charging'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PromoBannerCard(
              text: 'Start saving today with Auto Insurance?',
              onTap: () => Navigator.pushNamed(context, '/subscriptions'),
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
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

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
        onTap: onTap ?? () {},
        child: Ink(
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tileBorder, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 40, color: accent),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: 0.2,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class PromoBannerCard extends StatelessWidget {
  const PromoBannerCard({
    super.key,
    required this.text,
    required this.onTap,
  });

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kCitySmartYellow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Text(
            text,
            style: const TextStyle(
              color: kCitySmartGreen,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

int _addressNumber(String? address) {
  if (address == null) return 0;
  final match = RegExp(r'(\d+)').firstMatch(address);
  if (match == null) return 0;
  return int.tryParse(match.group(0) ?? '0') ?? 0;
}

int _addressFromPosition(Position position) {
  final val = (position.latitude.abs() * 10000).round() +
      (position.longitude.abs() * 10000).round();
  return val % 10000 == 0 ? 101 : val % 10000;
}

Future<String> _resolveAltSubtitle(UserProvider provider) async {
  final service = AlternateSideParkingService.instance;
  // Service only uses date-based odd/even; location is not needed here.
  final instructions = service.getTodayInstructions();
  return instructions.parkingSide == ParkingSide.odd
      ? 'Odd side today'
      : 'Even side today';
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
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
            ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400],
                  ),
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
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
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
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
