import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/subscription_plan.dart';
import '../providers/user_provider.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';
import 'paywall_widget.dart';

/// Widget that gates premium features behind subscription
class FeatureGate extends StatelessWidget {
  const FeatureGate({
    super.key,
    required this.feature,
    required this.child,
    this.lockedChild,
    this.showUpgradePrompt = true,
  });

  /// The premium feature being gated
  final PremiumFeature feature;

  /// Widget to show when feature is unlocked
  final Widget child;

  /// Optional widget to show when feature is locked
  /// If not provided, shows a default locked state
  final Widget? lockedChild;

  /// Whether to show upgrade prompt when tapping locked feature
  final bool showUpgradePrompt;

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        final plan = SubscriptionService.getPlanForTier(provider.tier);
        final hasAccess = plan.hasFeature(feature);

        if (hasAccess) {
          return child;
        }

        return lockedChild ??
            _DefaultLockedWidget(
              feature: feature,
              showUpgradePrompt: showUpgradePrompt,
            );
      },
    );
  }

  /// Check if user has access to a feature (static method for use in other places)
  static bool hasAccess(BuildContext context, PremiumFeature feature) {
    final provider = context.read<UserProvider>();
    final plan = SubscriptionService.getPlanForTier(provider.tier);
    return plan.hasFeature(feature);
  }

  /// Show paywall for a feature (static method)
  static Future<bool> showPaywall(
    BuildContext context,
    PremiumFeature feature,
  ) async {
    return PaywallScreen.show(context, feature: feature);
  }

  /// Check access and show paywall if needed. Returns true if user has access.
  static Future<bool> checkAccessOrShowPaywall(
    BuildContext context,
    PremiumFeature feature,
  ) async {
    if (hasAccess(context, feature)) {
      return true;
    }
    return showPaywall(context, feature);
  }
}

class _DefaultLockedWidget extends StatelessWidget {
  const _DefaultLockedWidget({
    required this.feature,
    required this.showUpgradePrompt,
  });

  final PremiumFeature feature;
  final bool showUpgradePrompt;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: showUpgradePrompt
          ? () => PaywallScreen.show(context, feature: feature)
          : null,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: kCitySmartCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: kCitySmartYellow.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  feature.icon,
                  size: 48,
                  color: kCitySmartText.withValues(alpha: 0.3),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: kCitySmartYellow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock,
                      size: 16,
                      color: kCitySmartGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              feature.displayName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              feature.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: kCitySmartText.withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (showUpgradePrompt)
              FilledButton.icon(
                onPressed: () =>
                    PaywallScreen.show(context, feature: feature),
                icon: const Icon(Icons.workspace_premium),
                label: Text('Upgrade to ${feature.minimumTier.name}'),
                style: FilledButton.styleFrom(
                  backgroundColor: kCitySmartYellow,
                  foregroundColor: kCitySmartGreen,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A locked tile overlay for dashboard tiles
class LockedTileOverlay extends StatelessWidget {
  const LockedTileOverlay({
    super.key,
    required this.feature,
    required this.child,
  });

  final PremiumFeature feature;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        final plan = SubscriptionService.getPlanForTier(provider.tier);
        final hasAccess = plan.hasFeature(feature);

        return Stack(
          children: [
            // Original tile with reduced opacity if locked
            Opacity(
              opacity: hasAccess ? 1.0 : 0.5,
              child: child,
            ),

            // Lock overlay
            if (!hasAccess)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => PaywallScreen.show(context, feature: feature),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kCitySmartYellow,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.lock,
                            size: 20,
                            color: kCitySmartGreen,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: kCitySmartYellow,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            feature.minimumTier.name.toUpperCase(),
                            style: const TextStyle(
                              color: kCitySmartGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Banner widget to show at bottom of screens for upgrade prompt
class UpgradeBanner extends StatelessWidget {
  const UpgradeBanner({
    super.key,
    this.feature,
    this.message,
  });

  final PremiumFeature? feature;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        // Don't show banner for premium users
        if (provider.tier != SubscriptionTier.free) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                kCitySmartYellow.withValues(alpha: 0.2),
                kCitySmartGreen.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: kCitySmartYellow.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.workspace_premium,
                color: kCitySmartYellow,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upgrade to Premium',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      message ?? 'Get access to all features and remove ads',
                      style: TextStyle(
                        color: kCitySmartText.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  if (feature != null) {
                    PaywallScreen.show(context, feature: feature!);
                  } else {
                    Navigator.pushNamed(context, '/subscriptions');
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: kCitySmartYellow,
                  foregroundColor: kCitySmartGreen,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text('Upgrade'),
              ),
            ],
          ),
        );
      },
    );
  }
}
