import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../models/subscription_plan.dart';

/// Service for managing in-app subscriptions via RevenueCat
class SubscriptionService extends ChangeNotifier {
  SubscriptionService._();
  static final instance = SubscriptionService._();

  // RevenueCat API keys - replace with actual keys from RevenueCat dashboard
  static const _revenueCatApiKeyiOS = 'appl_YOUR_IOS_KEY_HERE';
  static const _revenueCatApiKeyAndroid = 'goog_YOUR_ANDROID_KEY_HERE';

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

    if (entitlements.containsKey('pro') ||
        entitlements.containsKey('citysmart_pro')) {
      return SubscriptionTier.pro;
    }
    if (entitlements.containsKey('plus') ||
        entitlements.containsKey('citysmart_plus')) {
      return SubscriptionTier.plus;
    }

    return SubscriptionTier.free;
  }

  /// Whether user has an active paid subscription
  bool get isPremium =>
      currentTier == SubscriptionTier.plus ||
      currentTier == SubscriptionTier.pro;

  /// Check if user has access to a specific feature
  bool hasFeature(PremiumFeature feature) {
    return getPlanForTier(currentTier).hasFeature(feature);
  }

  /// Initialize RevenueCat SDK
  Future<void> initialize({String? userId}) async {
    if (_initialized || _isInitializing) return;
    _isInitializing = true;

    try {
      // Configure SDK based on platform
      final apiKey = defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS
          ? _revenueCatApiKeyiOS
          : _revenueCatApiKeyAndroid;

      // Skip initialization if using placeholder keys
      if (apiKey.contains('YOUR_')) {
        debugPrint(
            'SubscriptionService: Using placeholder API key - skipping RevenueCat init');
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

      return PurchaseResult(
        success: true,
        customerInfo: result,
      );
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
      case SubscriptionTier.plus:
        return const SubscriptionPlan(
          tier: SubscriptionTier.plus,
          maxAlertRadiusMiles: 8,
          alertVolumePerDay: 15,
          zeroProcessingFee: true,
          prioritySupport: false,
          monthlyPrice: 3.99,
          yearlyPrice: 29.99,
          adFree: true,
          heatmapAccess: true,
          smartAlerts: true,
          historyDays: 30,
          features: [
            '8-mile alert radius',
            '15 alerts per day',
            '30 days of history',
            'Citation heatmaps',
            'Smart alerts',
            'Ad-free experience',
            'Zero processing fees',
          ],
        );
      case SubscriptionTier.pro:
        return const SubscriptionPlan(
          tier: SubscriptionTier.pro,
          maxAlertRadiusMiles: 15,
          alertVolumePerDay: -1, // Unlimited
          zeroProcessingFee: true,
          prioritySupport: true,
          monthlyPrice: 6.99,
          yearlyPrice: 49.99,
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
