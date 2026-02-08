import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ad_preferences.dart';
import '../models/subscription_plan.dart';

/// Service for managing ads with frequency capping and premium user handling
class AdService {
  AdService._();
  static final instance = AdService._();

  // AdMob App ID: ca-app-pub-2009498889741048~9019853313
  // Test IDs for development
  static const _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const _testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const _testNativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110';

  // Production IDs - MKE CitySmart AdMob
  // Create these ad units at https://admob.google.com → Apps → MKE CitySmart → Ad units
  static const _prodBannerAdUnitId = 'ca-app-pub-2009498889741048/5020898555';
  static const _prodInterstitialAdUnitId =
      'ca-app-pub-2009498889741048/6714276952';
  static const _prodRewardedAdUnitId =
      'ca-app-pub-2009498889741048/2775031941'; // citysmart_rewarded
  static const _prodNativeAdUnitId =
      'ca-app-pub-2009498889741048/3072178018'; // Feed Screen native ad

  // Frequency caps
  static const int _maxInterstitialsPerHour = 3;
  static const int _maxInterstitialsPerDay = 8;
  static const Duration _minTimeBetweenInterstitials = Duration(minutes: 5);
  static const int _actionsBeforeFirstInterstitial = 3;

  bool _initialized = false;
  bool _isTestMode = true; // Set to false for production

  // Preloaded ads
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  // Tracking
  int _actionCount = 0;
  DateTime? _lastInterstitialShown;
  final List<DateTime> _interstitialTimestamps = [];

  // User preferences
  AdPreferences _preferences = const AdPreferences();
  SubscriptionTier _userTier = SubscriptionTier.free;

  bool get isInitialized => _initialized;
  bool get shouldShowAds => _userTier == SubscriptionTier.free;
  AdPreferences get preferences => _preferences;

  String get _bannerAdUnitId =>
      _isTestMode ? _testBannerAdUnitId : _prodBannerAdUnitId;
  String get _interstitialAdUnitId =>
      _isTestMode ? _testInterstitialAdUnitId : _prodInterstitialAdUnitId;
  String get _rewardedAdUnitId =>
      _isTestMode ? _testRewardedAdUnitId : _prodRewardedAdUnitId;
  String get _nativeAdUnitId =>
      _isTestMode ? _testNativeAdUnitId : _prodNativeAdUnitId;

  /// Initialize the ad service
  Future<void> initialize({bool testMode = true}) async {
    if (_initialized) return;

    _isTestMode = testMode;

    try {
      await MobileAds.instance.initialize();

      // Load initial ads
      await _loadInterstitialAd();
      await _loadRewardedAd();

      // Load tracking data
      await _loadTrackingData();

      _initialized = true;
      debugPrint('AdService: Initialized successfully (testMode: $testMode)');
    } catch (e) {
      debugPrint('AdService: Failed to initialize - $e');
    }
  }

  /// Update user preferences and tier
  void updateUserState({AdPreferences? preferences, SubscriptionTier? tier}) {
    if (preferences != null) _preferences = preferences;
    if (tier != null) _userTier = tier;
  }

  /// Record a user action (for frequency capping)
  void recordAction() {
    _actionCount++;
    _saveTrackingData();
  }

  /// Check if an interstitial ad can be shown based on frequency caps
  bool canShowInterstitial() {
    if (!shouldShowAds) return false;
    if (_interstitialAd == null) return false;

    // Check action count
    if (_actionCount < _actionsBeforeFirstInterstitial) return false;

    // Check time since last interstitial
    if (_lastInterstitialShown != null) {
      final elapsed = DateTime.now().difference(_lastInterstitialShown!);
      if (elapsed < _minTimeBetweenInterstitials) return false;
    }

    // Check hourly cap
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    final recentCount = _interstitialTimestamps
        .where((t) => t.isAfter(oneHourAgo))
        .length;
    if (recentCount >= _maxInterstitialsPerHour) return false;

    // Check daily cap
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final todayCount = _interstitialTimestamps
        .where((t) => t.isAfter(startOfDay))
        .length;
    if (todayCount >= _maxInterstitialsPerDay) return false;

    return true;
  }

  /// Show an interstitial ad if allowed
  Future<bool> showInterstitial() async {
    if (!canShowInterstitial()) return false;

    final completer = Completer<bool>();

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('AdService: Interstitial shown');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('AdService: Interstitial dismissed');
        ad.dispose();
        _interstitialAd = null;
        _recordInterstitialShown();
        _loadInterstitialAd();
        completer.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AdService: Interstitial failed to show - $error');
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
        completer.complete(false);
      },
    );

    await _interstitialAd!.show();
    return completer.future;
  }

  /// Show a rewarded ad and return whether the reward was granted
  Future<bool> showRewardedAd() async {
    if (!shouldShowAds) return false;
    if (_rewardedAd == null) return false;

    final completer = Completer<bool>();
    var rewardGranted = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('AdService: Rewarded ad shown');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('AdService: Rewarded ad dismissed');
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
        completer.complete(rewardGranted);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AdService: Rewarded ad failed to show - $error');
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
        completer.complete(false);
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint(
          'AdService: User earned reward - ${reward.amount} ${reward.type}',
        );
        rewardGranted = true;
      },
    );

    return completer.future;
  }

  /// Create a banner ad widget request
  BannerAd? createBannerAd({
    AdSize size = AdSize.banner,
    void Function(Ad)? onLoaded,
    void Function(Ad, LoadAdError)? onFailed,
  }) {
    if (!shouldShowAds) return null;

    return BannerAd(
      adUnitId: _bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('AdService: Banner loaded');
          onLoaded?.call(ad);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdService: Banner failed to load - $error');
          ad.dispose();
          onFailed?.call(ad, error);
        },
        onAdOpened: (ad) => debugPrint('AdService: Banner opened'),
        onAdClosed: (ad) => debugPrint('AdService: Banner closed'),
      ),
    );
  }

  /// Create a native ad
  NativeAd? createNativeAd({
    required String factoryId,
    void Function(Ad)? onLoaded,
    void Function(Ad, LoadAdError)? onFailed,
  }) {
    if (!shouldShowAds) return null;

    return NativeAd(
      adUnitId: _nativeAdUnitId,
      factoryId: factoryId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('AdService: Native ad loaded');
          onLoaded?.call(ad);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdService: Native ad failed to load - $error');
          ad.dispose();
          onFailed?.call(ad, error);
        },
      ),
    );
  }

  /// Check if a rewarded ad is available
  bool get hasRewardedAd => _rewardedAd != null && shouldShowAds;

  /// Preload ads for faster showing
  Future<void> preloadAds() async {
    if (!shouldShowAds) return;

    await Future.wait([_loadInterstitialAd(), _loadRewardedAd()]);
  }

  Future<void> _loadInterstitialAd() async {
    if (!shouldShowAds) return;

    await InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          debugPrint('AdService: Interstitial preloaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdService: Failed to load interstitial - $error');
        },
      ),
    );
  }

  Future<void> _loadRewardedAd() async {
    if (!shouldShowAds) return;

    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          debugPrint('AdService: Rewarded ad preloaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdService: Failed to load rewarded ad - $error');
        },
      ),
    );
  }

  void _recordInterstitialShown() {
    final now = DateTime.now();
    _lastInterstitialShown = now;
    _interstitialTimestamps.add(now);

    // Keep only last 24 hours of timestamps
    final cutoff = now.subtract(const Duration(hours: 24));
    _interstitialTimestamps.removeWhere((t) => t.isBefore(cutoff));

    _saveTrackingData();
  }

  Future<void> _loadTrackingData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _actionCount = prefs.getInt('ad_action_count') ?? 0;

      final lastShown = prefs.getInt('ad_last_interstitial');
      if (lastShown != null) {
        _lastInterstitialShown = DateTime.fromMillisecondsSinceEpoch(lastShown);
      }

      final timestamps =
          prefs.getStringList('ad_interstitial_timestamps') ?? [];
      _interstitialTimestamps.clear();
      for (final t in timestamps) {
        final ms = int.tryParse(t);
        if (ms != null) {
          _interstitialTimestamps.add(DateTime.fromMillisecondsSinceEpoch(ms));
        }
      }

      // Reset action count if it's a new day
      final lastDate = prefs.getString('ad_last_date');
      final today = DateTime.now().toIso8601String().substring(
        0,
        10,
      ); // YYYY-MM-DD
      if (lastDate != today) {
        _actionCount = 0;
        await prefs.setString('ad_last_date', today);
      }
    } catch (e) {
      debugPrint('AdService: Failed to load tracking data - $e');
    }
  }

  Future<void> _saveTrackingData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('ad_action_count', _actionCount);

      if (_lastInterstitialShown != null) {
        await prefs.setInt(
          'ad_last_interstitial',
          _lastInterstitialShown!.millisecondsSinceEpoch,
        );
      }

      await prefs.setStringList(
        'ad_interstitial_timestamps',
        _interstitialTimestamps
            .map((t) => t.millisecondsSinceEpoch.toString())
            .toList(),
      );

      final today = DateTime.now().toIso8601String().substring(0, 10);
      await prefs.setString('ad_last_date', today);
    } catch (e) {
      debugPrint('AdService: Failed to save tracking data - $e');
    }
  }

  /// Dispose of preloaded ads
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _interstitialAd = null;
    _rewardedAd = null;
  }
}
