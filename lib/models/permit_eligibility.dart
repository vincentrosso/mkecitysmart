import 'permit.dart';

class PermitEligibilityResult {
  const PermitEligibilityResult({
    required this.permitType,
    required this.eligible,
    required this.reason,
    required this.baseFee,
    required this.surcharges,
    required this.waiverAmount,
    required this.totalDue,
    this.notes = const [],
  });

  final PermitType permitType;
  final bool eligible;
  final String reason;
  final double baseFee;
  final double surcharges;
  final double waiverAmount;
  final double totalDue;
  final List<String> notes;
}
