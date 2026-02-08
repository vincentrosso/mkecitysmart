import 'package:flutter/material.dart';

/// Subscription tiers - simplified to Free and Pro
enum SubscriptionTier { free, pro }

// Keep 'plus' as alias for backward compatibility
extension SubscriptionTierCompat on SubscriptionTier {
  static SubscriptionTier get plus => SubscriptionTier.pro;
}

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.tier,
    required this.maxAlertRadiusMiles,
    required this.alertVolumePerDay,
    required this.zeroProcessingFee,
    required this.prioritySupport,
    required this.monthlyPrice,
    this.yearlyPrice,
    this.features = const [],
    this.adFree = false,
    this.heatmapAccess = false,
    this.smartAlerts = false,
    this.historyDays = 7,
  });

  final SubscriptionTier tier;
  final double maxAlertRadiusMiles;
  final int alertVolumePerDay;
  final bool zeroProcessingFee;
  final bool prioritySupport;
  final double monthlyPrice;
  final double? yearlyPrice;
  final List<String> features;
  final bool adFree;
  final bool heatmapAccess;
  final bool smartAlerts;
  final int historyDays; // Days of history access

  String get label {
    switch (tier) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.pro:
        return 'Pro';
    }
  }

  String get revenueCatProductId {
    switch (tier) {
      case SubscriptionTier.free:
        return '';
      case SubscriptionTier.pro:
        return 'citysmart_pro_monthly';
    }
  }

  String get revenueCatYearlyProductId {
    switch (tier) {
      case SubscriptionTier.free:
        return '';
      case SubscriptionTier.pro:
        return 'citysmart_pro_yearly';
    }
  }

  /// Check if user has access to a specific feature
  bool hasFeature(PremiumFeature feature) {
    switch (feature) {
      case PremiumFeature.heatmap:
        return heatmapAccess;
      case PremiumFeature.smartAlerts:
        return smartAlerts;
      case PremiumFeature.adFree:
        return adFree;
      case PremiumFeature.extendedHistory:
        return historyDays > 7;
      case PremiumFeature.prioritySupport:
        return prioritySupport;
      case PremiumFeature.expandedRadius:
        return maxAlertRadiusMiles > 3;
      case PremiumFeature.unlimitedAlerts:
        return alertVolumePerDay > 10;
      case PremiumFeature.spotCounts:
        return heatmapAccess; // Tied to heatmap/Pro access
      case PremiumFeature.parkingFinder:
        return heatmapAccess; // Tied to heatmap/Pro access
      case PremiumFeature.towHelper:
        return tier == SubscriptionTier.pro;
    }
  }
}

/// Features that can be gated behind subscription tiers
enum PremiumFeature {
  heatmap,
  smartAlerts,
  adFree,
  extendedHistory,
  prioritySupport,
  expandedRadius,
  unlimitedAlerts,
  spotCounts, // "~X spots open nearby" zone-aggregated data
  parkingFinder, // AI-powered safest spot finder
  towHelper, // Tow recovery helper guide
}

extension PremiumFeatureExt on PremiumFeature {
  String get displayName {
    switch (this) {
      case PremiumFeature.heatmap:
        return 'Citation Heatmaps';
      case PremiumFeature.smartAlerts:
        return 'Smart Alerts';
      case PremiumFeature.adFree:
        return 'Ad-Free Experience';
      case PremiumFeature.extendedHistory:
        return 'Extended History';
      case PremiumFeature.prioritySupport:
        return 'Priority Support';
      case PremiumFeature.expandedRadius:
        return 'Expanded Alert Radius';
      case PremiumFeature.unlimitedAlerts:
        return 'Unlimited Alerts';
      case PremiumFeature.spotCounts:
        return 'Live Spot Counts';
      case PremiumFeature.parkingFinder:
        return 'AI Parking Finder';
      case PremiumFeature.towHelper:
        return 'Tow Recovery Helper';
    }
  }

  String get description {
    switch (this) {
      case PremiumFeature.heatmap:
        return 'Access detailed citation risk heatmaps to find safer parking spots';
      case PremiumFeature.smartAlerts:
        return 'Get AI-powered alerts based on your parking patterns and local enforcement';
      case PremiumFeature.adFree:
        return 'Enjoy the app without any advertisements';
      case PremiumFeature.extendedHistory:
        return 'View your parking and ticket history beyond 7 days';
      case PremiumFeature.prioritySupport:
        return 'Get faster responses from our support team';
      case PremiumFeature.expandedRadius:
        return 'Receive alerts for a wider area around your location';
      case PremiumFeature.unlimitedAlerts:
        return 'No daily limit on the number of alerts you receive';
      case PremiumFeature.spotCounts:
        return 'See exactly how many spots are open near you';
      case PremiumFeature.parkingFinder:
        return 'AI-powered safest parking spot recommendations';
      case PremiumFeature.towHelper:
        return 'Step-by-step guidance when your car gets towed';
    }
  }

  IconData get icon {
    switch (this) {
      case PremiumFeature.heatmap:
        return Icons.map_outlined;
      case PremiumFeature.smartAlerts:
        return Icons.psychology_outlined;
      case PremiumFeature.adFree:
        return Icons.block_outlined;
      case PremiumFeature.extendedHistory:
        return Icons.history;
      case PremiumFeature.prioritySupport:
        return Icons.support_agent;
      case PremiumFeature.expandedRadius:
        return Icons.radar;
      case PremiumFeature.unlimitedAlerts:
        return Icons.notifications_active;
      case PremiumFeature.spotCounts:
        return Icons.pin_drop;
      case PremiumFeature.parkingFinder:
        return Icons.search;
      case PremiumFeature.towHelper:
        return Icons.car_crash;
    }
  }

  SubscriptionTier get minimumTier {
    switch (this) {
      case PremiumFeature.heatmap:
        return SubscriptionTier.pro;
      case PremiumFeature.smartAlerts:
        return SubscriptionTier.pro;
      case PremiumFeature.adFree:
        return SubscriptionTier.pro;
      case PremiumFeature.extendedHistory:
        return SubscriptionTier.pro;
      case PremiumFeature.prioritySupport:
        return SubscriptionTier.pro;
      case PremiumFeature.expandedRadius:
        return SubscriptionTier.pro;
      case PremiumFeature.unlimitedAlerts:
        return SubscriptionTier.pro;
      case PremiumFeature.spotCounts:
        return SubscriptionTier.pro;
      case PremiumFeature.parkingFinder:
        return SubscriptionTier.pro;
      case PremiumFeature.towHelper:
        return SubscriptionTier.pro;
    }
  }
}
