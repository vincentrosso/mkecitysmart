import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/payment_receipt.dart';
import '../models/ticket.dart';
import '../providers/user_provider.dart';

class TicketWorkflowScreen extends StatefulWidget {
  const TicketWorkflowScreen({super.key});

  @override
  State<TicketWorkflowScreen> createState() => _TicketWorkflowScreenState();
}

class _TicketWorkflowScreenState extends State<TicketWorkflowScreen> {
  final _plateController = TextEditingController(text: 'MKE-5123');
  final _ticketController = TextEditingController(text: 'TCK-18421');
  Ticket? _selected;
  PaymentReceipt? _receipt;
  bool _lowIncome = false;
  bool _firstOffense = true;
  bool _resident = true;
  String _payMethod = 'card';

  @override
  void dispose() {
    _plateController.dispose();
    _ticketController.dispose();
    super.dispose();
  }

  void _lookup(UserProvider provider) {
    final ticket = provider.findTicket(
      _plateController.text.trim(),
      _ticketController.text.trim(),
    );
    setState(() {
      _selected = ticket;
      _receipt = null;
    });
    if (ticket == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket not found.')),
      );
    }
  }

  void _settle(UserProvider provider) {
    if (_selected == null) return;
    final receipt = provider.settleTicket(
      ticket: _selected!,
      method: _payMethod,
      lowIncome: _lowIncome,
      firstOffense: _firstOffense,
      resident: _resident,
    );
    setState(() {
      _receipt = receipt;
      _selected = provider.findTicket(_selected!.plate, _selected!.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ticket settled. Receipt ready.')),
    );
  }

  double _computeDue(Ticket ticket) {
    final overduePenalty = ticket.isOverdue ? 15.0 : 0.0;
    final base = ticket.amount + overduePenalty;
    double waiverPct = 0;
    if (_lowIncome) waiverPct += 0.35;
    if (_firstOffense) waiverPct += 0.25;
    if (_resident) waiverPct += 0.1;
    waiverPct = waiverPct.clamp(0, 0.6);
    final waiver = base * waiverPct;
    return (base - waiver).clamp(0, double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        final tickets = provider.tickets;
        final receipts = provider.receipts
            .where((r) => r.category == 'ticket')
            .toList();
        return Scaffold(
          appBar: AppBar(title: const Text('Ticket lookup & payment')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Lookup', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _plateController,
                        decoration: const InputDecoration(labelText: 'Plate'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _ticketController,
                        decoration: const InputDecoration(labelText: 'Ticket ID'),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => _lookup(provider),
                        child: const Text('Find ticket'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => provider.syncTicketsWithBackend(),
                icon: const Icon(Icons.cloud_sync),
                label: const Text('Sync with backend'),
              ),
              const SizedBox(height: 12),
              if (_selected != null) _TicketDetailCard(ticket: _selected!),
              if (_selected != null && _selected!.status == TicketStatus.open) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Apply fee-waive rules',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilterChip(
                              selected: _lowIncome,
                              label: const Text('Low-income'),
                              onSelected: (value) => setState(() => _lowIncome = value),
                            ),
                            FilterChip(
                              selected: _firstOffense,
                              label: const Text('First offense'),
                              onSelected: (value) =>
                                  setState(() => _firstOffense = value),
                            ),
                            FilterChip(
                              selected: _resident,
                              label: const Text('Resident'),
                              onSelected: (value) => setState(() => _resident = value),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'card', label: Text('Card')),
                            ButtonSegment(value: 'ach', label: Text('ACH')),
                          ],
                          selected: {_payMethod},
                          onSelectionChanged: (value) =>
                              setState(() => _payMethod = value.first),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => _settle(provider),
                          icon: const Icon(Icons.receipt_long),
                          label: Text(
                            'Pay \$${_computeDue(_selected!).toStringAsFixed(2)}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (_receipt != null) ...[
                const SizedBox(height: 12),
                _TicketReceipt(receipt: _receipt!),
              ],
              if (receipts.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Receipts',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...receipts.map(
                  (r) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.receipt_long),
                      title: Text(r.reference),
                      subtitle: Text(
                        '\$${r.amountCharged.toStringAsFixed(2)} • ${r.method.toUpperCase()}',
                      ),
                      trailing: Text(
                        r.createdAt.toLocal().toString().split('.').first,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Recent tickets',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...tickets.map((ticket) => _TicketListTile(ticket: ticket)),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _TicketDetailCard extends StatelessWidget {
  const _TicketDetailCard({required this.ticket});
  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (ticket.status) {
      TicketStatus.paid => Colors.green,
      TicketStatus.waived => Colors.blueGrey,
      TicketStatus.open => Colors.orange,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.confirmation_number, color: statusColor),
                const SizedBox(width: 8),
                Text(ticket.id, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Chip(
                  label: Text(ticket.status.name.toUpperCase()),
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  labelStyle: TextStyle(color: statusColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Plate: ${ticket.plate}'),
            Text('Reason: ${ticket.reason}'),
            Text('Location: ${ticket.location}'),
            Text('Issued: ${ticket.issuedAt.toLocal()}'),
            Text('Due: ${ticket.dueDate.toLocal()}'),
            const SizedBox(height: 8),
            Text('Base: \$${ticket.amount.toStringAsFixed(2)}'),
            if (ticket.isOverdue) const Text('Overdue penalty pending: \$15'),
            if (ticket.waiverReason != null && ticket.waiverReason!.isNotEmpty)
              Text('Waiver: ${ticket.waiverReason}'),
          ],
        ),
      ),
    );
  }
}

class _TicketListTile extends StatelessWidget {
  const _TicketListTile({required this.ticket});
  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final statusIcon = switch (ticket.status) {
      TicketStatus.paid => Icons.check_circle,
      TicketStatus.waived => Icons.task_alt,
      TicketStatus.open => Icons.pending_actions,
    };
    return Card(
      child: ListTile(
        leading: Icon(statusIcon),
        title: Text(ticket.id),
        subtitle: Text('${ticket.reason} • \$${ticket.amount.toStringAsFixed(0)}'),
        trailing: Text(ticket.status.name),
      ),
    );
  }
}

class _TicketReceipt extends StatelessWidget {
  const _TicketReceipt({required this.receipt});
  final PaymentReceipt receipt;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Receipt ${receipt.reference}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Amount: \$${receipt.amountCharged.toStringAsFixed(2)}'),
            if (receipt.waivedAmount > 0)
              Text('Waived: \$${receipt.waivedAmount.toStringAsFixed(2)}'),
            Text('Method: ${receipt.method.toUpperCase()}'),
            Text('Time: ${receipt.createdAt}'),
            if (receipt.description.isNotEmpty) Text(receipt.description),
          ],
        ),
      ),
    );
  }
}
