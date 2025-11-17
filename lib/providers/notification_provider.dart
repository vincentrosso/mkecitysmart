import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../models/street_sweeping.dart';
import '../models/parking_reservation.dart';
import '../models/permit.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Notification settings
  bool _streetSweepingEnabled = true;
  bool _parkingRemindersEnabled = true;
  bool _permitExpiryEnabled = true;
  bool _paymentNotificationsEnabled = true;

  // Getters
  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  List<AppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  bool get streetSweepingEnabled => _streetSweepingEnabled;
  bool get parkingRemindersEnabled => _parkingRemindersEnabled;
  bool get permitExpiryEnabled => _permitExpiryEnabled;
  bool get paymentNotificationsEnabled => _paymentNotificationsEnabled;

  Future<void> initialize() async {
    _setLoading(true);
    _clearError();

    try {
      await _notificationService.initialize();
      await _loadNotificationSettings();
      _notifications = _notificationService.notifications;
    } catch (e) {
      _setError('Error initializing notifications: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadNotificationSettings() async {
    _streetSweepingEnabled = await StorageService.isNotificationEnabled(
      'street_sweeping',
    );
    _parkingRemindersEnabled = await StorageService.isNotificationEnabled(
      'parking_reminders',
    );
    _permitExpiryEnabled = await StorageService.isNotificationEnabled(
      'permit_expiry',
    );
    _paymentNotificationsEnabled = await StorageService.isNotificationEnabled(
      'payment_notifications',
    );
    notifyListeners();
  }

  Future<void> setStreetSweepingEnabled(bool enabled) async {
    _streetSweepingEnabled = enabled;
    await StorageService.setNotificationEnabled('street_sweeping', enabled);
    notifyListeners();
  }

  Future<void> setParkingRemindersEnabled(bool enabled) async {
    _parkingRemindersEnabled = enabled;
    await StorageService.setNotificationEnabled('parking_reminders', enabled);
    notifyListeners();
  }

  Future<void> setPermitExpiryEnabled(bool enabled) async {
    _permitExpiryEnabled = enabled;
    await StorageService.setNotificationEnabled('permit_expiry', enabled);
    notifyListeners();
  }

  Future<void> setPaymentNotificationsEnabled(bool enabled) async {
    _paymentNotificationsEnabled = enabled;
    await StorageService.setNotificationEnabled(
      'payment_notifications',
      enabled,
    );
    notifyListeners();
  }

  Future<void> scheduleNotification({
    required String title,
    required String body,
    required NotificationType type,
    required DateTime scheduledTime,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _notificationService.scheduleNotification(
        title: title,
        body: body,
        type: type,
        scheduledTime: scheduledTime,
        data: data,
      );
      _notifications = _notificationService.notifications;
      notifyListeners();
    } catch (e) {
      _setError('Error scheduling notification: ${e.toString()}');
    }
  }

  Future<void> scheduleStreetSweepingNotifications(
    List<StreetSweeping> schedules,
  ) async {
    if (!_streetSweepingEnabled) return;

    try {
      await _notificationService.scheduleStreetSweepingNotifications(schedules);
      _notifications = _notificationService.notifications;
      notifyListeners();
    } catch (e) {
      _setError(
        'Error scheduling street sweeping notifications: ${e.toString()}',
      );
    }
  }

  Future<void> scheduleParkingReminder(ParkingReservation reservation) async {
    if (!_parkingRemindersEnabled) return;

    try {
      await _notificationService.scheduleParkingReminder(reservation);
      _notifications = _notificationService.notifications;
      notifyListeners();
    } catch (e) {
      _setError('Error scheduling parking reminder: ${e.toString()}');
    }
  }

  Future<void> schedulePermitExpiryNotification(Permit permit) async {
    if (!_permitExpiryEnabled) return;

    try {
      await _notificationService.schedulePermitExpiryNotification(permit);
      _notifications = _notificationService.notifications;
      notifyListeners();
    } catch (e) {
      _setError('Error scheduling permit expiry notification: ${e.toString()}');
    }
  }

  Future<void> sendPaymentNotification({
    required bool success,
    required double amount,
    required String description,
    String? transactionId,
  }) async {
    if (!_paymentNotificationsEnabled) return;

    try {
      await _notificationService.sendPaymentNotification(
        success: success,
        amount: amount,
        description: description,
        transactionId: transactionId,
      );
      _notifications = _notificationService.notifications;
      notifyListeners();
    } catch (e) {
      _setError('Error sending payment notification: ${e.toString()}');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      _notifications = _notificationService.notifications;
      notifyListeners();
    } catch (e) {
      _setError('Error marking notification as read: ${e.toString()}');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      _notifications = _notificationService.notifications;
      notifyListeners();
    } catch (e) {
      _setError('Error marking all notifications as read: ${e.toString()}');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      _notifications = _notificationService.notifications;
      notifyListeners();
    } catch (e) {
      _setError('Error deleting notification: ${e.toString()}');
    }
  }

  Future<void> clearOldNotifications() async {
    try {
      await _notificationService.clearOldNotifications();
      _notifications = _notificationService.notifications;
      notifyListeners();
    } catch (e) {
      _setError('Error clearing old notifications: ${e.toString()}');
    }
  }

  List<AppNotification> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}
