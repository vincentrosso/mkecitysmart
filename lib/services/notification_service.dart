import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/street_sweeping.dart';
import '../models/parking_reservation.dart';
import '../models/permit.dart';
import '../services/storage_service.dart';

enum NotificationType {
  streetSweeping,
  parkingReminder,
  permitExpiry,
  reservationConfirmation,
  paymentSuccess,
  paymentFailed,
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime scheduledTime;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.scheduledTime,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${json['type']}',
        orElse: () => NotificationType.parkingReminder,
      ),
      scheduledTime: DateTime.parse(json['scheduled_time']),
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'])
          : null,
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.toString().split('.').last,
      'scheduled_time': scheduledTime.toIso8601String(),
      'data': data,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? scheduledTime,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class NotificationService {
  static const String _notificationsKey = 'app_notifications';

  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;

  // Initialize notification service
  Future<void> initialize() async {
    await _loadNotifications();
    _schedulePeriodicCheck();
  }

  // Load notifications from storage
  Future<void> _loadNotifications() async {
    try {
      final settings = await StorageService.getAppSettings();
      if (settings != null && settings.containsKey(_notificationsKey)) {
        final List<dynamic> notificationsList = jsonDecode(
          settings[_notificationsKey],
        );
        _notifications =
            notificationsList
                .map((json) => AppNotification.fromJson(json))
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }

  // Save notifications to storage
  Future<void> _saveNotifications() async {
    try {
      final settings =
          await StorageService.getAppSettings() ?? <String, dynamic>{};
      settings[_notificationsKey] = jsonEncode(
        _notifications.map((n) => n.toJson()).toList(),
      );
      await StorageService.saveAppSettings(settings);
    } catch (e) {
      debugPrint('Error saving notifications: $e');
    }
  }

  // Schedule a notification
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required NotificationType type,
    required DateTime scheduledTime,
    Map<String, dynamic>? data,
  }) async {
    final notification = AppNotification(
      id: _generateNotificationId(),
      title: title,
      body: body,
      type: type,
      scheduledTime: scheduledTime,
      data: data,
      createdAt: DateTime.now(),
    );

    _notifications.insert(0, notification);
    await _saveNotifications();

    // In a real app, this would integrate with flutter_local_notifications
    // to schedule actual system notifications
    _mockScheduleSystemNotification(notification);
  }

  // Schedule street sweeping notifications
  Future<void> scheduleStreetSweepingNotifications(
    List<StreetSweeping> schedules,
  ) async {
    final isEnabled = await StorageService.isNotificationEnabled(
      'street_sweeping',
    );
    if (!isEnabled) return;

    for (final schedule in schedules) {
      // 24-hour advance notice
      final dayBefore = schedule.date.subtract(const Duration(days: 1));
      if (dayBefore.isAfter(DateTime.now())) {
        await scheduleNotification(
          title: 'Street Sweeping Tomorrow',
          body:
              'Street sweeping scheduled on ${schedule.streetName} tomorrow at ${_formatTime(schedule.startTime)}',
          type: NotificationType.streetSweeping,
          scheduledTime: dayBefore,
          data: {
            'street_sweeping_id': schedule.id,
            'street_name': schedule.streetName,
          },
        );
      }

      // 1-hour advance notice
      final hourBefore = schedule.startTime.subtract(const Duration(hours: 1));
      if (hourBefore.isAfter(DateTime.now())) {
        await scheduleNotification(
          title: 'Street Sweeping in 1 Hour',
          body:
              'Move your vehicle from ${schedule.streetName}. Sweeping starts at ${_formatTime(schedule.startTime)}',
          type: NotificationType.streetSweeping,
          scheduledTime: hourBefore,
          data: {
            'street_sweeping_id': schedule.id,
            'street_name': schedule.streetName,
            'urgent': true,
          },
        );
      }
    }
  }

  // Schedule parking reminder notifications
  Future<void> scheduleParkingReminder(ParkingReservation reservation) async {
    final isEnabled = await StorageService.isNotificationEnabled(
      'parking_reminders',
    );
    if (!isEnabled) return;

    // Reservation confirmation
    await scheduleNotification(
      title: 'Parking Reserved',
      body:
          'Your parking spot is confirmed for ${_formatDateTime(reservation.startTime)}',
      type: NotificationType.reservationConfirmation,
      scheduledTime: DateTime.now(),
      data: {'reservation_id': reservation.id, 'spot_id': reservation.spotId},
    );

    // 15-minute reminder before reservation starts
    final reminderTime = reservation.startTime.subtract(
      const Duration(minutes: 15),
    );
    if (reminderTime.isAfter(DateTime.now())) {
      await scheduleNotification(
        title: 'Parking Reminder',
        body: 'Your parking reservation starts in 15 minutes',
        type: NotificationType.parkingReminder,
        scheduledTime: reminderTime,
        data: {'reservation_id': reservation.id, 'spot_id': reservation.spotId},
      );
    }

    // 15-minute reminder before reservation ends
    final endReminderTime = reservation.endTime.subtract(
      const Duration(minutes: 15),
    );
    if (endReminderTime.isAfter(DateTime.now())) {
      await scheduleNotification(
        title: 'Parking Ending Soon',
        body: 'Your parking reservation expires in 15 minutes',
        type: NotificationType.parkingReminder,
        scheduledTime: endReminderTime,
        data: {
          'reservation_id': reservation.id,
          'spot_id': reservation.spotId,
          'ending': true,
        },
      );
    }
  }

  // Schedule permit expiry notifications
  Future<void> schedulePermitExpiryNotification(Permit permit) async {
    final isEnabled = await StorageService.isNotificationEnabled(
      'permit_expiry',
    );
    if (!isEnabled) return;

    // 7 days before expiry
    final weekBefore = permit.endDate.subtract(const Duration(days: 7));
    if (weekBefore.isAfter(DateTime.now())) {
      await scheduleNotification(
        title: 'Permit Expiring Soon',
        body:
            'Your ${permit.type.toString().split('.').last} permit expires in 7 days',
        type: NotificationType.permitExpiry,
        scheduledTime: weekBefore,
        data: {
          'permit_id': permit.id,
          'permit_type': permit.type.toString().split('.').last,
        },
      );
    }

    // 1 day before expiry
    final dayBefore = permit.endDate.subtract(const Duration(days: 1));
    if (dayBefore.isAfter(DateTime.now())) {
      await scheduleNotification(
        title: 'Permit Expires Tomorrow',
        body:
            'Your ${permit.type.toString().split('.').last} permit expires tomorrow. Renew now to avoid interruption.',
        type: NotificationType.permitExpiry,
        scheduledTime: dayBefore,
        data: {
          'permit_id': permit.id,
          'permit_type': permit.type.toString().split('.').last,
          'urgent': true,
        },
      );
    }
  }

  // Send payment notifications
  Future<void> sendPaymentNotification({
    required bool success,
    required double amount,
    required String description,
    String? transactionId,
  }) async {
    final isEnabled = await StorageService.isNotificationEnabled(
      'payment_notifications',
    );
    if (!isEnabled) return;

    if (success) {
      await scheduleNotification(
        title: 'Payment Successful',
        body:
            'Payment of \$${amount.toStringAsFixed(2)} for $description was successful',
        type: NotificationType.paymentSuccess,
        scheduledTime: DateTime.now(),
        data: {
          'transaction_id': transactionId,
          'amount': amount,
          'description': description,
        },
      );
    } else {
      await scheduleNotification(
        title: 'Payment Failed',
        body:
            'Payment of \$${amount.toStringAsFixed(2)} for $description failed. Please try again.',
        type: NotificationType.paymentFailed,
        scheduledTime: DateTime.now(),
        data: {
          'transaction_id': transactionId,
          'amount': amount,
          'description': description,
        },
      );
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveNotifications();
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    await _saveNotifications();
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    await _saveNotifications();
  }

  // Clear old notifications (older than 30 days)
  Future<void> clearOldNotifications() async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    _notifications.removeWhere((n) => n.createdAt.isBefore(cutoffDate));
    await _saveNotifications();
  }

  // Get unread count
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Get notifications by type
  List<AppNotification> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  // Check for due notifications (mock implementation)
  void _schedulePeriodicCheck() {
    // In a real app, this would be handled by the system notification scheduler
    // For development purposes, we'll simulate checking for due notifications
    Future.delayed(const Duration(minutes: 1), () {
      _checkForDueNotifications();
      _schedulePeriodicCheck(); // Reschedule
    });
  }

  void _checkForDueNotifications() {
    final now = DateTime.now();
    final dueNotifications = _notifications.where(
      (n) =>
          n.scheduledTime.isBefore(now) &&
          !n.isRead &&
          n.scheduledTime.isAfter(now.subtract(const Duration(minutes: 5))),
    );

    for (final notification in dueNotifications) {
      _showNotification(notification);
    }
  }

  // Mock system notification (in production, use flutter_local_notifications)
  void _mockScheduleSystemNotification(AppNotification notification) {
    debugPrint(
      'Scheduled notification: ${notification.title} - ${notification.body}',
    );
    debugPrint('Scheduled for: ${notification.scheduledTime}');
  }

  void _showNotification(AppNotification notification) {
    debugPrint(
      'Showing notification: ${notification.title} - ${notification.body}',
    );
    // In a real app, this would trigger a system notification
  }

  // Utility methods
  String _generateNotificationId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return 'notif_${List.generate(8, (index) => chars[random.nextInt(chars.length)]).join()}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} at ${_formatTime(dateTime)}';
  }
}
