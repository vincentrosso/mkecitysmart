class PaymentReceipt {
  const PaymentReceipt({
    required this.id,
    required this.amountCharged,
    required this.method,
    required this.reference,
    required this.createdAt,
    this.waivedAmount = 0,
    this.description = '',
  });

  final String id;
  final double amountCharged;
  final String method;
  final String reference;
  final DateTime createdAt;
  final double waivedAmount;
  final String description;
}
