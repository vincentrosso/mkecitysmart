import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseResilienceService {
  FirebaseResilienceService._();
  static final FirebaseResilienceService instance =
      FirebaseResilienceService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  Future<bool> refreshAuthToken() async {
    final user = _auth.currentUser;
    if (user == null) {
      await ensureAuthReady();
      return _auth.currentUser != null;
    }

    try {
      await user.getIdToken(true);
      return true;
    } catch (e) {
      debugPrint('[FirebaseResilience] Token refresh failed: $e');
      return false;
    }
  }

  bool isAuthError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('permission-denied') ||
        message.contains('unauthenticated') ||
        message.contains('auth') && message.contains('token');
  }
}
