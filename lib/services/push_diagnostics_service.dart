import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'cloud_log_service.dart';

/// Captures push-notification runtime data so we can inspect it in TestFlight
/// without attaching Xcode.
class PushDiagnosticsService {
  PushDiagnosticsService._();
  static final PushDiagnosticsService instance = PushDiagnosticsService._();

  NotificationSettings? _lastPermission;
  String? _lastFcmToken;
  DateTime? _lastFcmTokenTime;
  Object? _lastRegisterError;
  DateTime? _lastRegisterAttemptTime;
  bool? _lastRegisterSuccess;

  NotificationSettings? get lastPermission => _lastPermission;
  String? get lastFcmToken => _lastFcmToken;
  DateTime? get lastFcmTokenTime => _lastFcmTokenTime;
  Object? get lastRegisterError => _lastRegisterError;
  DateTime? get lastRegisterAttemptTime => _lastRegisterAttemptTime;
  bool? get lastRegisterSuccess => _lastRegisterSuccess;

  void recordPermission(NotificationSettings settings) {
    _lastPermission = settings;
  }

  void recordFcmToken(String token) {
    _lastFcmToken = token;
    _lastFcmTokenTime = DateTime.now();
  }

  void recordRegisterAttempt({required bool success, Object? error}) {
    _lastRegisterAttemptTime = DateTime.now();
    _lastRegisterSuccess = success;
    _lastRegisterError = _formatFunctionsError(error);
  }

  /// Best-effort refresh of permission + FCM token even if NotificationService
  /// init was skipped.
  Future<void> refreshLocalSnapshot() async {
    try {
      final messaging = FirebaseMessaging.instance;
      _lastPermission = await messaging.getNotificationSettings();
      final token = await messaging.getToken();
      if (token != null) {
        recordFcmToken(token);
      }
    } catch (e, st) {
      // Don't throw. Snapshot is best-effort.
      CloudLogService.instance.recordError('push_diag_refresh_failed', e, st);
    }
  }

  /// Callable endpoint to validate end-to-end push delivery.
  Future<Map<String, dynamic>> sendTestPushToSelf({
    String? title,
    String? body,
  }) async {
    final token = _lastFcmToken ?? await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) {
      throw StateError('No FCM token available yet.');
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Sign in required to run push self-test.');
    }

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('testPushToSelf');
      final resp = await callable.call({
        'token': token,
        if (title != null) 'title': title,
        if (body != null) 'body': body,
      });

      return (resp.data as Map).cast<String, dynamic>();
    } catch (e) {
      throw StateError(_formatFunctionsError(e) ?? e.toString());
    }
  }

  /// Admin-only helper to simulate nearby fan-out.
  Future<Map<String, dynamic>> simulateNearbyWarning({
    required double latitude,
    required double longitude,
    double? radiusMiles,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Sign in required to run simulation.');
    }

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('simulateNearbyWarning');
      final resp = await callable.call({
        'latitude': latitude,
        'longitude': longitude,
        if (radiusMiles != null) 'radiusMiles': radiusMiles,
        'title': 'Test nearby warning',
        'body': 'This is a TestFlight diagnostic push',
      });

      return (resp.data as Map).cast<String, dynamic>();
    } catch (e) {
      throw StateError(_formatFunctionsError(e) ?? e.toString());
    }
  }

  String? _formatFunctionsError(Object? error) {
    if (error is FirebaseFunctionsException) {
      final details = error.details == null ? '' : ' details=${error.details}';
      return 'functions/${error.code}: ${error.message ?? 'Unknown error.'}$details';
    }
    return error?.toString();
  }

  static String redactToken(String? token) {
    if (token == null || token.isEmpty) return '(none)';
    if (token.length <= 10) return '***';
    return '${token.substring(0, 6)}…${token.substring(token.length - 4)}';
  }
}
