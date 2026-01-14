import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CloudLogService {
  CloudLogService._();
  static final CloudLogService instance = CloudLogService._();

  FirebaseFirestore? _firestore;
  bool _enabled = false;
  bool _initialized = false;
  void Function(FlutterErrorDetails details)? _originalFlutterErrorHandler;

  Future<void> initialize({required bool firebaseReady}) async {
    if (_initialized) return;
    _initialized = true;
    if (!firebaseReady) {
      debugPrint('[CloudLog] Firebase unavailable; logging disabled.');
      return;
    }
    // Skip Firestore logging on web to avoid JS interop/network hangs when
    // Firestore isn't configured for the web target.
    if (kIsWeb) {
      debugPrint('[CloudLog] Disabled on web build.');
      return;
    }
    try {
      _firestore = FirebaseFirestore.instance;
      _enabled = true;
      _hookFlutterErrors();
      await logEvent('app_bootstrap');
      debugPrint('[CloudLog] initialized');
    } catch (err) {
      debugPrint('[CloudLog] init failed: $err');
      _enabled = false;
    }
  }

  Future<void> logEvent(String name, {Map<String, dynamic>? data}) async {
    if (!_enabled || _firestore == null) return;
    final payload = <String, dynamic>{
      'event': name,
      'createdAt': FieldValue.serverTimestamp(),
      'data': data ?? <String, dynamic>{},
    };
    try {
      await _firestore!.collection('appLogs').add(payload);
    } catch (err) {
      debugPrint('[CloudLog] logEvent failed for $name: $err');
    }
  }

  Future<void> recordError(
    String context,
    Object error,
    StackTrace stack, {
    bool fatal = false,
  }) async {
    await logEvent(
      'error',
      data: {
        'context': context,
        'message': error.toString(),
        'stack': stack.toString(),
        'fatal': fatal,
      },
    );
  }

  void _hookFlutterErrors() {
    _originalFlutterErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      recordError('flutter_error', details.exception, details.stack ?? StackTrace.current);
      _originalFlutterErrorHandler?.call(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      recordError('platform_error', error, stack, fatal: true);
      return false;
    };
  }
}
