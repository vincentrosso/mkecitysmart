import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Scalable analytics service for tracking user behavior and app performance.
/// Wraps Firebase Analytics and Crashlytics with a clean API.
/// 
/// Designed for:
/// - Event tracking (screen views, actions, conversions)
/// - User property management
/// - Crash reporting with context
/// - Performance monitoring hooks
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  static AnalyticsService get instance => _instance;
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  FirebaseCrashlytics? _crashlytics;
  bool _initialized = false;

  /// Initialize analytics services
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      _analytics = FirebaseAnalytics.instance;
      _crashlytics = FirebaseCrashlytics.instance;
      
      // Enable crashlytics collection (disabled in debug for cleaner logs)
      if (!kDebugMode) {
        await _crashlytics?.setCrashlyticsCollectionEnabled(true);
      } else {
        await _crashlytics?.setCrashlyticsCollectionEnabled(false);
      }
      
      _initialized = true;
      debugPrint('[AnalyticsService] Initialized');
    } catch (e) {
      debugPrint('[AnalyticsService] Init error: $e');
    }
  }

  /// Get the Firebase Analytics observer for navigation tracking
  FirebaseAnalyticsObserver? get observer {
    if (_analytics == null) return null;
    return FirebaseAnalyticsObserver(analytics: _analytics!);
  }

  // ==================== Screen Tracking ====================

  /// Log a screen view
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    try {
      await _analytics?.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
      if (kDebugMode) {
        debugPrint('[Analytics] Screen: $screenName');
      }
    } catch (e) {
      _logError('logScreenView', e);
    }
  }

  // ==================== Event Tracking ====================

  /// Log a custom event with optional parameters
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    try {
      await _analytics?.logEvent(name: name, parameters: parameters);
      if (kDebugMode) {
        debugPrint('[Analytics] Event: $name ${parameters ?? ''}');
      }
    } catch (e) {
      _logError('logEvent', e);
    }
  }

  /// Log when user posts a sighting
  Future<void> logSightingPosted({
    required String type,
    required bool hasLocation,
    required bool hasPhoto,
  }) async {
    await logEvent('sighting_posted', parameters: {
      'sighting_type': type,
      'has_location': hasLocation.toString(),
      'has_photo': hasPhoto.toString(),
    });
  }

  /// Log when user views the feed
  Future<void> logFeedViewed({
    required String radiusFilter,
    required String timeFilter,
    required int resultCount,
  }) async {
    await logEvent('feed_viewed', parameters: {
      'radius_filter': radiusFilter,
      'time_filter': timeFilter,
      'result_count': resultCount,
    });
  }

  /// Log when user taps a sighting card
  Future<void> logSightingTapped(String sightingId, String type) async {
    await logEvent('sighting_tapped', parameters: {
      'sighting_id': sightingId,
      'sighting_type': type,
    });
  }

  /// Log when user reports a sighting
  Future<void> logSightingReported(String sightingId) async {
    await logEvent('sighting_reported', parameters: {
      'sighting_id': sightingId,
    });
  }

  /// Log when user views the parking heatmap
  Future<void> logHeatmapViewed({required int zoneCount}) async {
    await logEvent('heatmap_viewed', parameters: {
      'zone_count': zoneCount,
    });
  }

  /// Log when user uses parking finder
  Future<void> logParkingFinderUsed(String locationType) async {
    await logEvent('parking_finder_used', parameters: {
      'location_type': locationType,
    });
  }

  /// Log when user gets directions
  Future<void> logDirectionsRequested(String destination) async {
    await logEvent('directions_requested', parameters: {
      'destination': destination,
    });
  }

  /// Log when user adds a ticket to tracker
  Future<void> logTicketAdded({required bool hasPhoto}) async {
    await logEvent('ticket_added', parameters: {
      'has_photo': hasPhoto.toString(),
    });
  }

  /// Log when user marks ticket as paid
  Future<void> logTicketPaid(double amount) async {
    await logEvent('ticket_paid', parameters: {
      'amount': amount,
    });
  }

  /// Log authentication events
  Future<void> logLogin(String method) async {
    await _analytics?.logLogin(loginMethod: method);
    if (kDebugMode) {
      debugPrint('[Analytics] Login: $method');
    }
  }

  Future<void> logSignUp(String method) async {
    await _analytics?.logSignUp(signUpMethod: method);
    if (kDebugMode) {
      debugPrint('[Analytics] SignUp: $method');
    }
  }

  /// Log onboarding completion
  Future<void> logOnboardingComplete() async {
    await logEvent('onboarding_complete');
  }

  /// Log notification permission granted
  Future<void> logNotificationPermission(bool granted) async {
    await logEvent('notification_permission', parameters: {
      'granted': granted.toString(),
    });
  }

  /// Log filter changes (for understanding user preferences)
  Future<void> logFilterChanged({
    required String filterType,
    required String oldValue,
    required String newValue,
  }) async {
    await logEvent('filter_changed', parameters: {
      'filter_type': filterType,
      'old_value': oldValue,
      'new_value': newValue,
    });
  }

  // ==================== User Properties ====================

  /// Set a user property
  Future<void> setUserProperty(String name, String? value) async {
    try {
      await _analytics?.setUserProperty(name: name, value: value);
      if (kDebugMode) {
        debugPrint('[Analytics] UserProperty: $name = $value');
      }
    } catch (e) {
      _logError('setUserProperty', e);
    }
  }

  /// Set user ID for cross-device tracking
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics?.setUserId(id: userId);
      await _crashlytics?.setUserIdentifier(userId ?? '');
      if (kDebugMode) {
        debugPrint('[Analytics] UserId: $userId');
      }
    } catch (e) {
      _logError('setUserId', e);
    }
  }

  /// Set subscription tier (for future monetization tracking)
  Future<void> setSubscriptionTier(String tier) async {
    await setUserProperty('subscription_tier', tier);
  }

  /// Set user's city (for geo-based analytics)
  Future<void> setUserCity(String city) async {
    await setUserProperty('user_city', city);
  }

  // ==================== Error & Crash Reporting ====================

  /// Record a non-fatal error
  Future<void> recordError(
    dynamic error, {
    StackTrace? stackTrace,
    String? reason,
    bool fatal = false,
  }) async {
    try {
      await _crashlytics?.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
      if (kDebugMode) {
        debugPrint('[Crashlytics] Error: $error, reason: $reason');
      }
    } catch (e) {
      debugPrint('[AnalyticsService] recordError failed: $e');
    }
  }

  /// Set a custom key for crash reports (provides context)
  Future<void> setCrashlyticsKey(String key, dynamic value) async {
    try {
      if (value is String) {
        await _crashlytics?.setCustomKey(key, value);
      } else if (value is int) {
        await _crashlytics?.setCustomKey(key, value);
      } else if (value is bool) {
        await _crashlytics?.setCustomKey(key, value);
      } else if (value is double) {
        await _crashlytics?.setCustomKey(key, value);
      }
    } catch (e) {
      _logError('setCrashlyticsKey', e);
    }
  }

  /// Log a message that will appear in crash reports
  Future<void> log(String message) async {
    try {
      await _crashlytics?.log(message);
      if (kDebugMode) {
        debugPrint('[Crashlytics] Log: $message');
      }
    } catch (e) {
      _logError('log', e);
    }
  }

  // ==================== Performance Tracking ====================

  /// Start timing an operation (returns a stop function)
  Stopwatch startTimer(String operationName) {
    if (kDebugMode) {
      debugPrint('[Analytics] Timer start: $operationName');
    }
    return Stopwatch()..start();
  }

  /// Log the duration of an operation
  Future<void> logTiming(String operationName, Duration duration) async {
    await logEvent('timing_$operationName', parameters: {
      'duration_ms': duration.inMilliseconds,
    });
    if (kDebugMode) {
      debugPrint('[Analytics] Timer $operationName: ${duration.inMilliseconds}ms');
    }
  }

  /// Helper to measure and log an async operation
  Future<T> measureAsync<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = startTimer(operationName);
    try {
      final result = await operation();
      stopwatch.stop();
      await logTiming(operationName, stopwatch.elapsed);
      return result;
    } catch (e, stack) {
      stopwatch.stop();
      await logTiming(operationName, stopwatch.elapsed);
      await recordError(e, stackTrace: stack, reason: 'measureAsync: $operationName');
      rethrow;
    }
  }

  // ==================== Private Helpers ====================

  void _logError(String method, dynamic error) {
    if (kDebugMode) {
      debugPrint('[AnalyticsService] $method error: $error');
    }
  }
}
