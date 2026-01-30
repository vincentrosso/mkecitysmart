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
  Map<String, Object?>? _lastLocationDiagnostics;

  NotificationSettings? get lastPermission => _lastPermission;
  String? get lastFcmToken => _lastFcmToken;
  DateTime? get lastFcmTokenTime => _lastFcmTokenTime;
  Object? get lastRegisterError => _lastRegisterError;
  DateTime? get lastRegisterAttemptTime => _lastRegisterAttemptTime;
  bool? get lastRegisterSuccess => _lastRegisterSuccess;
  Map<String, Object?>? get lastLocationDiagnostics => _lastLocationDiagnostics;

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

  void recordLocationDiagnostics(Map<String, Object?> diagnostics) {
    _lastLocationDiagnostics = diagnostics.isEmpty ? null : diagnostics;
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
      final details = error.details;
      String detailsStr = '';
      
      // Try to extract FCM error code from details map
      if (details is Map) {
        final message = details['message'];
        if (message is String) {
          // Decode common FCM error codes
          final fcmCode = _decodeFcmErrorCode(message);
          if (fcmCode.isNotEmpty) {
            detailsStr = ' [$fcmCode]';
          } else if (message.isNotEmpty) {
            detailsStr = ' message=$message';
          }
        }
      } else if (details != null) {
        detailsStr = ' details=$details';
      }
      
      return 'functions/${error.code}: ${error.message ?? 'Unknown error.'}$detailsStr';
    }
    return error?.toString();
  }

  /// Decode common FCM error messages to user-friendly error codes.
  static String _decodeFcmErrorCode(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('registration-token-not-registered')) {
      return 'FCM_TOKEN_NOT_REGISTERED: Token not registered with Firebase Messaging';
    }
    if (lower.contains('invalid-argument') || lower.contains('invalid.*token')) {
      return 'FCM_INVALID_TOKEN: Token format is invalid or corrupted';
    }
    if (lower.contains('authentication-error') || lower.contains('unauthorized')) {
      return 'FCM_AUTH_ERROR: Firebase Messaging authentication failed';
    }
    if (lower.contains('instance-id-error')) {
      return 'FCM_INSTANCE_ERROR: Firebase Instance ID service error';
    }
    if (lower.contains('service-unavailable')) {
      return 'FCM_UNAVAILABLE: Firebase Messaging service temporarily unavailable';
    }
    return '';
  }

  static String redactToken(String? token) {
    if (token == null || token.isEmpty) return '(none)';
    if (token.length <= 10) return '***';
    return '${token.substring(0, 6)}…${token.substring(token.length - 4)}';
  }
}
