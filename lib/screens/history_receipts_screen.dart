import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/payment_receipt.dart';
import '../models/ticket.dart';
import '../providers/user_provider.dart';

class HistoryReceiptsScreen extends StatelessWidget {
  const HistoryReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        final receipts = provider.receipts;
        final tickets = provider.tickets;
        return Scaffold(
          appBar: AppBar(title: const Text('Receipts & Tickets')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Receipts (${receipts.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (receipts.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No receipts yet. Complete a permit or ticket flow.',
                    ),
                  ),
                )
              else
                ...receipts.map((r) => _ReceiptTile(receipt: r)),
              const SizedBox(height: 16),
              Text(
                'Tickets (${tickets.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (tickets.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No tickets on file.'),
                  ),
                )
              else
                ...tickets.map((t) => _TicketTile(ticket: t)),
            ],
          ),
        );
      },
    );
  }
}

class _ReceiptTile extends StatelessWidget {
  const _ReceiptTile({required this.receipt});
  final PaymentReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      '\$${receipt.amountCharged.toStringAsFixed(2)}',
      if (receipt.waivedAmount > 0)
        'Waived \$${receipt.waivedAmount.toStringAsFixed(2)}',
      receipt.method.toUpperCase(),
    ].join(' • ');
    return Card(
      child: ListTile(
        leading: Icon(
          receipt.category == 'ticket' ? Icons.receipt_long : Icons.badge,
          color: receipt.category == 'ticket' ? Colors.blueGrey : Colors.green,
        ),
        title: Text(receipt.reference),
        subtitle: Text(subtitle),
        trailing: Text(
          receipt.createdAt.toLocal().toString().split('.').first,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  const _TicketTile({required this.ticket});
  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (ticket.status) {
      TicketStatus.paid => Colors.green,
      TicketStatus.waived => Colors.blueGrey,
      TicketStatus.open => Colors.orange,
    };
    return Card(
      child: ListTile(
        leading: Icon(Icons.confirmation_number, color: statusColor),
        title: Text(ticket.id),
        subtitle: Text(
          '${ticket.reason} • \$${ticket.amount.toStringAsFixed(0)}',
        ),
        trailing: Text(ticket.status.name.toUpperCase()),
      ),
    );
  }
}
