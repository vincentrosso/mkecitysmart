import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../models/subscription_plan.dart';

/// Service for managing in-app subscriptions via RevenueCat
class SubscriptionService extends ChangeNotifier {
  SubscriptionService._();
  static final instance = SubscriptionService._();

  // RevenueCat API keys
  // Test/Development key (works for all platforms during development)
  static const _revenueCatTestKey = 'test_JhJpIJnyYopCsUtcPVYZKarOQEO';

  // Production keys from RevenueCat dashboard
  static const _revenueCatApiKeyiOS = 'appl_nPogZtDlCliLIbcHVwxxguJacpq';
  static const _revenueCatApiKeyAndroid =
      'goog_YOUR_ANDROID_KEY_HERE'; // TODO: Add Android key when ready

  // Entitlement identifier (must match RevenueCat dashboard)
  static const entitlementPro = 'pro';

  // Product identifiers (must match App Store Connect / Google Play Console)
  static const productMonthly = 'citysmart_pro_monthly';
  static const productYearly = 'citysmart_pro_yearly';

  bool _initialized = false;
  bool _isInitializing = false;
  CustomerInfo? _customerInfo;
  Offerings? _offerings;
  String? _lastError;

  bool get isInitialized => _initialized;
  CustomerInfo? get customerInfo => _customerInfo;
  Offerings? get offerings => _offerings;
  String? get lastError => _lastError;

  /// Current subscription tier based on RevenueCat entitlements
  SubscriptionTier get currentTier {
    if (_customerInfo == null) return SubscriptionTier.free;

    final entitlements = _customerInfo!.entitlements.active;

    // Check for Pro entitlement
    if (entitlements.containsKey(entitlementPro) ||
        entitlements.containsKey('pro') ||
        entitlements.containsKey('citysmart_pro')) {
      return SubscriptionTier.pro;
    }

    return SubscriptionTier.free;
  }

  /// Whether user has an active paid subscription
  bool get isPremium => currentTier == SubscriptionTier.pro;

  /// Check if user has access to a specific feature
  bool hasFeature(PremiumFeature feature) {
    return getPlanForTier(currentTier).hasFeature(feature);
  }

  /// Initialize RevenueCat SDK
  Future<void> initialize({String? userId}) async {
    if (_initialized || _isInitializing) return;
    _isInitializing = true;

    try {
      // Enable debug logs in development
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }

      // Use test key in debug mode, production keys in release
      String apiKey;
      if (kDebugMode) {
        // Use test key for development
        apiKey = _revenueCatTestKey;
      } else {
        // Use platform-specific keys for production
        apiKey =
            defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.macOS
            ? _revenueCatApiKeyiOS
            : _revenueCatApiKeyAndroid;
      }

      // Skip initialization if using placeholder keys in production
      if (!kDebugMode && apiKey.contains('YOUR_')) {
        debugPrint(
          'SubscriptionService: Using placeholder API key - skipping RevenueCat init',
        );
        _initialized = true;
        _isInitializing = false;
        return;
      }

      final config = PurchasesConfiguration(apiKey);
      if (userId != null && userId.isNotEmpty) {
        config.appUserID = userId;
      }

      await Purchases.configure(config);

      // Listen to customer info updates
      Purchases.addCustomerInfoUpdateListener((info) {
        _customerInfo = info;
        notifyListeners();
      });

      // Fetch initial customer info and offerings
      _customerInfo = await Purchases.getCustomerInfo();
      _offerings = await Purchases.getOfferings();

      _initialized = true;
      _lastError = null;
      debugPrint('SubscriptionService: Initialized successfully');
    } catch (e) {
      _lastError = e.toString();
      debugPrint('SubscriptionService: Init failed - $e');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  /// Login user with RevenueCat
  Future<void> login(String userId) async {
    if (!_initialized || userId.isEmpty) return;

    try {
      final result = await Purchases.logIn(userId);
      _customerInfo = result.customerInfo;
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      debugPrint('SubscriptionService: Login failed - $e');
    }
  }

  /// Logout user from RevenueCat
  Future<void> logout() async {
    if (!_initialized) return;

    try {
      _customerInfo = await Purchases.logOut();
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      debugPrint('SubscriptionService: Logout failed - $e');
    }
  }

  /// Purchase a subscription package
  Future<PurchaseResult> purchase(Package package) async {
    if (!_initialized) {
      return PurchaseResult(
        success: false,
        error: 'Subscription service not initialized',
      );
    }

    try {
      final result = await Purchases.purchasePackage(package);
      _customerInfo = result;
      notifyListeners();

      return PurchaseResult(success: true, customerInfo: result);
    } on PurchasesErrorCode catch (e) {
      String errorMessage;
      switch (e) {
        case PurchasesErrorCode.purchaseCancelledError:
          errorMessage = 'Purchase was cancelled';
          break;
        case PurchasesErrorCode.purchaseNotAllowedError:
          errorMessage = 'Purchase not allowed on this device';
          break;
        case PurchasesErrorCode.purchaseInvalidError:
          errorMessage = 'Invalid purchase';
          break;
        case PurchasesErrorCode.productNotAvailableForPurchaseError:
          errorMessage = 'Product not available for purchase';
          break;
        case PurchasesErrorCode.networkError:
          errorMessage = 'Network error. Please check your connection';
          break;
        default:
          errorMessage = 'Purchase failed: ${e.name}';
      }
      return PurchaseResult(success: false, error: errorMessage);
    } catch (e) {
      return PurchaseResult(success: false, error: e.toString());
    }
  }

  /// Restore previous purchases
  Future<PurchaseResult> restorePurchases() async {
    if (!_initialized) {
      return PurchaseResult(
        success: false,
        error: 'Subscription service not initialized',
      );
    }

    try {
      _customerInfo = await Purchases.restorePurchases();
      notifyListeners();

      final hasPurchases = _customerInfo!.entitlements.active.isNotEmpty;
      return PurchaseResult(
        success: true,
        customerInfo: _customerInfo,
        message: hasPurchases
            ? 'Purchases restored successfully!'
            : 'No previous purchases found',
      );
    } catch (e) {
      return PurchaseResult(
        success: false,
        error: 'Failed to restore purchases: $e',
      );
    }
  }

  /// Get available offerings (subscription packages)
  Future<Offerings?> fetchOfferings() async {
    if (!_initialized) return null;

    try {
      _offerings = await Purchases.getOfferings();
      notifyListeners();
      return _offerings;
    } catch (e) {
      _lastError = e.toString();
      return null;
    }
  }

  /// Get the subscription plan details for a tier
  static SubscriptionPlan getPlanForTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return const SubscriptionPlan(
          tier: SubscriptionTier.free,
          maxAlertRadiusMiles: 3,
          alertVolumePerDay: 3,
          zeroProcessingFee: false,
          prioritySupport: false,
          monthlyPrice: 0,
          adFree: false,
          heatmapAccess: false,
          smartAlerts: false,
          historyDays: 7,
          features: [
            '3-mile alert radius',
            '3 alerts per day',
            '7 days of history',
            'Basic parking info',
          ],
        );
      case SubscriptionTier.pro:
        return const SubscriptionPlan(
          tier: SubscriptionTier.pro,
          maxAlertRadiusMiles: 15,
          alertVolumePerDay: -1, // Unlimited
          zeroProcessingFee: true,
          prioritySupport: true,
          monthlyPrice: 4.99,
          yearlyPrice: 39.99,
          adFree: true,
          heatmapAccess: true,
          smartAlerts: true,
          historyDays: 365,
          features: [
            '15-mile alert radius',
            'Unlimited alerts',
            '1 year of history',
            'Citation heatmaps',
            'Smart alerts',
            'Ad-free experience',
            'Zero processing fees',
            'Priority support',
          ],
        );
    }
  }

  // ============================================================
  // RevenueCat Paywall UI Methods
  // ============================================================

  /// Present RevenueCat's native paywall UI
  /// Returns true if user purchased or restored, false otherwise
  Future<bool> presentPaywall({String? offeringIdentifier}) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      Offering? offering;
      if (offeringIdentifier != null) {
        offering = _offerings?.getOffering(offeringIdentifier);
      } else {
        offering = _offerings?.current;
      }

      final result = await RevenueCatUI.presentPaywall(offering: offering);

      // Refresh customer info after paywall closes
      await _refreshCustomerInfo();

      return result == PaywallResult.purchased ||
          result == PaywallResult.restored;
    } on PlatformException catch (e) {
      debugPrint('SubscriptionService: Paywall error - ${e.message}');
      _lastError = e.message;
      return false;
    }
  }

  /// Present paywall only if user doesn't have the specified entitlement
  /// Returns true if user has access (either already had or just purchased)
  Future<bool> presentPaywallIfNeeded(String entitlementId) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      final result = await RevenueCatUI.presentPaywallIfNeeded(
        entitlementId,
        offering: _offerings?.current,
      );

      await _refreshCustomerInfo();

      // Return true if user now has access
      return result == PaywallResult.purchased ||
          result == PaywallResult.restored ||
          result == PaywallResult.notPresented; // Already had entitlement
    } on PlatformException catch (e) {
      debugPrint('SubscriptionService: Paywall error - ${e.message}');
      _lastError = e.message;
      return false;
    }
  }

  /// Present RevenueCat's Customer Center for managing subscriptions
  Future<void> presentCustomerCenter() async {
    if (!_initialized) {
      await initialize();
    }

    try {
      await RevenueCatUI.presentCustomerCenter();
      // Refresh customer info after customer center closes
      await _refreshCustomerInfo();
    } on PlatformException catch (e) {
      debugPrint('SubscriptionService: Customer Center error - ${e.message}');
      _lastError = e.message;
    }
  }

  /// Refresh customer info from RevenueCat
  Future<void> _refreshCustomerInfo() async {
    try {
      _customerInfo = await Purchases.getCustomerInfo();
      notifyListeners();
    } catch (e) {
      debugPrint('SubscriptionService: Error refreshing customer info - $e');
    }
  }

  /// Get expiration date for an entitlement
  DateTime? getExpirationDate(String entitlementId) {
    final entitlement = _customerInfo?.entitlements.active[entitlementId];
    final expirationStr = entitlement?.expirationDate;
    if (expirationStr == null) return null;
    return DateTime.tryParse(expirationStr);
  }

  /// Check if subscription will auto-renew
  bool willRenew(String entitlementId) {
    final entitlement = _customerInfo?.entitlements.active[entitlementId];
    return entitlement?.willRenew ?? false;
  }

  /// Check if user has a specific entitlement
  bool hasEntitlement(String entitlementId) {
    return _customerInfo?.entitlements.active.containsKey(entitlementId) ??
        false;
  }

  /// Get the management URL for the user's subscription
  String? get managementUrl => _customerInfo?.managementURL;

  /// Set user attributes for analytics
  Future<void> setUserAttributes({
    String? email,
    String? displayName,
    String? phoneNumber,
  }) async {
    if (!_initialized) return;

    try {
      if (email != null) await Purchases.setEmail(email);
      if (displayName != null) await Purchases.setDisplayName(displayName);
      if (phoneNumber != null) await Purchases.setPhoneNumber(phoneNumber);
    } catch (e) {
      debugPrint('SubscriptionService: Error setting attributes - $e');
    }
  }

  /// Get the monthly package from current offering
  Package? get monthlyPackage => _offerings?.current?.monthly;

  /// Get the annual package from current offering
  Package? get annualPackage => _offerings?.current?.annual;

  /// Get the lifetime package from current offering
  Package? get lifetimePackage => _offerings?.current?.lifetime;

  /// Get all available packages from current offering
  List<Package> get availablePackages =>
      _offerings?.current?.availablePackages ?? [];
}

/// Result of a purchase operation
class PurchaseResult {
  const PurchaseResult({
    required this.success,
    this.customerInfo,
    this.error,
    this.message,
  });

  final bool success;
  final CustomerInfo? customerInfo;
  final String? error;
  final String? message;
}
