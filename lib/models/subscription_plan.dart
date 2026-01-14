enum SubscriptionTier { free, plus, pro }

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.tier,
    required this.maxAlertRadiusMiles,
    required this.alertVolumePerDay,
    required this.zeroProcessingFee,
    required this.prioritySupport,
    required this.monthlyPrice,
  });

  final SubscriptionTier tier;
  final double maxAlertRadiusMiles;
  final int alertVolumePerDay;
  final bool zeroProcessingFee;
  final bool prioritySupport;
  final double monthlyPrice;

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
}
