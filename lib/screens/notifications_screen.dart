import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../services/notification_service.dart';
import '../citysmart/theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CitySmartTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: CitySmartTheme.primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  switch (value) {
                    case 'mark_all_read':
                      notificationProvider.markAllAsRead();
                      break;
                    case 'clear_old':
                      notificationProvider.clearOldNotifications();
                      break;
                    case 'settings':
                      _showNotificationSettings(context);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'mark_all_read',
                    child: Row(
                      children: [
                        Icon(Icons.done_all, size: 20),
                        SizedBox(width: 8),
                        Text('Mark All Read'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear_old',
                    child: Row(
                      children: [
                        Icon(Icons.clear, size: 20),
                        SizedBox(width: 8),
                        Text('Clear Old'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings, size: 20),
                        SizedBox(width: 8),
                        Text('Settings'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: CitySmartTheme.secondaryYellow,
          tabs: [
            Consumer<NotificationProvider>(
              builder: (context, notificationProvider, child) {
                final unreadCount = notificationProvider.unreadCount;
                return Tab(
                  icon: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text(unreadCount.toString()),
                    child: const Icon(Icons.notifications),
                  ),
                  text: 'All',
                );
              },
            ),
            const Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_NotificationsTab(), _NotificationSettingsTab()],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    _tabController.animateTo(1);
  }
}

class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        if (notificationProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: CitySmartTheme.primaryGreen,
            ),
          );
        }

        if (notificationProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  notificationProvider.errorMessage!,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => notificationProvider.initialize(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CitySmartTheme.primaryGreen,
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }

        if (notificationProvider.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No notifications',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'You\'re all caught up! Notifications will appear here.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => notificationProvider.initialize(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: notificationProvider.notifications.length,
            itemBuilder: (context, index) {
              final notification = notificationProvider.notifications[index];
              return _NotificationWidget(notification: notification);
            },
          ),
        );
      },
    );
  }
}

class _NotificationWidget extends StatelessWidget {
  final AppNotification notification;

  const _NotificationWidget({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: notification.isRead ? Colors.white : Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: notification.isRead
              ? Colors.grey.shade300
              : Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Dismissible(
        key: Key(notification.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete, color: Colors.white, size: 24),
        ),
        onDismissed: (direction) {
          context.read<NotificationProvider>().deleteNotification(
            notification.id,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${notification.title} deleted'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  // In a real app, you'd implement undo functionality
                },
              ),
            ),
          );
        },
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: _getNotificationColor(notification.type),
            child: Icon(
              _getNotificationIcon(notification.type),
              color: Colors.white,
              size: 20,
            ),
          ),
          title: Text(
            notification.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: notification.isRead
                  ? FontWeight.normal
                  : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.body,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    _getTimeAgo(notification.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  if (!notification.isRead) ...[
                    const Spacer(),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          onTap: () {
            if (!notification.isRead) {
              context.read<NotificationProvider>().markAsRead(notification.id);
            }
            _showNotificationDetails(context, notification);
          },
        ),
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.streetSweeping:
        return Colors.orange;
      case NotificationType.parkingReminder:
        return CitySmartTheme.primaryGreen;
      case NotificationType.permitExpiry:
        return Colors.red;
      case NotificationType.reservationConfirmation:
        return Colors.blue;
      case NotificationType.paymentSuccess:
        return Colors.green;
      case NotificationType.paymentFailed:
        return Colors.red;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.streetSweeping:
        return Icons.cleaning_services;
      case NotificationType.parkingReminder:
        return Icons.local_parking;
      case NotificationType.permitExpiry:
        return Icons.card_membership;
      case NotificationType.reservationConfirmation:
        return Icons.check_circle;
      case NotificationType.paymentSuccess:
        return Icons.payment;
      case NotificationType.paymentFailed:
        return Icons.error;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showNotificationDetails(
    BuildContext context,
    AppNotification notification,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getNotificationColor(notification.type),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    notification.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              notification.body,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Received ${_getTimeAgo(notification.createdAt)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            if (notification.scheduledTime.isAfter(DateTime.now())) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Scheduled for ${_formatDateTime(notification.scheduledTime)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            if (notification.data != null && notification.data!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Additional Information',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...notification.data!.entries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              '${entry.key}:',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value.toString(),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CitySmartTheme.primaryGreen,
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} at ${_formatTime(dateTime)}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }
}

class _NotificationSettingsTab extends StatelessWidget {
  const _NotificationSettingsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notification Types',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _NotificationToggle(
                      title: 'Street Sweeping Alerts',
                      subtitle:
                          'Get notified about upcoming street sweeping in your area',
                      icon: Icons.cleaning_services,
                      value: notificationProvider.streetSweepingEnabled,
                      onChanged: notificationProvider.setStreetSweepingEnabled,
                    ),
                    const Divider(),
                    _NotificationToggle(
                      title: 'Parking Reminders',
                      subtitle: 'Reminders for your parking reservations',
                      icon: Icons.local_parking,
                      value: notificationProvider.parkingRemindersEnabled,
                      onChanged:
                          notificationProvider.setParkingRemindersEnabled,
                    ),
                    const Divider(),
                    _NotificationToggle(
                      title: 'Permit Expiry',
                      subtitle:
                          'Alerts when your parking permits are about to expire',
                      icon: Icons.card_membership,
                      value: notificationProvider.permitExpiryEnabled,
                      onChanged: notificationProvider.setPermitExpiryEnabled,
                    ),
                    const Divider(),
                    _NotificationToggle(
                      title: 'Payment Notifications',
                      subtitle:
                          'Confirmations and alerts for payment transactions',
                      icon: Icons.payment,
                      value: notificationProvider.paymentNotificationsEnabled,
                      onChanged:
                          notificationProvider.setPaymentNotificationsEnabled,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notification Statistics',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _StatCard(
                      'Total Notifications',
                      notificationProvider.notifications.length.toString(),
                      Icons.notifications,
                      Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _StatCard(
                      'Unread Notifications',
                      notificationProvider.unreadCount.toString(),
                      Icons.mark_email_unread,
                      Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    _StatCard(
                      'Street Sweeping Alerts',
                      notificationProvider
                          .getNotificationsByType(
                            NotificationType.streetSweeping,
                          )
                          .length
                          .toString(),
                      Icons.cleaning_services,
                      Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    _StatCard(
                      'Parking Reminders',
                      notificationProvider
                          .getNotificationsByType(
                            NotificationType.parkingReminder,
                          )
                          .length
                          .toString(),
                      Icons.local_parking,
                      CitySmartTheme.primaryGreen,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NotificationToggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final Function(bool) onChanged;

  const _NotificationToggle({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: CitySmartTheme.primaryGreen),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: CitySmartTheme.primaryGreen,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
