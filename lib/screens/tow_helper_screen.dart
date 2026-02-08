import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/subscription_plan.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/citysmart_scaffold.dart';
import '../widgets/feature_gate.dart';

/// Tow Helper Screen - Guidance for vehicle recovery
///
/// Features:
/// - Step-by-step tow recovery guide
/// - Milwaukee tow lot contact info
/// - Quick-dial and map links
/// - Cost estimator
/// - Tips for avoiding tows
class TowHelperScreen extends StatelessWidget {
  const TowHelperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CitySmartScaffold(
      title: 'Tow Helper',
      currentIndex: -1,
      body: FeatureGate(
        feature: PremiumFeature.towHelper,
        child: const _TowHelperBody(),
      ),
    );
  }
}

class _TowHelperBody extends StatefulWidget {
  const _TowHelperBody();

  @override
  State<_TowHelperBody> createState() => _TowHelperBodyState();
}

class _TowHelperBodyState extends State<_TowHelperBody> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView('TowHelperScreen');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: _TabButton(
                  label: 'Recovery Guide',
                  icon: Icons.help_outline,
                  selected: _selectedTab == 0,
                  onTap: () => setState(() => _selectedTab = 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TabButton(
                  label: 'Tow Lots',
                  icon: Icons.location_city,
                  selected: _selectedTab == 1,
                  onTap: () => setState(() => _selectedTab = 1),
                ),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: _selectedTab == 0
              ? const _RecoveryGuideTab()
              : const _TowLotsTab(),
        ),
      ],
    );
  }
}

// ==================== Tab Button ====================

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? kCitySmartYellow : Colors.white10,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? kCitySmartGreen : Colors.white70,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? kCitySmartGreen : Colors.white70,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== Recovery Guide Tab ====================

class _RecoveryGuideTab extends StatelessWidget {
  const _RecoveryGuideTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Alert banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade800, Colors.orange.shade700],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Vehicle Towed?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Don't panic! Follow these steps to recover your vehicle.",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Step-by-step guide
        _StepCard(
          step: 1,
          title: 'Confirm Tow Status',
          description:
              'Call the Milwaukee Police non-emergency line to confirm your vehicle was towed and find out which lot it was taken to.',
          actionLabel: 'Call Police',
          actionIcon: Icons.phone,
          onAction: () => _launchPhone(context, '414-933-4444'),
        ),

        _StepCard(
          step: 2,
          title: 'Gather Required Documents',
          description:
              'You\'ll need:\n• Valid driver\'s license\n• Vehicle registration\n• Proof of insurance\n• Payment (cash, credit, or debit)',
          actionLabel: null,
          onAction: null,
        ),

        _StepCard(
          step: 3,
          title: 'Visit the Tow Lot',
          description:
              'Go to the tow lot during business hours. The main Milwaukee tow lot is open Monday-Friday 7am-10pm.',
          actionLabel: 'Get Directions',
          actionIcon: Icons.map,
          onAction: () => _launchMaps(context, _milwaukeeTowLots.first),
        ),

        _StepCard(
          step: 4,
          title: 'Pay the Fees',
          description:
              'Fees typically include:\n• Tow fee: \$145-\$275\n• Storage: \$25-\$40/day\n• Admin fee: \$15-\$25\n\nFees increase after 24 hours!',
          actionLabel: 'See Fee Details',
          actionIcon: Icons.attach_money,
          onAction: () => _showFeeSheet(context),
        ),

        _StepCard(
          step: 5,
          title: 'Retrieve Your Vehicle',
          description:
              'After payment, you\'ll receive a release form. Show this to the lot attendant to get your vehicle.',
          actionLabel: null,
          onAction: null,
        ),

        const SizedBox(height: 24),

        // Tips section
        const Text(
          'Tips to Avoid Future Tows',
          style: TextStyle(
            color: kCitySmartYellow,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        _TipCard(
          icon: Icons.notifications_active,
          title: 'Enable Parking Alerts',
          description: 'Get notified when parking enforcement is in your area.',
        ),
        _TipCard(
          icon: Icons.cleaning_services,
          title: 'Check Street Sweeping',
          description: 'Know when street sweeping is scheduled for your area.',
        ),
        _TipCard(
          icon: Icons.timer,
          title: 'Set Parking Timers',
          description: 'Use reminders to move your car before meters expire.',
        ),
        _TipCard(
          icon: Icons.place,
          title: 'Save Your Locations',
          description: 'Mark home and work to get relevant parking alerts.',
        ),

        const SizedBox(height: 80),
      ],
    );
  }

  static void _showFeeSheet(BuildContext context) {
    AnalyticsService.instance.logEvent('tow_fee_details_viewed');

    showModalBottomSheet(
      context: context,
      backgroundColor: kCitySmartGreen,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Milwaukee Tow Fee Estimates',
              style: TextStyle(
                color: kCitySmartYellow,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _FeeRow('Standard tow fee', '\$145 - \$175'),
            _FeeRow('Heavy duty tow', '\$200 - \$275'),
            _FeeRow('Storage (per day)', '\$25 - \$40'),
            _FeeRow('Admin/release fee', '\$15 - \$25'),
            const Divider(color: Colors.white24, height: 24),
            _FeeRow('Typical total (24hr)', '\$185 - \$240', highlight: true),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade800.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Fees may vary. Retrieve your vehicle ASAP to minimize storage charges.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  final String label;
  final String amount;
  final bool highlight;

  const _FeeRow(this.label, this.amount, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: highlight ? kCitySmartYellow : Colors.white70,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: highlight ? kCitySmartYellow : Colors.white,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int step;
  final String title;
  final String description;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const _StepCard({
    required this.step,
    required this.title,
    required this.description,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kCitySmartYellow,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  color: kCitySmartGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Card(
              color: kCitySmartGreen.withValues(alpha: 0.8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    if (actionLabel != null && onAction != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: onAction,
                          icon: Icon(actionIcon, size: 18),
                          label: Text(actionLabel!),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kCitySmartYellow,
                            side: BorderSide(
                              color: kCitySmartYellow.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _TipCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white10,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: kCitySmartYellow, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== Tow Lots Tab ====================

class _TowLotsTab extends StatelessWidget {
  const _TowLotsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Milwaukee Tow Lots',
          style: TextStyle(
            color: kCitySmartYellow,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Contact these locations to verify where your vehicle was towed.',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 16),

        ..._milwaukeeTowLots.map((lot) => _TowLotCard(lot: lot)),

        const SizedBox(height: 24),

        // Emergency contacts
        const Text(
          'Emergency Contacts',
          style: TextStyle(
            color: kCitySmartYellow,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        _ContactCard(
          name: 'Milwaukee Police (Non-Emergency)',
          phone: '414-933-4444',
          description: 'Confirm tow status and locate your vehicle',
        ),
        _ContactCard(
          name: 'Milwaukee 311',
          phone: '414-286-CITY',
          description: 'General city services and parking questions',
        ),
        _ContactCard(
          name: 'Parking Enforcement',
          phone: '414-286-2489',
          description: 'Questions about parking tickets and regulations',
        ),

        const SizedBox(height: 80),
      ],
    );
  }
}

class _TowLotCard extends StatelessWidget {
  final _TowLot lot;

  const _TowLotCard({required this.lot});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kCitySmartGreen.withValues(alpha: 0.8),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: kCitySmartYellow.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warehouse, color: kCitySmartYellow),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lot.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (lot.isPrimary)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kCitySmartYellow.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Primary',
                      style: TextStyle(
                        color: kCitySmartYellow,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Address
            _InfoRow(Icons.location_on_outlined, lot.address),

            // Hours
            _InfoRow(Icons.access_time, lot.hours),

            // Phone
            if (lot.phone != null) _InfoRow(Icons.phone, lot.phone!),

            const SizedBox(height: 12),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _launchPhone(context, lot.phone ?? '414-933-4444'),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Call'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kCitySmartYellow,
                      side: BorderSide(
                        color: kCitySmartYellow.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _launchMaps(context, lot),
                    icon: const Icon(Icons.directions, size: 16),
                    label: const Text('Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kCitySmartYellow,
                      foregroundColor: kCitySmartGreen,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.white54),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String name;
  final String phone;
  final String description;

  const _ContactCard({
    required this.name,
    required this.phone,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white10,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: const Icon(Icons.phone, color: kCitySmartYellow),
        title: Text(name, style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          description,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: TextButton(
          onPressed: () => _launchPhone(context, phone),
          child: Text(
            phone,
            style: const TextStyle(
              color: kCitySmartYellow,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== Tow Lot Data ====================

class _TowLot {
  final String name;
  final String address;
  final String hours;
  final String? phone;
  final double lat;
  final double lon;
  final bool isPrimary;

  const _TowLot({
    required this.name,
    required this.address,
    required this.hours,
    this.phone,
    required this.lat,
    required this.lon,
    this.isPrimary = false,
  });
}

const List<_TowLot> _milwaukeeTowLots = [
  _TowLot(
    name: 'Milwaukee Police Tow Lot',
    address: '3001 W. Clybourn St, Milwaukee, WI 53208',
    hours: 'Mon-Fri: 7am-10pm, Sat-Sun: 8am-4pm',
    phone: '414-935-7204',
    lat: 43.0379,
    lon: -87.9467,
    isPrimary: true,
  ),
  _TowLot(
    name: "Fischer's Towing",
    address: '1930 N. 31st St, Milwaukee, WI 53208',
    hours: '24/7',
    phone: '414-933-4300',
    lat: 43.0544,
    lon: -87.9506,
  ),
  _TowLot(
    name: 'Always Towing',
    address: '2000 W. Canal St, Milwaukee, WI 53233',
    hours: '24/7',
    phone: '414-344-0000',
    lat: 43.0248,
    lon: -87.9339,
  ),
  _TowLot(
    name: 'AAA Towing Milwaukee',
    address: '1223 N. Water St, Milwaukee, WI 53202',
    hours: '24/7',
    phone: '414-273-8200',
    lat: 43.0457,
    lon: -87.9101,
  ),
];

// ==================== Helper Functions ====================

Future<void> _launchPhone(BuildContext context, String phone) async {
  // Clean phone number
  final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
  final uri = Uri.parse('tel:$cleaned');

  AnalyticsService.instance.logEvent(
    'tow_phone_call',
    parameters: {'phone': phone},
  );

  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Copy to clipboard instead
      await Clipboard.setData(ClipboardData(text: phone));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Phone number copied: $phone')));
      }
    }
  } catch (e) {
    await Clipboard.setData(ClipboardData(text: phone));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Phone number copied: $phone')));
    }
  }
}

Future<void> _launchMaps(BuildContext context, _TowLot lot) async {
  // Try Google Maps first, then Apple Maps
  final googleUri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=${lot.lat},${lot.lon}&destination_place_id=${Uri.encodeComponent(lot.address)}',
  );
  final appleUri = Uri.parse(
    'https://maps.apple.com/?daddr=${lot.lat},${lot.lon}&dirflg=d',
  );

  AnalyticsService.instance.logEvent(
    'tow_directions',
    parameters: {'lot_name': lot.name},
  );

  try {
    if (await canLaunchUrl(googleUri)) {
      await launchUrl(googleUri, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(appleUri)) {
      await launchUrl(appleUri, mode: LaunchMode.externalApplication);
    } else {
      // Copy address instead
      await Clipboard.setData(ClipboardData(text: lot.address));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Address copied: ${lot.address}')),
        );
      }
    }
  } catch (e) {
    await Clipboard.setData(ClipboardData(text: lot.address));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Address copied: ${lot.address}')));
    }
  }
}
