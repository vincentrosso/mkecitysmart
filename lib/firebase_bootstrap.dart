import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

/// Attempts to initialize Firebase using the platform
/// default files (GoogleService-Info.plist / google-services.json) or dart-defines.
/// Returns `true` when Firebase ends up ready, or `false` if configuration is missing.
Future<bool> initializeFirebaseIfAvailable() async {
  if (Firebase.apps.isNotEmpty) return true;

  debugPrint('[Bootstrap] Starting Firebase init for ${kIsWeb ? 'web' : defaultTargetPlatform.name}...');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // If running in debug mode, point Firebase clients at the local emulators.
    // Adjust ports as needed to match your `firebase emulators:start` output.
    // if (kDebugMode) {
    //   // Use the standard emulator defaults. If you start emulators with
    //   // custom ports, update these values to match the `firebase emulators:start` output.
    //   try {
    //     FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
    //   } catch (_) {}
    //   try {
    //     FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    //   } catch (_) {}
    //   try {
    //     // Auth emulator is set to 9199 in firebase.json (avoid local conflicts)
    //     FirebaseAuth.instance.useAuthEmulator('localhost', 9199);
    //   } catch (_) {}
    // }
    debugPrint('[Bootstrap] Firebase init OK');
    return true;
  } catch (err, stack) {
    debugPrint('[Bootstrap] Firebase init FAILED: $err');
    log(
      'Firebase config missing for ${defaultTargetPlatform.name}: $err',
      stackTrace: stack,
    );
    return false;
  }
}
