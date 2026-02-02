import 'package:flutter/material.dart';

enum SubscriptionTier { free, plus, pro }

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
      case SubscriptionTier.plus:
        return 'Plus';
      case SubscriptionTier.pro:
        return 'Pro';
    }
  }

  String get revenueCatProductId {
    switch (tier) {
      case SubscriptionTier.free:
        return '';
      case SubscriptionTier.plus:
        return 'citysmart_plus_monthly';
      case SubscriptionTier.pro:
        return 'citysmart_pro_monthly';
    }
  }

  String get revenueCatYearlyProductId {
    switch (tier) {
      case SubscriptionTier.free:
        return '';
      case SubscriptionTier.plus:
        return 'citysmart_plus_yearly';
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
    }
  }

  SubscriptionTier get minimumTier {
    switch (this) {
      case PremiumFeature.heatmap:
        return SubscriptionTier.plus;
      case PremiumFeature.smartAlerts:
        return SubscriptionTier.plus;
      case PremiumFeature.adFree:
        return SubscriptionTier.plus;
      case PremiumFeature.extendedHistory:
        return SubscriptionTier.plus;
      case PremiumFeature.prioritySupport:
        return SubscriptionTier.pro;
      case PremiumFeature.expandedRadius:
        return SubscriptionTier.plus;
      case PremiumFeature.unlimitedAlerts:
        return SubscriptionTier.pro;
    }
  }
}
