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

  bool get isOverdue => DateTime.now().isAfter(dueDate) && status == TicketStatus.open;

  Ticket copyWith({
    TicketStatus? status,
    DateTime? paidAt,
    String? waiverReason,
    String? paymentMethod,
  }) {
    return Ticket(
      id: id,
      plate: plate,
      amount: amount,
      reason: reason,
      location: location,
      issuedAt: issuedAt,
      dueDate: dueDate,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
      waiverReason: waiverReason ?? this.waiverReason,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}
