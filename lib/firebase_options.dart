// Firebase configuration resolved via --dart-define secrets at build time.
// Required defines:
//   FIREBASE_WEB_API_KEY
//   FIREBASE_ANDROID_API_KEY
//   FIREBASE_IOS_API_KEY
//
// Example:
// flutter run --dart-define=FIREBASE_WEB_API_KEY=xxx \
//   --dart-define=FIREBASE_ANDROID_API_KEY=yyy \
//   --dart-define=FIREBASE_IOS_API_KEY=zzz

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  // Hard-coded API keys to avoid dart-define requirements.
  // Values sourced from platform configs (GoogleService-Info.plist / google-services.json).
  static const String _webApiKey = 'AIzaSyB-I3Fa-4bmR-rB-jngHkgWQnjTTHTBZDo';
  static const String _androidApiKey = 'AIzaSyBaT4ZkDKVhwjiFwYCEhhf8c1Sd0xvnf_g';
  static const String _iosApiKey = 'AIzaSyB-I3Fa-4bmR-rB-jngHkgWQnjTTHTBZDo';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: _webApiKey,
        appId: const String.fromEnvironment(
          'FIREBASE_WEB_APP_ID',
          defaultValue: '1:418926446148:web:0e080d9bf8a7ea04631e11',
        ),
        messagingSenderId: const String.fromEnvironment(
          'FIREBASE_WEB_MSG_SENDER_ID',
          defaultValue: '418926446148',
        ),
        projectId: const String.fromEnvironment(
          'FIREBASE_WEB_PROJECT_ID',
          defaultValue: 'mkeparkapp-1ad15',
        ),
        authDomain: const String.fromEnvironment(
          'FIREBASE_WEB_AUTH_DOMAIN',
          defaultValue: 'mkeparkapp-1ad15.web.app',
        ),
        storageBucket: const String.fromEnvironment(
          'FIREBASE_WEB_STORAGE_BUCKET',
          defaultValue: 'mkeparkapp-1ad15.firebasestorage.app',
        ),
        measurementId: const String.fromEnvironment(
          'FIREBASE_WEB_MEASUREMENT_ID',
          defaultValue: 'G-DBEX7GBTPT',
        ),
      );

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: _androidApiKey,
        appId: const String.fromEnvironment(
          'FIREBASE_ANDROID_APP_ID',
          defaultValue: '1:802081773281:android:55de0e46223bddcf0009a0',
        ),
        messagingSenderId: const String.fromEnvironment(
          'FIREBASE_ANDROID_MSG_SENDER_ID',
          defaultValue: '802081773281',
        ),
        projectId: const String.fromEnvironment(
          'FIREBASE_ANDROID_PROJECT_ID',
          defaultValue: 'mkeparkapp-6edc3',
        ),
        storageBucket: const String.fromEnvironment(
          'FIREBASE_ANDROID_STORAGE_BUCKET',
          defaultValue: 'mkeparkapp-6edc3.firebasestorage.app',
        ),
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: _iosApiKey,
        appId: const String.fromEnvironment(
          'FIREBASE_IOS_APP_ID',
          defaultValue: '1:418926446148:ios:1077e2e334de8b7e631e11',
        ),
        messagingSenderId: const String.fromEnvironment(
          'FIREBASE_IOS_MSG_SENDER_ID',
          defaultValue: '418926446148',
        ),
        projectId: const String.fromEnvironment(
          'FIREBASE_IOS_PROJECT_ID',
          defaultValue: 'mkeparkapp-1ad15',
        ),
        storageBucket: const String.fromEnvironment(
          'FIREBASE_IOS_STORAGE_BUCKET',
          defaultValue: 'mkeparkapp-1ad15.firebasestorage.app',
        ),
        iosBundleId: const String.fromEnvironment(
          'FIREBASE_IOS_BUNDLE_ID',
          defaultValue: 'com.mkecitysmart.app',
        ),
      );

  static FirebaseOptions get macos => android;
  static FirebaseOptions get windows => android;
  static FirebaseOptions get linux => android;

}
