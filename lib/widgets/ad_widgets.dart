import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../models/subscription_plan.dart';
import '../providers/user_provider.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';

/// A banner ad widget with automatic loading and premium user handling
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({
    super.key,
    this.adSize = AdSize.banner,
    this.showPlaceholder = true,
  });

  final AdSize adSize;
  final bool showPlaceholder;

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadAd() {
    final adService = AdService.instance;
    if (!adService.shouldShowAds) return;

    _bannerAd = adService.createBannerAd(
      size: widget.adSize,
      onLoaded: (ad) {
        if (mounted) {
          setState(() => _isLoaded = true);
        }
      },
      onFailed: (ad, error) {
        if (mounted) {
          setState(() => _loadFailed = true);
        }
      },
    );

    _bannerAd?.load();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        // Don't show ads for premium users
        if (provider.tier != SubscriptionTier.free) {
          return const SizedBox.shrink();
        }

        if (_loadFailed && !widget.showPlaceholder) {
          return const SizedBox.shrink();
        }

        if (!_isLoaded || _bannerAd == null) {
          if (!widget.showPlaceholder) {
            return const SizedBox.shrink();
          }

          return Container(
            width: widget.adSize.width.toDouble(),
            height: widget.adSize.height.toDouble(),
            color: kCitySmartCard,
            child: const Center(
              child: Text(
                'Ad',
                style: TextStyle(
                  color: kCitySmartMuted,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }

        return Container(
          width: widget.adSize.width.toDouble(),
          height: widget.adSize.height.toDouble(),
          alignment: Alignment.center,
          child: AdWidget(ad: _bannerAd!),
        );
      },
    );
  }
}

/// A container for banner ads at the bottom of screens
class BottomBannerContainer extends StatelessWidget {
  const BottomBannerContainer({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        // Don't show ad container for premium users
        final showAd = provider.tier == SubscriptionTier.free;

        return Column(
          children: [
            Expanded(child: child),
            if (showAd)
              Container(
                color: kCitySmartGreen,
                padding: const EdgeInsets.only(top: 4),
                child: const SafeArea(
                  top: false,
                  child: AdBannerWidget(),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// A native ad widget for feed integration
class NativeAdCard extends StatefulWidget {
  const NativeAdCard({super.key});

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  void _loadAd() {
    final adService = AdService.instance;
    if (!adService.shouldShowAds) return;

    _nativeAd = adService.createNativeAd(
      factoryId: 'listTile', // Must match factory ID in native code
      onLoaded: (ad) {
        if (mounted) {
          setState(() => _isLoaded = true);
        }
      },
      onFailed: (ad, error) {
        // Silently fail - don't show native ad
      },
    );

    _nativeAd?.load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        if (provider.tier != SubscriptionTier.free) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: kCitySmartCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: kCitySmartYellow.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: kCitySmartYellow.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Sponsored',
                        style: TextStyle(
                          fontSize: 10,
                          color: kCitySmartYellow,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 100, // Adjust based on native ad design
                child: AdWidget(ad: _nativeAd!),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Watch a rewarded ad button
class WatchAdButton extends StatefulWidget {
  const WatchAdButton({
    super.key,
    required this.onReward,
    this.rewardDescription = 'Watch a short ad',
    this.buttonText = 'Watch Ad',
    this.rewardText = '3-day Premium Trial',
  });

  final VoidCallback onReward;
  final String rewardDescription;
  final String buttonText;
  final String rewardText;

  @override
  State<WatchAdButton> createState() => _WatchAdButtonState();
}

class _WatchAdButtonState extends State<WatchAdButton> {
  bool _loading = false;

  Future<void> _watchAd() async {
    setState(() => _loading = true);

    final success = await AdService.instance.showRewardedAd();

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      widget.onReward();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.rewardText} unlocked!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ad not available. Please try again later.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adService = AdService.instance;

    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        // Don't show for premium users
        if (provider.tier != SubscriptionTier.free) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kCitySmartCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: kCitySmartYellow.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kCitySmartYellow.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_circle_outline,
                      color: kCitySmartYellow,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.rewardDescription,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.card_giftcard,
                              size: 14,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Earn: ${widget.rewardText}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loading || !adService.hasRewardedAd
                    ? null
                    : _watchAd,
                style: FilledButton.styleFrom(
                  backgroundColor: kCitySmartYellow,
                  foregroundColor: kCitySmartGreen,
                  minimumSize: const Size.fromHeight(44),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: kCitySmartGreen,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow),
                          const SizedBox(width: 8),
                          Text(widget.buttonText),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Mixin for screens that want to show interstitial ads
mixin InterstitialAdMixin<T extends StatefulWidget> on State<T> {
  /// Call this when user completes an action that might trigger an ad
  Future<void> maybeShowInterstitial() async {
    final adService = AdService.instance;
    adService.recordAction();

    if (adService.canShowInterstitial()) {
      await adService.showInterstitial();
    }
  }
}

/// Helper to conditionally wrap content with banner ad
class ConditionalBannerWrapper extends StatelessWidget {
  const ConditionalBannerWrapper({
    super.key,
    required this.child,
    this.showBanner = true,
  });

  final Widget child;
  final bool showBanner;

  @override
  Widget build(BuildContext context) {
    if (!showBanner) return child;

    return Column(
      children: [
        Expanded(child: child),
        const AdBannerWidget(),
      ],
    );
  }
}
