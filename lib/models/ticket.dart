enum TicketStatus { open, paid, waived }

class Ticket {
  const Ticket({
    required this.id,
    required this.plate,
    required this.amount,
    required this.reason,
    required this.location,
    required this.issuedAt,
    required this.dueDate,
    this.status = TicketStatus.open,
    this.paidAt,
    this.waiverReason,
    this.paymentMethod,
    this.photoPath,
    this.lateFeeAmount,
    this.lateFeeAfterDays,
    this.latitude,
    this.longitude,
    this.vehicleId,
  });

  final String id;
  final String plate;
  final double amount;
  final String reason;
  final String location;
  final DateTime issuedAt;
  final DateTime dueDate;
  final TicketStatus status;
  final DateTime? paidAt;
  final String? waiverReason;
  final String? paymentMethod;

  // New fields for enhanced tracking
  final String? photoPath; // Local path to ticket photo
  final double? lateFeeAmount; // Late fee amount (varies by violation)
  final int? lateFeeAfterDays; // Days after due date when late fee kicks in
  final double? latitude; // Citation location for risk engine
  final double? longitude; // Citation location for risk engine
  final String? vehicleId; // Link to registered vehicle

  /// Check if the ticket is past due
  bool get isOverdue =>
      DateTime.now().isAfter(dueDate) && status == TicketStatus.open;

  /// Calculate days overdue (0 if not overdue)
  int get daysOverdue {
    if (!isOverdue) return 0;
    return DateTime.now().difference(dueDate).inDays;
  }

  /// Calculate current amount owed including late fees
  double get currentAmountOwed {
    if (status != TicketStatus.open) return 0;

    final daysLate = daysOverdue;
    if (daysLate <= 0) return amount;

    // Apply late fee if past the grace period
    final graceDays = lateFeeAfterDays ?? 14; // Default 14 days grace
    final lateFee = lateFeeAmount ?? 15.0; // Default $15 late fee

    if (daysLate > graceDays) {
      return amount + lateFee;
    }
    return amount;
  }

  /// Check if late fee has been applied
  bool get hasLateFeeApplied {
    if (status != TicketStatus.open) return false;
    final graceDays = lateFeeAfterDays ?? 14;
    return daysOverdue > graceDays;
  }

  Ticket copyWith({
    String? id,
    String? plate,
    double? amount,
    String? reason,
    String? location,
    DateTime? issuedAt,
    DateTime? dueDate,
    TicketStatus? status,
    DateTime? paidAt,
    String? waiverReason,
    String? paymentMethod,
    String? photoPath,
    double? lateFeeAmount,
    int? lateFeeAfterDays,
    double? latitude,
    double? longitude,
    String? vehicleId,
  }) {
    return Ticket(
      id: id ?? this.id,
      plate: plate ?? this.plate,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      location: location ?? this.location,
      issuedAt: issuedAt ?? this.issuedAt,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
      waiverReason: waiverReason ?? this.waiverReason,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      photoPath: photoPath ?? this.photoPath,
      lateFeeAmount: lateFeeAmount ?? this.lateFeeAmount,
      lateFeeAfterDays: lateFeeAfterDays ?? this.lateFeeAfterDays,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      vehicleId: vehicleId ?? this.vehicleId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plate': plate,
      'amount': amount,
      'reason': reason,
      'location': location,
      'issuedAt': issuedAt.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'status': status.name,
      'paidAt': paidAt?.toIso8601String(),
      'waiverReason': waiverReason,
      'paymentMethod': paymentMethod,
      'photoPath': photoPath,
      'lateFeeAmount': lateFeeAmount,
      'lateFeeAfterDays': lateFeeAfterDays,
      'latitude': latitude,
      'longitude': longitude,
      'vehicleId': vehicleId,
    };
  }

  factory Ticket.fromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String? ?? TicketStatus.open.name;
    return Ticket(
      id: json['id'] as String? ?? '',
      plate: json['plate'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      reason: json['reason'] as String? ?? '',
      location: json['location'] as String? ?? '',
      issuedAt:
          DateTime.tryParse(json['issuedAt'] as String? ?? '') ??
          DateTime.now(),
      dueDate:
          DateTime.tryParse(json['dueDate'] as String? ?? '') ?? DateTime.now(),
      status: TicketStatus.values.firstWhere(
        (value) => value.name == statusName,
        orElse: () => TicketStatus.open,
      ),
      paidAt: DateTime.tryParse(json['paidAt'] as String? ?? ''),
      waiverReason: json['waiverReason'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      photoPath: json['photoPath'] as String?,
      lateFeeAmount: (json['lateFeeAmount'] as num?)?.toDouble(),
      lateFeeAfterDays: json['lateFeeAfterDays'] as int?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      vehicleId: json['vehicleId'] as String?,
    );
  }
}
