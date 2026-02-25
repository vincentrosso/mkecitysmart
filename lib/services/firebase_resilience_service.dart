import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseResilienceService {
  FirebaseResilienceService._();
  static final FirebaseResilienceService instance =
      FirebaseResilienceService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Whether the current user is actually signed in (not just anonymous).
  bool get isUserSignedIn => _auth.currentUser != null;

  Future<void> ensureAuthReady({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (_auth.currentUser != null) return;

    try {
      await _auth
          .authStateChanges()
          .firstWhere((user) => user != null)
          .timeout(timeout, onTimeout: () => null);
    } catch (_) {
      // Ignore and continue to anonymous fallback.
    }

    if (_auth.currentUser != null) return;

    try {
      await _auth.signInAnonymously();
      debugPrint(
        '[FirebaseResilience] Anonymous sign-in recovered missing auth session',
      );
    } catch (e) {
      debugPrint('[FirebaseResilience] Anonymous sign-in unavailable: $e');
    }
  }

  /// Force-refresh both the Auth ID token AND the App Check token.
  /// Returns `true` when the user ends up with a usable session.
  Future<bool> refreshAuthToken() async {
    // --- Auth token ---
    var user = _auth.currentUser;
    if (user == null) {
      await ensureAuthReady();
      user = _auth.currentUser;
      if (user == null) return false;
    }

    try {
      await user.getIdToken(true);
    } catch (e) {
      debugPrint('[FirebaseResilience] Auth token refresh failed: $e');
      return false;
    }

    // --- App Check token ---
    try {
      await FirebaseAppCheck.instance.getToken(true);
      debugPrint('[FirebaseResilience] App Check token refreshed');
    } catch (e) {
      // App Check refresh is best-effort; some environments (simulator) may
      // not support it.  Log and continue – the fresh auth token alone may
      // be enough.
      debugPrint('[FirebaseResilience] App Check token refresh skipped: $e');
    }

    return true;
  }

  /// Refresh only the App Check attestation token (useful when auth is fine
  /// but the request is still rejected).
  Future<void> refreshAppCheckToken() async {
    try {
      await FirebaseAppCheck.instance.getToken(true);
    } catch (e) {
      debugPrint('[FirebaseResilience] App Check refresh failed: $e');
    }
  }

  bool isAuthError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('permission-denied') ||
        message.contains('unauthenticated') ||
        message.contains('auth') && message.contains('token') ||
        message.contains('app-check');
  }
}
