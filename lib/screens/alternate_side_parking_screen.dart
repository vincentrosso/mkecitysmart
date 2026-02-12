import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/alternate_side_parking_service.dart';
import '../services/notification_service.dart';
import '../widgets/alternate_side_parking_card.dart';
import '../widgets/data_source_attribution.dart';

/// Full screen for alternate side parking information
class AlternateSideParkingScreen extends StatelessWidget {
  const AlternateSideParkingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AlternateSideParkingService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alternate Side Parking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
            tooltip: 'How it works',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Main card with today and upcoming days
          const AlternateSideParkingCard(showUpcoming: true, upcomingDays: 14),

          const SizedBox(height: 24),

          // How it works section
          _buildHowItWorksCard(context),

          const SizedBox(height: 16),

          // Tips section
          _buildTipsCard(context),

          const SizedBox(height: 16),

          // Notification settings
          _buildNotificationCard(context, service),

          const DataSourceAttribution(
            source: 'City of Milwaukee DPW (city.milwaukee.gov)',
            url:
                'https://city.milwaukee.gov/dpw/infrastructure/Street-Maintenance/Alternate-Side-Parking',
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.help_outline,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'How It Works',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context: context,
              icon: Icons.calendar_today,
              title: 'Odd Days (1, 3, 5, 7...)',
              description: 'Park on the odd-numbered side of the street',
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context: context,
              icon: Icons.calendar_today,
              title: 'Even Days (2, 4, 6, 8...)',
              description: 'Park on the even-numbered side of the street',
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context: context,
              icon: Icons.schedule,
              title: 'Switch at Midnight',
              description: 'Parking side changes every night at 12:00 AM',
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color:
                      Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ??
                      Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipsCard(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Parking Tips',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTipItem(
              context,
              'Look at house numbers to identify which side is odd/even',
            ),
            _buildTipItem(
              context,
              'Set a reminder to move your car before midnight',
            ),
            _buildTipItem(
              context,
              'Check for posted signs - some streets may have exceptions',
            ),
            _buildTipItem(
              context,
              'Enable notifications in this app for daily reminders',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color:
                    Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.8) ??
                    Colors.grey[700],
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    AlternateSideParkingService service,
  ) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        final prefs = provider.profile?.preferences;
        final morningOn = prefs?.aspMorningReminder ?? true;
        final eveningOn = prefs?.aspEveningWarning ?? true;
        final midnightOn = prefs?.aspMidnightAlert ?? false;

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.notifications_active,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Notifications',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Get reminders to help you remember which side to park on:',
                  style: TextStyle(
                    color:
                        Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withValues(alpha: 0.8) ??
                        Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                _buildNotificationToggle(
                  icon: Icons.wb_sunny,
                  title: 'Morning Reminder',
                  description: 'Daily at 7:00 AM',
                  enabled: morningOn,
                  color: Colors.orange,
                  onChanged: (value) {
                    provider.updatePreferences(aspMorningReminder: value);
                    NotificationService.instance.syncAspNotifications(
                      morningEnabled: value,
                      eveningEnabled: eveningOn,
                      midnightEnabled: midnightOn,
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildNotificationToggle(
                  icon: Icons.nightlight_round,
                  title: 'Evening Warning',
                  description: 'Daily at 9:00 PM (before side changes)',
                  enabled: eveningOn,
                  color: Colors.indigo,
                  onChanged: (value) {
                    provider.updatePreferences(aspEveningWarning: value);
                    NotificationService.instance.syncAspNotifications(
                      morningEnabled: morningOn,
                      eveningEnabled: value,
                      midnightEnabled: midnightOn,
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildNotificationToggle(
                  icon: Icons.alarm,
                  title: 'Midnight Alert',
                  description: 'At 12:00 AM when side changes',
                  enabled: midnightOn,
                  color: Colors.red,
                  onChanged: (value) {
                    provider.updatePreferences(aspMidnightAlert: value);
                    NotificationService.instance.syncAspNotifications(
                      morningEnabled: morningOn,
                      eveningEnabled: eveningOn,
                      midnightEnabled: value,
                    );
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/preferences');
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Configure Notifications'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await service.sendParkingNotification(
                        type: NotificationType.morningReminder,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Test notification sent!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Send Test Notification'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationToggle({
    required IconData icon,
    required String title,
    required String description,
    required bool enabled,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: enabled ? color.withValues(alpha: 0.08) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? color.withValues(alpha: 0.3) : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: enabled ? color : Colors.grey[500], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: enabled ? color : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: enabled
                        ? color.withValues(alpha: 0.7)
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: enabled,
            onChanged: onChanged,
            activeTrackColor: color.withValues(alpha: 0.4),
            activeThumbColor: color,
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Alternate Side Parking'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Alternate side parking is a traffic law that helps cities with:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              _buildDialogBullet('Street cleaning operations'),
              _buildDialogBullet('Snow plowing during winter'),
              _buildDialogBullet('Emergency vehicle access'),
              _buildDialogBullet('Fair parking distribution'),
              const SizedBox(height: 16),
              Text(
                'The rule is simple: on odd-numbered days, park on the odd side. '
                'On even-numbered days, park on the even side.',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Violation may result in tickets or towing.',
                        style: TextStyle(
                          color: Colors.orange[900],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }
}
