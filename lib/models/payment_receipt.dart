class PaymentReceipt {
  const PaymentReceipt({
    required this.id,
    required this.amountCharged,
    required this.method,
    required this.reference,
    required this.createdAt,
    this.waivedAmount = 0,
    this.description = '',
    this.category = 'general',
  });

  final String id;
  final double amountCharged;
  final String method;
  final String reference;
  final DateTime createdAt;
  final double waivedAmount;
  final String description;
  final String category;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amountCharged': amountCharged,
      'method': method,
      'reference': reference,
      'createdAt': createdAt.toIso8601String(),
      'waivedAmount': waivedAmount,
      'description': description,
      'category': category,
    };
  }

  factory PaymentReceipt.fromJson(Map<String, dynamic> json) {
    return PaymentReceipt(
      id: json['id'] as String? ?? '',
      amountCharged: (json['amountCharged'] as num?)?.toDouble() ?? 0,
      method: json['method'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      waivedAmount: (json['waivedAmount'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
    );
  }
}
