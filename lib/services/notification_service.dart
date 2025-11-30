import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../firebase_options.dart';
import 'api_client.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  FirebaseMessaging? _messaging;
  final _local = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    // Skip push setup on web to avoid service worker/service constraints unless configured.
    if (kIsWeb) {
      _initialized = true;
      return;
    }
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _messaging = FirebaseMessaging.instance;
      await _requestPermissions();
      await _setupLocalNotifications();
      await _registerToken();
      _initTimeZones();

      FirebaseMessaging.onMessage.listen((message) {
        final notification = message.notification;
        final android = message.notification?.android;
        if (notification != null) {
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
      });
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      _initialized = true;
    } catch (e) {
      log('Notification init skipped: $e');
      _initialized = true;
    }
  }

  Future<void> showLocal({
    required String title,
    required String body,
  }) async {
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
  }) async {
    // For web and to avoid API changes, fall back to an immediate local
    // notification instead of true scheduling.
    await showLocal(title: title, body: body);
  }

  Future<void> _requestPermissions() async {
    if (_messaging == null) return;
    final settings = await _messaging!.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      sound: true,
    );
    log('Notification permission: ${settings.authorizationStatus}');
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
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _registerToken() async {
    if (_messaging == null) return;
    try {
      final token = await _messaging!.getToken();
      if (token == null) return;
      final client = ApiClient();
      await client.post(
        '/devices/register',
        jsonBody: {
          'token': token,
          'platform': _platform(),
        },
      );
      log('Registered push token: $token');
    } catch (e) {
      log('Failed to register push token: $e');
    }
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

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Already initialized.
  }
  // Optionally handle background payloads for risk alerts.
}

String _platform() => kIsWeb ? 'web' : 'mobile';

// Re-export for consumers if needed.
String platformLabel() => _platform();
