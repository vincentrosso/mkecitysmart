import 'package:flutter/material.dart';
import '../services/alternate_side_parking_service.dart';
import '../widgets/alternate_side_parking_card.dart';

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
              icon: Icons.calendar_today,
              title: 'Odd Days (1, 3, 5, 7...)',
              description: 'Park on the odd-numbered side of the street',
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.calendar_today,
              title: 'Even Days (2, 4, 6, 8...)',
              description: 'Park on the even-numbered side of the street',
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
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
              'Look at house numbers to identify which side is odd/even',
            ),
            _buildTipItem('Set a reminder to move your car before midnight'),
            _buildTipItem(
              'Check for posted signs - some streets may have exceptions',
            ),
            _buildTipItem(
              'Enable notifications in this app for daily reminders',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
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
                color: Colors.grey[700],
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Get reminders to help you remember which side to park on:',
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildNotificationOption(
              icon: Icons.wb_sunny,
              title: 'Morning Reminder',
              description: 'Daily at 7:00 AM',
              enabled: true,
            ),
            const SizedBox(height: 12),
            _buildNotificationOption(
              icon: Icons.nightlight_round,
              title: 'Evening Warning',
              description: 'Daily at 9:00 PM (before side changes)',
              enabled: true,
            ),
            const SizedBox(height: 12),
            _buildNotificationOption(
              icon: Icons.alarm,
              title: 'Midnight Alert',
              description: 'At 12:00 AM when side changes',
              enabled: false,
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
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationOption({
    required IconData icon,
    required String title,
    required String description,
    required bool enabled,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: enabled ? Colors.green[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? Colors.green[200]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: enabled ? Colors.green[700] : Colors.grey[500],
            size: 24,
          ),
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
                    color: enabled ? Colors.green[900] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: enabled ? Colors.green[700] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            enabled ? Icons.check_circle : Icons.cancel,
            color: enabled ? Colors.green : Colors.grey,
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
