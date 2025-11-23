import '../models/ticket.dart';

final sampleTickets = <Ticket>[
  Ticket(
    id: 'TCK-18421',
    plate: 'MKE-5123',
    amount: 45,
    reason: 'Street cleaning violation',
    location: 'Holton & Center',
    issuedAt: DateTime.now().subtract(const Duration(days: 4)),
    dueDate: DateTime.now().add(const Duration(days: 10)),
  ),
  Ticket(
    id: 'TCK-22018',
    plate: 'EV-2108',
    amount: 65,
    reason: 'Overtime parking',
    location: '3rd Ward Garage',
    issuedAt: DateTime.now().subtract(const Duration(days: 12)),
    dueDate: DateTime.now().subtract(const Duration(days: 1)),
  ),
  Ticket(
    id: 'TCK-99004',
    plate: 'FLEET-42',
    amount: 120,
    reason: 'Unauthorized commercial loading',
    location: 'Harbor District',
    issuedAt: DateTime.now().subtract(const Duration(days: 20)),
    dueDate: DateTime.now().subtract(const Duration(days: 5)),
    status: TicketStatus.paid,
    paidAt: DateTime.now().subtract(const Duration(days: 2)),
    paymentMethod: 'card',
  ),
];
