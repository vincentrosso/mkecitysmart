import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/night_parking_permission.dart';
import '../providers/user_provider.dart';
import '../services/night_parking_service.dart';
import '../theme/app_theme.dart';

class NightParkingScreen extends StatefulWidget {
  const NightParkingScreen({super.key});

  @override
  State<NightParkingScreen> createState() => _NightParkingScreenState();
}

class _NightParkingScreenState extends State<NightParkingScreen> {
  bool _checkingZone = false;
  NightParkingZoneResult? _zoneResult;
  final _dateFormat = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    _checkUserZone();
  }

  Future<void> _checkUserZone() async {
    setState(() => _checkingZone = true);

    final provider = context.read<UserProvider>();
    final result = await provider.checkNightParkingForAddress();

    if (mounted) {
      setState(() {
        _zoneResult = result;
        _checkingZone = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = NightParkingService.instance;
    final permission = service.permission;
    final isEnforcement = service.isEnforcementActive();
    final stats = service.getCitationStats();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Night Parking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
            tooltip: 'About night parking',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Enforcement status banner
          _EnforcementBanner(
            isActive: isEnforcement,
            hasPermit: service.hasValidPermission,
            timeUntil: service.timeUntilEnforcement(),
          ),
          const SizedBox(height: 20),

          // Your permit status card
          _PermitStatusCard(
            permission: permission,
            dateFormat: _dateFormat,
            onApply: _launchApplication,
            onActivate: _showActivateDialog,
          ),
          const SizedBox(height: 16),

          // Zone check card
          _ZoneCheckCard(
            isLoading: _checkingZone,
            result: _zoneResult,
            onRecheck: _checkUserZone,
          ),
          const SizedBox(height: 16),

          // Reminder settings
          _ReminderSettingsCard(
            enabled: service.reminderEnabled,
            onToggle: (enabled) async {
              await service.setReminderEnabled(enabled);
              setState(() {});
            },
          ),
          const SizedBox(height: 16),

          // Statistics card
          _StatsCard(stats: stats),
          const SizedBox(height: 16),

          // Info card
          const _InfoCard(),
          const SizedBox(height: 24),

          // Apply button
          FilledButton.icon(
            onPressed: _launchApplication,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Apply for Night Parking Permission'),
            style: FilledButton.styleFrom(
              backgroundColor: kCitySmartYellow,
              foregroundColor: kCitySmartGreen,
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchApplication() async {
    final url = Uri.parse(NightParkingService.applicationUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open application page')),
        );
      }
    }
  }

  Future<void> _showActivateDialog() async {
    final provider = context.read<UserProvider>();
    final plateController = TextEditingController();
    final descController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCitySmartGreen,
        title: const Text('Add Permit Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: plateController,
              decoration: const InputDecoration(
                labelText: 'License Plate',
                hintText: 'ABC-1234',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Vehicle Description (optional)',
                hintText: 'Blue Honda Civic',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: kCitySmartYellow,
              foregroundColor: kCitySmartGreen,
            ),
            child: const Text('Save & Activate'),
          ),
        ],
      ),
    );

    if (result == true && plateController.text.isNotEmpty) {
      await provider.setNightParkingPermission(
        licensePlate: plateController.text.trim(),
        vehicleDescription: descController.text.trim().isNotEmpty
            ? descController.text.trim()
            : null,
        status: NightParkingStatus.active,
        expirationDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Night parking permit activated!')),
        );
      }
    }
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCitySmartGreen,
        title: const Text('About Night Parking'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Milwaukee Night Parking Restriction',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'From 2:00 AM to 6:00 AM, parking on most Milwaukee streets '
                'requires permission. This rule helps with snow removal, '
                'street cleaning, and emergency access.',
              ),
              SizedBox(height: 16),
              Text(
                'Exemptions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                '• Downtown Metered District\n'
                '• Historic Third Ward\n'
                '• Streets with posted exemptions',
              ),
              SizedBox(height: 16),
              Text(
                'How to Apply',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Apply online at city.milwaukee.gov/NightParking. Permission '
                'is typically valid for one year and tied to your vehicle '
                'and address.',
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: kCitySmartYellow,
              foregroundColor: kCitySmartGreen,
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Enforcement Banner
// ─────────────────────────────────────────────────────────────────────────────

class _EnforcementBanner extends StatelessWidget {
  const _EnforcementBanner({
    required this.isActive,
    required this.hasPermit,
    this.timeUntil,
  });

  final bool isActive;
  final bool hasPermit;
  final Duration? timeUntil;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color textColor;
    final IconData icon;
    final String title;
    final String subtitle;

    if (isActive) {
      if (hasPermit) {
        bgColor = const Color(0xFF2E7D32);
        textColor = Colors.white;
        icon = Icons.check_circle;
        title = 'Enforcement Active — You\'re Covered';
        subtitle = 'Your night parking permit is valid.';
      } else {
        bgColor = const Color(0xFFE53935);
        textColor = Colors.white;
        icon = Icons.warning_rounded;
        title = '🚨 Enforcement Active Now';
        subtitle = 'It\'s 2-6 AM. Vehicles without permission may be ticketed.';
      }
    } else {
      final hours = timeUntil?.inHours ?? 0;
      final minutes = (timeUntil?.inMinutes ?? 0) % 60;
      bgColor = const Color(0xFF1A3A34);
      textColor = Colors.white;
      icon = Icons.nightlight_round;
      if (hours > 0) {
        title = 'Enforcement in ${hours}h ${minutes}m';
      } else if (minutes > 0) {
        title = 'Enforcement in ${minutes}m';
      } else {
        title = 'No enforcement right now';
      }
      subtitle = hasPermit
          ? 'Your permit is valid for overnight parking.'
          : 'Night parking restriction applies 2 AM - 6 AM.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.9),
                    fontSize: 14,
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

// ─────────────────────────────────────────────────────────────────────────────
//  Permit Status Card
// ─────────────────────────────────────────────────────────────────────────────

class _PermitStatusCard extends StatelessWidget {
  const _PermitStatusCard({
    this.permission,
    required this.dateFormat,
    required this.onApply,
    required this.onActivate,
  });

  final NightParkingPermission? permission;
  final DateFormat dateFormat;
  final VoidCallback onApply;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2A26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF174139)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.badge_outlined,
                color: kCitySmartYellow,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Your Night Parking Permit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              _StatusBadge(status: permission?.status),
            ],
          ),
          const SizedBox(height: 16),
          if (permission == null ||
              permission!.status == NightParkingStatus.unknown) ...[
            const Text(
              'No permit on file. If you have a night parking permission, add it here to track expiration and get renewal reminders.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onActivate,
                    icon: const Icon(Icons.add),
                    label: const Text('I Have a Permit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kCitySmartYellow,
                      side: const BorderSide(color: kCitySmartYellow),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onApply,
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Apply'),
                    style: FilledButton.styleFrom(
                      backgroundColor: kCitySmartYellow,
                      foregroundColor: kCitySmartGreen,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            _PermitDetailRow(
              label: 'Address',
              value: permission!.address.isNotEmpty
                  ? permission!.address
                  : 'Not set',
            ),
            if (permission!.licensePlate != null)
              _PermitDetailRow(
                label: 'Vehicle',
                value: permission!.licensePlate!,
              ),
            if (permission!.expirationDate != null)
              _PermitDetailRow(
                label: 'Expires',
                value: dateFormat.format(permission!.expirationDate!),
                isWarning: permission!.isExpiringSoon(),
              ),
            if (permission!.isExpiringSoon()) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onApply,
                icon: const Icon(Icons.refresh),
                label: const Text('Renew Permit'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({this.status});
  final NightParkingStatus? status;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;

    switch (status) {
      case NightParkingStatus.active:
        color = const Color(0xFF4CAF50);
        label = 'ACTIVE';
        break;
      case NightParkingStatus.expired:
        color = const Color(0xFFE53935);
        label = 'EXPIRED';
        break;
      case NightParkingStatus.pending:
        color = const Color(0xFFFFA726);
        label = 'PENDING';
        break;
      case NightParkingStatus.denied:
        color = const Color(0xFFE53935);
        label = 'DENIED';
        break;
      case NightParkingStatus.exempt:
        color = const Color(0xFF42A5F5);
        label = 'EXEMPT';
        break;
      default:
        color = Colors.grey;
        label = 'NONE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _PermitDetailRow extends StatelessWidget {
  const _PermitDetailRow({
    required this.label,
    required this.value,
    this.isWarning = false,
  });

  final String label;
  final String value;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isWarning ? Colors.orange : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (isWarning)
            const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Zone Check Card
// ─────────────────────────────────────────────────────────────────────────────

class _ZoneCheckCard extends StatelessWidget {
  const _ZoneCheckCard({
    required this.isLoading,
    this.result,
    required this.onRecheck,
  });

  final bool isLoading;
  final NightParkingZoneResult? result;
  final VoidCallback onRecheck;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2A26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF174139)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: kCitySmartYellow, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Your Zone Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRecheck,
                icon: const Icon(Icons.refresh, color: kCitySmartYellow),
                tooltip: 'Recheck zone',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: kCitySmartYellow),
              ),
            )
          else if (result == null)
            const Text(
              'Set your address in settings to check if your zone requires night parking permission.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            )
          else ...[
            Row(
              children: [
                Icon(
                  result!.requiresPermission
                      ? Icons.warning_amber
                      : Icons.check_circle,
                  color: result!.requiresPermission
                      ? Colors.orange
                      : Colors.green,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result!.zoneName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        result!.requiresPermission
                            ? 'Permission required for overnight parking'
                            : result!.exemptionReason ?? 'No permission needed',
                        style: TextStyle(
                          color: result!.requiresPermission
                              ? Colors.orange
                              : Colors.green,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Enforcement: ${result!.enforcementHours}',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Reminder Settings Card
// ─────────────────────────────────────────────────────────────────────────────

class _ReminderSettingsCard extends StatelessWidget {
  const _ReminderSettingsCard({required this.enabled, required this.onToggle});

  final bool enabled;
  final void Function(bool) onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2A26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF174139)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: kCitySmartYellow,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Reminders',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: enabled,
            onChanged: onToggle,
            title: const Text(
              'Evening Reminder (9 PM)',
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
            subtitle: const Text(
              'Reminds you before enforcement starts',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            activeTrackColor: kCitySmartYellow.withValues(alpha: 0.5),
            thumbColor: WidgetStateProperty.resolveWith((states) {
              return states.contains(WidgetState.selected)
                  ? kCitySmartYellow
                  : Colors.grey;
            }),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Stats Card
// ─────────────────────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});
  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final total = stats['nightParkingTotal'] as int? ?? 0;
    final percent = stats['percentOfAllCitations'] as double? ?? 0;
    final cost = stats['averageTicketCost'] as double? ?? 30;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2A26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF174139)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: kCitySmartYellow, size: 24),
              SizedBox(width: 12),
              Text(
                'Why Night Parking Matters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _StatRow(
            icon: Icons.receipt_long,
            label: 'Night parking tickets issued',
            value: '${(total / 1000).toStringAsFixed(0)}K+',
          ),
          _StatRow(
            icon: Icons.pie_chart,
            label: 'Of all Milwaukee citations',
            value: '~${percent.toStringAsFixed(0)}%',
          ),
          _StatRow(
            icon: Icons.attach_money,
            label: 'Average ticket cost',
            value: '\$${cost.toStringAsFixed(0)}',
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: kCitySmartYellow,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Info Card
// ─────────────────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A3A34),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text(
                'About Night Parking in Milwaukee',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '• Enforcement hours: 2:00 AM - 6:00 AM\n'
            '• Applies to most residential streets\n'
            '• Annual permission can be obtained online\n'
            '• Metered areas may have different rules\n'
            '• Some streets are exempt — check your zone',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
