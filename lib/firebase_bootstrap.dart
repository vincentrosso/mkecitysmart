import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

/// Firestore cache settings for offline support and performance
/// These settings enable local caching to reduce reads and improve UX
class FirestoreCacheConfig {
  /// Maximum cache size in bytes (100 MB default, good for scalability)
  static const int maxCacheSizeBytes = 100 * 1024 * 1024;
  
  /// Enable persistence for offline support
  static const bool persistenceEnabled = true;
}

/// Attempts to initialize Firebase using the platform
/// default files (GoogleService-Info.plist / google-services.json) or dart-defines.
/// Returns `true` when Firebase ends up ready, or `false` if configuration is missing.
Future<bool> initializeFirebaseIfAvailable() async {
  if (Firebase.apps.isNotEmpty) return true;

  debugPrint(
    '[Bootstrap] Starting Firebase init for ${kIsWeb ? 'web' : defaultTargetPlatform.name}...',
  );
  try {
    // Guardrail: avoid crashing release/TestFlight when the iOS plist is the
    // placeholder test config (e.g. API_KEY=TEST_API_KEY / projectId=test-project).
    // In that case we treat Firebase as "not available" and let the app run
    // without Firebase-backed features.
    final options = DefaultFirebaseOptions.currentPlatform;

    bool looksLikePlaceholderConfig() {
      final apiKey = options.apiKey.trim();
      final projectId = options.projectId.trim();
      final iOSBundleId = options.iosBundleId?.trim() ?? '';

      if (apiKey.isEmpty || projectId.isEmpty) return true;
      if (apiKey.toUpperCase().contains('TEST')) return true;
      if (projectId.toLowerCase().contains('test-')) return true;
      if (iOSBundleId.isNotEmpty && iOSBundleId.startsWith('com.example.')) return true;
      return false;
    }

    // Safe, non-secret identifiers that help debug TestFlight configuration.
    debugPrint(
      '[Bootstrap] Firebase options: projectId=${options.projectId}, appId=${options.appId}, iosBundleId=${options.iosBundleId ?? '(none)'}',
    );

    if (!kDebugMode && looksLikePlaceholderConfig()) {
      debugPrint(
        '[Bootstrap] Firebase init SKIPPED: config looks like placeholder (release).',
      );
      debugPrint(
        '[Bootstrap] If this is unexpected, re-download iOS GoogleService-Info.plist for bundle id com.mkecitysmart.app and rebuild.',
      );
      return false;
    }

    await Firebase.initializeApp(options: options);
    
    // Configure Firestore for better offline support and performance
    // This enables local caching to reduce reads and improve scalability
    try {
      FirebaseFirestore.instance.settings = Settings(
        persistenceEnabled: FirestoreCacheConfig.persistenceEnabled,
        cacheSizeBytes: FirestoreCacheConfig.maxCacheSizeBytes,
      );
      debugPrint('[Bootstrap] Firestore persistence enabled (${FirestoreCacheConfig.maxCacheSizeBytes ~/ (1024 * 1024)} MB cache)');
    } catch (e) {
      // Settings may already be set, ignore
      debugPrint('[Bootstrap] Firestore settings already configured');
    }
    
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
    debugPrint(
      '[Bootstrap] When Firebase is disabled on iOS TestFlight, check: (1) correct GoogleService-Info.plist, (2) Firebase Console → Cloud Messaging APNs key, (3) aps-environment entitlement.',
    );
    log(
      'Firebase config missing for ${defaultTargetPlatform.name}: $err',
      stackTrace: stack,
    );
    return false;
  }
}
