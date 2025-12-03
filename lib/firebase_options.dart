// Firebase configuration resolved via --dart-define secrets at build time.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_WEB_API_KEY',
      defaultValue: 'MISSING_FIREBASE_WEB_API_KEY',
    ),
    appId: String.fromEnvironment(
      'FIREBASE_WEB_APP_ID',
      defaultValue: 'MISSING_FIREBASE_WEB_APP_ID',
    ),
    messagingSenderId: String.fromEnvironment(
      'FIREBASE_WEB_MESSAGING_SENDER_ID',
      defaultValue: 'MISSING_FIREBASE_WEB_MESSAGING_SENDER_ID',
    ),
    projectId: String.fromEnvironment(
      'FIREBASE_WEB_PROJECT_ID',
      defaultValue: 'MISSING_FIREBASE_WEB_PROJECT_ID',
    ),
    authDomain: String.fromEnvironment(
      'FIREBASE_WEB_AUTH_DOMAIN',
      defaultValue: 'MISSING_FIREBASE_WEB_AUTH_DOMAIN',
    ),
    storageBucket: String.fromEnvironment(
      'FIREBASE_WEB_STORAGE_BUCKET',
      defaultValue: 'MISSING_FIREBASE_WEB_STORAGE_BUCKET',
    ),
    measurementId: String.fromEnvironment(
      'FIREBASE_WEB_MEASUREMENT_ID',
      defaultValue: 'MISSING_FIREBASE_WEB_MEASUREMENT_ID',
    ),
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_ANDROID_API_KEY',
      defaultValue: 'MISSING_FIREBASE_ANDROID_API_KEY',
    ),
    appId: String.fromEnvironment(
      'FIREBASE_ANDROID_APP_ID',
      defaultValue: 'MISSING_FIREBASE_ANDROID_APP_ID',
    ),
    messagingSenderId: String.fromEnvironment(
      'FIREBASE_ANDROID_MESSAGING_SENDER_ID',
      defaultValue: 'MISSING_FIREBASE_ANDROID_MESSAGING_SENDER_ID',
    ),
    projectId: String.fromEnvironment(
      'FIREBASE_ANDROID_PROJECT_ID',
      defaultValue: 'MISSING_FIREBASE_ANDROID_PROJECT_ID',
    ),
    storageBucket: String.fromEnvironment(
      'FIREBASE_ANDROID_STORAGE_BUCKET',
      defaultValue: 'MISSING_FIREBASE_ANDROID_STORAGE_BUCKET',
    ),
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_IOS_API_KEY',
      defaultValue: 'MISSING_FIREBASE_IOS_API_KEY',
    ),
    appId: String.fromEnvironment(
      'FIREBASE_IOS_APP_ID',
      defaultValue: 'MISSING_FIREBASE_IOS_APP_ID',
    ),
    messagingSenderId: String.fromEnvironment(
      'FIREBASE_IOS_MESSAGING_SENDER_ID',
      defaultValue: 'MISSING_FIREBASE_IOS_MESSAGING_SENDER_ID',
    ),
    projectId: String.fromEnvironment(
      'FIREBASE_IOS_PROJECT_ID',
      defaultValue: 'MISSING_FIREBASE_IOS_PROJECT_ID',
    ),
    storageBucket: String.fromEnvironment(
      'FIREBASE_IOS_STORAGE_BUCKET',
      defaultValue: 'MISSING_FIREBASE_IOS_STORAGE_BUCKET',
    ),
    iosBundleId: String.fromEnvironment(
      'FIREBASE_IOS_BUNDLE_ID',
      defaultValue: 'MISSING_FIREBASE_IOS_BUNDLE_ID',
    ),
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_MACOS_API_KEY',
      defaultValue: 'MISSING_FIREBASE_MACOS_API_KEY',
    ),
    appId: String.fromEnvironment(
      'FIREBASE_MACOS_APP_ID',
      defaultValue: 'MISSING_FIREBASE_MACOS_APP_ID',
    ),
    messagingSenderId: String.fromEnvironment(
      'FIREBASE_MACOS_MESSAGING_SENDER_ID',
      defaultValue: 'MISSING_FIREBASE_MACOS_MESSAGING_SENDER_ID',
    ),
    projectId: String.fromEnvironment(
      'FIREBASE_MACOS_PROJECT_ID',
      defaultValue: 'MISSING_FIREBASE_MACOS_PROJECT_ID',
    ),
    storageBucket: String.fromEnvironment(
      'FIREBASE_MACOS_STORAGE_BUCKET',
      defaultValue: 'MISSING_FIREBASE_MACOS_STORAGE_BUCKET',
    ),
    iosBundleId: String.fromEnvironment(
      'FIREBASE_MACOS_BUNDLE_ID',
      defaultValue: 'MISSING_FIREBASE_MACOS_BUNDLE_ID',
    ),
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_WINDOWS_API_KEY',
      defaultValue: 'MISSING_FIREBASE_WINDOWS_API_KEY',
    ),
    appId: String.fromEnvironment(
      'FIREBASE_WINDOWS_APP_ID',
      defaultValue: 'MISSING_FIREBASE_WINDOWS_APP_ID',
    ),
    messagingSenderId: String.fromEnvironment(
      'FIREBASE_WINDOWS_MESSAGING_SENDER_ID',
      defaultValue: 'MISSING_FIREBASE_WINDOWS_MESSAGING_SENDER_ID',
    ),
    projectId: String.fromEnvironment(
      'FIREBASE_WINDOWS_PROJECT_ID',
      defaultValue: 'MISSING_FIREBASE_WINDOWS_PROJECT_ID',
    ),
    authDomain: String.fromEnvironment(
      'FIREBASE_WINDOWS_AUTH_DOMAIN',
      defaultValue: 'MISSING_FIREBASE_WINDOWS_AUTH_DOMAIN',
    ),
    storageBucket: String.fromEnvironment(
      'FIREBASE_WINDOWS_STORAGE_BUCKET',
      defaultValue: 'MISSING_FIREBASE_WINDOWS_STORAGE_BUCKET',
    ),
    measurementId: String.fromEnvironment(
      'FIREBASE_WINDOWS_MEASUREMENT_ID',
      defaultValue: 'MISSING_FIREBASE_WINDOWS_MEASUREMENT_ID',
    ),
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_LINUX_API_KEY',
      defaultValue: 'MISSING_FIREBASE_LINUX_API_KEY',
    ),
    appId: String.fromEnvironment(
      'FIREBASE_LINUX_APP_ID',
      defaultValue: 'MISSING_FIREBASE_LINUX_APP_ID',
    ),
    messagingSenderId: String.fromEnvironment(
      'FIREBASE_LINUX_MESSAGING_SENDER_ID',
      defaultValue: 'MISSING_FIREBASE_LINUX_MESSAGING_SENDER_ID',
    ),
    projectId: String.fromEnvironment(
      'FIREBASE_LINUX_PROJECT_ID',
      defaultValue: 'MISSING_FIREBASE_LINUX_PROJECT_ID',
    ),
    storageBucket: String.fromEnvironment(
      'FIREBASE_LINUX_STORAGE_BUCKET',
      defaultValue: 'MISSING_FIREBASE_LINUX_STORAGE_BUCKET',
    ),
  );
}
