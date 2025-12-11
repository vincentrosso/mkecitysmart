import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

/// Attempts to initialize Firebase using the platform
/// default files (GoogleService-Info.plist / google-services.json) or dart-defines.
/// Returns `true` when Firebase ends up ready, or `false` if configuration is missing.
Future<bool> initializeFirebaseIfAvailable() async {
  if (Firebase.apps.isNotEmpty) return true;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } catch (err, stack) {
    log(
      'Firebase config missing for ${defaultTargetPlatform.name}: $err',
      stackTrace: stack,
    );
    return false;
  }
}