// Payment-related models and enums
enum PaymentMethod {
  creditCard,
  debitCard,
  paypal,
  applePay,
  googlePay,
  venmo,
  cash,
}

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  refunded,
  cancelled,
}

enum TransactionType { parking, permit, fine, refund }

class PaymentCard {
  final String id;
  final String lastFourDigits;
  final String cardType; // visa, mastercard, amex, etc.
  final String expiryMonth;
  final String expiryYear;
  final String holderName;
  final bool isDefault;

  PaymentCard({
    required this.id,
    required this.lastFourDigits,
    required this.cardType,
    required this.expiryMonth,
    required this.expiryYear,
    required this.holderName,
    this.isDefault = false,
  });

  factory PaymentCard.fromJson(Map<String, dynamic> json) {
    return PaymentCard(
      id: json['id'],
      lastFourDigits: json['last_four_digits'],
      cardType: json['card_type'],
      expiryMonth: json['expiry_month'],
      expiryYear: json['expiry_year'],
      holderName: json['holder_name'],
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'last_four_digits': lastFourDigits,
      'card_type': cardType,
      'expiry_month': expiryMonth,
      'expiry_year': expiryYear,
      'holder_name': holderName,
      'is_default': isDefault,
    };
  }

  String get maskedCardNumber {
    return '**** **** **** $lastFourDigits';
  }

  String get displayName {
    return '$cardType ending in $lastFourDigits';
  }
}

class PaymentTransaction {
  final String id;
  final double amount;
  final PaymentMethod paymentMethod;
  final PaymentStatus status;
  final TransactionType type;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? description;
  final String? referenceId; // parking spot, permit, etc.
  final PaymentCard? card;
  final String? failureReason;

  PaymentTransaction({
    required this.id,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.type,
    required this.createdAt,
    this.completedAt,
    this.description,
    this.referenceId,
    this.card,
    this.failureReason,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'],
      amount: json['amount']?.toDouble(),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString() == 'PaymentMethod.${json['payment_method']}',
        orElse: () => PaymentMethod.creditCard,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString() == 'PaymentStatus.${json['status']}',
        orElse: () => PaymentStatus.pending,
      ),
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${json['type']}',
        orElse: () => TransactionType.parking,
      ),
      createdAt: DateTime.parse(json['created_at']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      description: json['description'],
      referenceId: json['reference_id'],
      card: json['card'] != null ? PaymentCard.fromJson(json['card']) : null,
      failureReason: json['failure_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'payment_method': paymentMethod.toString().split('.').last,
      'status': status.toString().split('.').last,
      'type': type.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'description': description,
      'reference_id': referenceId,
      'card': card?.toJson(),
      'failure_reason': failureReason,
    };
  }

  String get formattedAmount {
    return '\$${amount.toStringAsFixed(2)}';
  }

  String get statusDisplayText {
    switch (status) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get typeDisplayText {
    switch (type) {
      case TransactionType.parking:
        return 'Parking Fee';
      case TransactionType.permit:
        return 'Parking Permit';
      case TransactionType.fine:
        return 'Parking Fine';
      case TransactionType.refund:
        return 'Refund';
    }
  }
}

class ParkingPayment {
  final String id;
  final String spotId;
  final String reservationId;
  final double hourlyRate;
  final int durationMinutes;
  final double totalAmount;
  final double tax;
  final double processingFee;
  final PaymentMethod paymentMethod;
  final PaymentCard? card;
  final DateTime startTime;
  final DateTime endTime;
  final PaymentStatus status;
  final DateTime createdAt;

  ParkingPayment({
    required this.id,
    required this.spotId,
    required this.reservationId,
    required this.hourlyRate,
    required this.durationMinutes,
    required this.totalAmount,
    this.tax = 0.0,
    this.processingFee = 0.0,
    required this.paymentMethod,
    this.card,
    required this.startTime,
    required this.endTime,
    this.status = PaymentStatus.pending,
    required this.createdAt,
  });

  factory ParkingPayment.fromJson(Map<String, dynamic> json) {
    return ParkingPayment(
      id: json['id'],
      spotId: json['spot_id'],
      reservationId: json['reservation_id'],
      hourlyRate: json['hourly_rate']?.toDouble(),
      durationMinutes: json['duration_minutes'],
      totalAmount: json['total_amount']?.toDouble(),
      tax: json['tax']?.toDouble() ?? 0.0,
      processingFee: json['processing_fee']?.toDouble() ?? 0.0,
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString() == 'PaymentMethod.${json['payment_method']}',
        orElse: () => PaymentMethod.creditCard,
      ),
      card: json['card'] != null ? PaymentCard.fromJson(json['card']) : null,
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString() == 'PaymentStatus.${json['status']}',
        orElse: () => PaymentStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'spot_id': spotId,
      'reservation_id': reservationId,
      'hourly_rate': hourlyRate,
      'duration_minutes': durationMinutes,
      'total_amount': totalAmount,
      'tax': tax,
      'processing_fee': processingFee,
      'payment_method': paymentMethod.toString().split('.').last,
      'card': card?.toJson(),
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
    };
  }

  double get subtotal {
    final hours = durationMinutes / 60.0;
    return hourlyRate * hours;
  }

  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    return '${minutes}m';
  }
}
