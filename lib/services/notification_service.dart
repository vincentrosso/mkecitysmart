import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../firebase_bootstrap.dart';
import 'cloud_log_service.dart';
import 'push_diagnostics_service.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  FirebaseMessaging? _messaging;
  final _local = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  Future<bool> Function()? _canReceiveAlertCallback;

  Future<void> initialize({required bool enableRemoteNotifications}) async {
    if (_initialized) return;
    // Skip push setup on web to avoid service worker/service constraints unless configured.
    if (kIsWeb) {
      _initialized = true;
      return;
    }
    try {
      await _setupLocalNotifications();
      if (!enableRemoteNotifications) {
        log(
          'Push notifications disabled; init limited to local notifications.',
        );
        CloudLogService.instance.logEvent('push_notifications_disabled');
        _initTimeZones();
        _initialized = true;
        return;
      }
      if (Firebase.apps.isEmpty && !await initializeFirebaseIfAvailable()) {
        log('Skipping push notifications (Firebase unavailable).');
        _initTimeZones();
        _initialized = true;
        return;
      }
      _messaging = FirebaseMessaging.instance;
      await _requestPermissions();
      await _registerToken();
      await _subscribeToAlertsTopic();
      _listenForTokenRefresh();
      _listenForMessageOpens();
      await _handleInitialMessage();
      _initTimeZones();
      CloudLogService.instance.logEvent('push_notifications_enabled');

      FirebaseMessaging.onMessage.listen((message) async {
        final notification = message.notification;
        final android = message.notification?.android;
        if (notification != null) {
          final canReceive =
              await (_canReceiveAlertCallback?.call() ?? Future.value(true));
          if (canReceive) {
            _local.show(
              notification.hashCode,
              notification.title,
              notification.body,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  'risk_alerts',
                  'Risk Alerts',
                  importance: Importance.high,
                  icon: android?.smallIcon,
                ),
                iOS: const DarwinNotificationDetails(),
              ),
            );
          }
        }
      });
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      _initialized = true;
    } catch (e) {
      log('Notification init skipped: $e');
      _initialized = true;
    }
  }

  Future<void> showLocal({required String title, required String body}) async {
    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'risk_alerts',
          'Risk Alerts',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> scheduleLocal({
    required String title,
    required String body,
    required DateTime when,
    int? id,
  }) async {
    // Skip if the scheduled time has already passed
    if (when.isBefore(DateTime.now())) return;

    try {
      final tzWhen = tz.TZDateTime.from(when, tz.local);
      final notificationId = id ?? when.millisecondsSinceEpoch ~/ 1000;

      await _local.zonedSchedule(
        notificationId,
        title,
        body,
        tzWhen,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'garbage_reminders',
            'Garbage & Recycling Reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: null,
      );
    } catch (e) {
      // Fallback to immediate notification if scheduling fails
      log('Failed to schedule notification: $e');
      await showLocal(title: title, body: body);
    }
  }

  /// Schedule repeating reminders every 30 minutes until a cutoff time
  Future<void> scheduleRepeatingReminders({
    required String title,
    required String body,
    required DateTime startTime,
    required DateTime cutoffTime,
    required int baseId,
  }) async {
    var currentTime = startTime;
    var idOffset = 0;

    while (currentTime.isBefore(cutoffTime)) {
      if (currentTime.isAfter(DateTime.now())) {
        await scheduleLocal(
          title: title,
          body: body,
          when: currentTime,
          id: baseId + idOffset,
        );
      }
      currentTime = currentTime.add(const Duration(minutes: 30));
      idOffset++;
    }
  }

  /// Cancel all pending notifications
  Future<void> cancelAllScheduled() async {
    await _local.cancelAll();
  }

  /// Cancel a specific notification by ID
  Future<void> cancelScheduled(int id) async {
    await _local.cancel(id);
  }

  // ──────────────────────────────────────────────────────────────────────
  //  Alternate Side Parking – daily scheduled notifications
  // ──────────────────────────────────────────────────────────────────────

  /// Stable IDs so we can cancel/replace without leaking notifications.
  static const int _aspMorningId = 900001;
  static const int _aspEveningId = 900002;
  static const int _aspMidnightId = 900003;

  /// Schedule (or reschedule) the three alternate-side parking notifications
  /// based on the user's current toggle states.  Call this at startup and
  /// whenever the user changes a toggle.
  Future<void> syncAspNotifications({
    required bool morningEnabled,
    required bool eveningEnabled,
    required bool midnightEnabled,
  }) async {
    // Cancel existing ASP notifications first
    await _local.cancel(_aspMorningId);
    await _local.cancel(_aspEveningId);
    await _local.cancel(_aspMidnightId);

    const aspDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'asp_reminders',
        'Alternate Side Parking',
        channelDescription: 'Daily alternate side parking reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      if (morningEnabled) {
        final morning = _nextOccurrence(hour: 7, minute: 0);
        await _local.zonedSchedule(
          _aspMorningId,
          '☀️ Morning Parking Reminder',
          _aspBodyForDate(morning),
          morning,
          aspDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time, // repeats daily
        );
      }

      if (eveningEnabled) {
        final evening = _nextOccurrence(hour: 21, minute: 0);
        await _local.zonedSchedule(
          _aspEveningId,
          '🌙 Evening Parking Warning',
          _aspEveningBody(evening),
          evening,
          aspDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }

      if (midnightEnabled) {
        final midnight = _nextOccurrence(hour: 0, minute: 0);
        await _local.zonedSchedule(
          _aspMidnightId,
          '🚨 Parking Side Changed!',
          _aspBodyForDate(midnight),
          midnight,
          aspDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }

      log(
        'ASP notifications synced – morning:$morningEnabled '
        'evening:$eveningEnabled midnight:$midnightEnabled',
      );
    } catch (e) {
      log('Failed to schedule ASP notifications: $e');
    }
  }

  /// Returns the next [tz.TZDateTime] for the given hour/minute.
  tz.TZDateTime _nextOccurrence({required int hour, required int minute}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Build a body string for the morning/midnight notification.
  String _aspBodyForDate(tz.TZDateTime date) {
    final isOdd = date.day % 2 == 1;
    final side = isOdd ? 'odd' : 'even';
    return 'Today is day ${date.day} ($side). '
        'Park on the $side-numbered side of the street.';
  }

  /// Build a body string for the evening warning.
  String _aspEveningBody(tz.TZDateTime date) {
    final tomorrow = date.add(const Duration(days: 1));
    final isOdd = tomorrow.day % 2 == 1;
    final side = isOdd ? 'odd' : 'even';
    return 'Tomorrow is day ${tomorrow.day} ($side). '
        'Move your car to the $side-numbered side before midnight.';
  }

  Future<void> _requestPermissions() async {
    if (_messaging == null) return;
    final settings = await _messaging!.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      sound: true,
    );

    // Enable foreground notification presentation on iOS
    await _messaging!.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    PushDiagnosticsService.instance.recordPermission(settings);
    log('Notification permission: ${settings.authorizationStatus}');
    CloudLogService.instance.logEvent(
      'push_permission_prompt',
      data: {'status': settings.authorizationStatus.name},
    );
  }

  Future<void> _setupLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: android, iOS: ios);
    await _local.initialize(initSettings);

    const channel = AndroidNotificationChannel(
      'risk_alerts',
      'Risk Alerts',
      description: 'Tow/ticket risk notifications',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> _registerToken() async {
    if (_messaging == null) return;
    try {
      final token = await _messaging!.getToken();
      if (token == null) return;
      PushDiagnosticsService.instance.recordFcmToken(token);

      final positionResult = await _getBestEffortPositionWithDiagnostics();
      PushDiagnosticsService.instance.recordLocationDiagnostics(
        positionResult.diagnostics,
      );
      final position = positionResult.position;
      final callable = FirebaseFunctions.instance.httpsCallable(
        'registerDevice',
      );
      await callable.call({
        'token': token,
        'platform': _platform(),
        if (position != null) 'latitude': position.latitude,
        if (position != null) 'longitude': position.longitude,
        if (position != null) 'locationPrecisionMeters': position.accuracy,
      });
      PushDiagnosticsService.instance.recordRegisterAttempt(success: true);
      log('Registered push token: $token');
      CloudLogService.instance.logEvent(
        'push_token_registered',
        data: {
          'platform': _platform(),
          'hasLocation': position != null,
          ...positionResult.diagnostics,
        },
      );
    } catch (e) {
      PushDiagnosticsService.instance.recordRegisterAttempt(
        success: false,
        error: e,
      );
      log('Failed to register push token: $e');
      CloudLogService.instance.recordError(
        'push_token_register_failed',
        e,
        StackTrace.current,
      );
    }
  }

  Future<void> _subscribeToAlertsTopic() async {
    if (_messaging == null) return;
    try {
      await _messaging!.subscribeToTopic('alerts');
      log('Subscribed to alerts topic');
      CloudLogService.instance.logEvent('subscribed_to_alerts_topic');
    } catch (e) {
      log('Failed to subscribe to alerts topic: $e');
      CloudLogService.instance.recordError(
        'alerts_topic_subscription_failed',
        e,
        StackTrace.current,
      );
    }
  }

  void setAlertLimitCallback(Future<bool> Function() callback) {
    _canReceiveAlertCallback = callback;
  }

  void _listenForTokenRefresh() {
    if (_messaging == null) return;
    _messaging!.onTokenRefresh.listen((token) async {
      try {
        PushDiagnosticsService.instance.recordFcmToken(token);
        final positionResult = await _getBestEffortPositionWithDiagnostics();
        PushDiagnosticsService.instance.recordLocationDiagnostics(
          positionResult.diagnostics,
        );
        final position = positionResult.position;
        final callable = FirebaseFunctions.instance.httpsCallable(
          'registerDevice',
        );
        await callable.call({
          'token': token,
          'platform': _platform(),
          if (position != null) 'latitude': position.latitude,
          if (position != null) 'longitude': position.longitude,
          if (position != null) 'locationPrecisionMeters': position.accuracy,
        });
        PushDiagnosticsService.instance.recordRegisterAttempt(success: true);
        log('Refreshed push token: $token');
        CloudLogService.instance.logEvent(
          'push_token_refreshed',
          data: {
            'platform': _platform(),
            'hasLocation': position != null,
            ...positionResult.diagnostics,
          },
        );
      } catch (e) {
        PushDiagnosticsService.instance.recordRegisterAttempt(
          success: false,
          error: e,
        );
        log('Failed to refresh push token: $e');
        CloudLogService.instance.recordError(
          'push_token_refresh_failed',
          e,
          StackTrace.current,
        );
      }
    });
  }

  void _listenForMessageOpens() {
    if (_messaging == null) return;
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      log('Push opened: ${message.messageId}');
      CloudLogService.instance.logEvent(
        'push_opened',
        data: {'messageId': message.messageId},
      );
    });
  }

  /// Re-register the FCM token with the current authenticated user.
  /// Call this after sign-in completes to ensure the token is associated
  /// with the correct UID (not an anonymous auth UID from app startup).
  Future<void> reregisterTokenAfterSignIn() async {
    if (_messaging == null || !_initialized) return;
    try {
      await _registerToken();
      log('Re-registered push token after sign-in');
      CloudLogService.instance.logEvent('push_token_reregistered_after_signin');
    } catch (e) {
      log('Failed to re-register push token after sign-in: $e');
      CloudLogService.instance.recordError(
        'push_token_reregister_failed',
        e,
        StackTrace.current,
      );
    }
  }

  Future<void> _handleInitialMessage() async {
    if (_messaging == null) return;
    final message = await _messaging!.getInitialMessage();
    if (message == null) return;
    log('Push launched app: ${message.messageId}');
    CloudLogService.instance.logEvent(
      'push_launch',
      data: {'messageId': message.messageId},
    );
  }

  void _initTimeZones() {
    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('America/Chicago'));
    } catch (_) {
      // Best-effort.
    }
  }
}

class _BestEffortPositionResult {
  final Position? position;
  final Map<String, Object?> diagnostics;

  const _BestEffortPositionResult({
    required this.position,
    required this.diagnostics,
  });
}

Future<_BestEffortPositionResult>
_getBestEffortPositionWithDiagnostics() async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    var permission = await Geolocator.checkPermission();
    final permissionBefore = permission;
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    final diagnostics = <String, Object?>{
      'locationServiceEnabled': serviceEnabled,
      'locationPermissionBefore': permissionBefore.toString(),
      'locationPermissionAfter': permission.toString(),
    };

    if (!serviceEnabled) {
      return _BestEffortPositionResult(
        position: null,
        diagnostics: diagnostics,
      );
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return _BestEffortPositionResult(
        position: null,
        diagnostics: diagnostics,
      );
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 8),
      ),
    );
    return _BestEffortPositionResult(position: pos, diagnostics: diagnostics);
  } catch (e) {
    return _BestEffortPositionResult(
      position: null,
      diagnostics: <String, Object?>{'locationError': e.toString()},
    );
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await initializeFirebaseIfAvailable();
  }
  // Optionally handle background payloads for risk alerts.
}

String _platform() => kIsWeb ? 'web' : 'mobile';

// Re-export for consumers if needed.
String platformLabel() => _platform();
