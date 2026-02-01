import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/ticket.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/citysmart_scaffold.dart';

/// Enhanced ticket tracking screen with photo capture and manual entry
class TicketTrackerScreen extends StatefulWidget {
  const TicketTrackerScreen({super.key});

  @override
  State<TicketTrackerScreen> createState() => _TicketTrackerScreenState();
}

class _TicketTrackerScreenState extends State<TicketTrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        final tickets = provider.tickets;
        final openTickets = tickets.where((t) => t.status == TicketStatus.open).toList();
        final paidTickets = tickets.where((t) => t.status != TicketStatus.open).toList();
        
        return CitySmartScaffold(
          title: 'My tickets',
          currentIndex: 0,
          actions: [
            IconButton(
              onPressed: () => _showAddTicketDialog(context, provider),
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Add ticket',
            ),
          ],
          body: Column(
            children: [
              // Summary card
              _TicketSummaryCard(
                openCount: openTickets.length,
                totalOwed: openTickets.fold(0.0, (sum, t) => sum + t.amount + (t.isOverdue ? 15 : 0)),
                overdueCount: openTickets.where((t) => t.isOverdue).length,
              ),
              
              // Tabs
              TabBar(
                controller: _tabController,
                labelColor: kCitySmartYellow,
                unselectedLabelColor: kCitySmartMuted,
                indicatorColor: kCitySmartYellow,
                tabs: [
                  Tab(text: 'Open (${openTickets.length})'),
                  Tab(text: 'Paid (${paidTickets.length})'),
                  const Tab(text: 'Add new'),
                ],
              ),
              
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Open tickets
                    openTickets.isEmpty
                        ? const _EmptyState(
                            icon: Icons.check_circle_outline,
                            title: 'No open tickets',
                            subtitle: 'You\'re all caught up!',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: openTickets.length,
                            itemBuilder: (context, index) => _TicketCard(
                              ticket: openTickets[index],
                              onPay: () => _showPayDialog(context, provider, openTickets[index]),
                              onContest: () => _showContestDialog(context, openTickets[index]),
                            ),
                          ),
                    
                    // Paid/resolved tickets
                    paidTickets.isEmpty
                        ? const _EmptyState(
                            icon: Icons.history,
                            title: 'No payment history',
                            subtitle: 'Paid tickets will appear here',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: paidTickets.length,
                            itemBuilder: (context, index) => _PaidTicketCard(
                              ticket: paidTickets[index],
                            ),
                          ),
                    
                    // Add new ticket
                    _AddTicketForm(
                      onSubmit: (ticket) {
                        provider.addTicket(ticket);
                        _tabController.animateTo(0);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ticket added for tracking')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddTicketDialog(BuildContext context, UserProvider provider) {
    _tabController.animateTo(2); // Switch to Add tab
  }

  void _showPayDialog(BuildContext context, UserProvider provider, Ticket ticket) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kCitySmartCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _PaymentSheet(
        ticket: ticket,
        onPay: (method) {
          provider.settleTicket(
            ticket: ticket,
            method: method,
            lowIncome: false,
            firstOffense: false,
            resident: true,
          );
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment recorded!')),
          );
        },
      ),
    );
  }

  void _showContestDialog(BuildContext context, Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCitySmartCard,
        title: const Text('Contest ticket', style: TextStyle(color: kCitySmartText)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To contest a Milwaukee parking ticket:',
              style: TextStyle(color: kCitySmartText),
            ),
            const SizedBox(height: 12),
            _ContestStep(number: '1', text: 'Visit milwaukee.gov/parkingtickets'),
            _ContestStep(number: '2', text: 'Select "Contest a Ticket"'),
            _ContestStep(number: '3', text: 'Enter ticket # ${ticket.id}'),
            _ContestStep(number: '4', text: 'Provide your evidence/reason'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _TicketSummaryCard extends StatelessWidget {
  final int openCount;
  final double totalOwed;
  final int overdueCount;

  const _TicketSummaryCard({
    required this.openCount,
    required this.totalOwed,
    required this.overdueCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: overdueCount > 0
              ? [Colors.red.shade900, Colors.red.shade700]
              : [kCitySmartGreen, const Color(0xFF0D2924)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  openCount == 0 ? 'All clear!' : '$openCount open ticket${openCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (openCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Total owed: \$${totalOwed.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
                if (overdueCount > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.yellow, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$overdueCount overdue - late fees apply!',
                        style: const TextStyle(
                          color: Colors.yellow,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              openCount == 0 ? Icons.check_circle : Icons.receipt_long,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onPay;
  final VoidCallback onContest;

  const _TicketCard({
    required this.ticket,
    required this.onPay,
    required this.onContest,
  });

  @override
  Widget build(BuildContext context) {
    final daysUntilDue = ticket.dueDate.difference(DateTime.now()).inDays;
    final totalDue = ticket.amount + (ticket.isOverdue ? 15 : 0);
    
    return Card(
      color: kCitySmartCard,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: ticket.isOverdue ? Colors.red : const Color(0xFF1F3A34),
          width: ticket.isOverdue ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ticket.isOverdue
                        ? Colors.red.withValues(alpha: 0.2)
                        : kCitySmartYellow.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: ticket.isOverdue ? Colors.red : kCitySmartYellow,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.id,
                        style: const TextStyle(
                          color: kCitySmartText,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        ticket.reason,
                        style: const TextStyle(color: kCitySmartMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${totalDue.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: ticket.isOverdue ? Colors.red : kCitySmartYellow,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    if (ticket.isOverdue)
                      const Text(
                        '+\$15 late fee',
                        style: TextStyle(color: Colors.red, fontSize: 11),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: kCitySmartMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    ticket.location,
                    style: const TextStyle(color: kCitySmartMuted, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.directions_car, size: 14, color: kCitySmartMuted),
                const SizedBox(width: 4),
                Text(
                  'Plate: ${ticket.plate}',
                  style: const TextStyle(color: kCitySmartMuted, fontSize: 12),
                ),
                const Spacer(),
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: ticket.isOverdue ? Colors.red : kCitySmartMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  ticket.isOverdue
                      ? 'Overdue!'
                      : daysUntilDue == 0
                          ? 'Due today'
                          : 'Due in $daysUntilDue days',
                  style: TextStyle(
                    color: ticket.isOverdue ? Colors.red : kCitySmartMuted,
                    fontSize: 12,
                    fontWeight: ticket.isOverdue ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onContest,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kCitySmartMuted,
                      side: const BorderSide(color: kCitySmartMuted),
                    ),
                    child: const Text('Contest'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onPay,
                    style: FilledButton.styleFrom(
                      backgroundColor: kCitySmartYellow,
                      foregroundColor: kCitySmartGreen,
                    ),
                    child: const Text('Pay now'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaidTicketCard extends StatelessWidget {
  final Ticket ticket;

  const _PaidTicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kCitySmartCard,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF1F3A34)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.check_circle, color: Colors.green),
        ),
        title: Text(
          ticket.id,
          style: const TextStyle(color: kCitySmartText, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${ticket.reason} • ${ticket.status == TicketStatus.waived ? "Waived" : "Paid"} ${ticket.paidAt != null ? DateFormat('M/d/yy').format(ticket.paidAt!) : ""}',
          style: const TextStyle(color: kCitySmartMuted, fontSize: 12),
        ),
        trailing: Text(
          '\$${ticket.amount.toStringAsFixed(2)}',
          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _AddTicketForm extends StatefulWidget {
  final void Function(Ticket) onSubmit;

  const _AddTicketForm({required this.onSubmit});

  @override
  State<_AddTicketForm> createState() => _AddTicketFormState();
}

class _AddTicketFormState extends State<_AddTicketForm> {
  final _formKey = GlobalKey<FormState>();
  final _ticketIdController = TextEditingController();
  final _plateController = TextEditingController();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime _issuedDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 14));
  File? _photoFile;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _ticketIdController.dispose();
    _plateController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() => _photoFile = File(photo.path));
      // TODO: Use OCR to extract ticket details from photo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo captured! Enter details manually.')),
      );
    }
  }

  Future<void> _pickPhoto() async {
    final photo = await _picker.pickImage(source: ImageSource.gallery);
    if (photo != null) {
      setState(() => _photoFile = File(photo.path));
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final ticket = Ticket(
        id: _ticketIdController.text.trim(),
        plate: _plateController.text.trim().toUpperCase(),
        amount: double.tryParse(_amountController.text) ?? 0,
        reason: _reasonController.text.trim(),
        location: _locationController.text.trim(),
        issuedAt: _issuedDate,
        dueDate: _dueDate,
      );
      widget.onSubmit(ticket);
      // Clear form
      _ticketIdController.clear();
      _plateController.clear();
      _amountController.clear();
      _reasonController.clear();
      _locationController.clear();
      setState(() => _photoFile = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo capture section
            Card(
              color: kCitySmartCard,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Snap a photo of your ticket',
                      style: TextStyle(color: kCitySmartText, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    if (_photoFile != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _photoFile!,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => setState(() => _photoFile = null),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _takePhoto,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Camera'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: _pickPhoto,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Manual entry form
            const Text(
              'Or enter details manually',
              style: TextStyle(color: kCitySmartMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _ticketIdController,
              decoration: const InputDecoration(
                labelText: 'Ticket number *',
                hintText: 'e.g., TCK-12345',
                prefixIcon: Icon(Icons.tag),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _plateController,
              decoration: const InputDecoration(
                labelText: 'License plate *',
                hintText: 'e.g., ABC-1234',
                prefixIcon: Icon(Icons.directions_car),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount *',
                hintText: 'e.g., 50.00',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v?.isEmpty ?? true) return 'Required';
                if (double.tryParse(v!) == null) return 'Enter valid amount';
                return null;
              },
            ),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Violation type',
                hintText: 'e.g., Expired meter',
                prefixIcon: Icon(Icons.warning_amber),
              ),
            ),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'e.g., 123 N Water St',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 12),
            
            // Date pickers
            Row(
              children: [
                Expanded(
                  child: _DatePickerField(
                    label: 'Issued date',
                    date: _issuedDate,
                    onChanged: (d) => setState(() => _issuedDate = d),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DatePickerField(
                    label: 'Due date',
                    date: _dueDate,
                    onChanged: (d) => setState(() => _dueDate = d),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.add),
              label: const Text('Add ticket to tracker'),
              style: FilledButton.styleFrom(
                backgroundColor: kCitySmartYellow,
                foregroundColor: kCitySmartGreen,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final void Function(DateTime) onChanged;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          DateFormat('M/d/yy').format(date),
          style: const TextStyle(color: kCitySmartText),
        ),
      ),
    );
  }
}

class _PaymentSheet extends StatelessWidget {
  final Ticket ticket;
  final void Function(String method) onPay;

  const _PaymentSheet({required this.ticket, required this.onPay});

  @override
  Widget build(BuildContext context) {
    final total = ticket.amount + (ticket.isOverdue ? 15 : 0);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Pay ticket',
            style: TextStyle(
              color: kCitySmartText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ticket:', style: TextStyle(color: kCitySmartMuted)),
              Text(ticket.id, style: const TextStyle(color: kCitySmartText)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Base amount:', style: TextStyle(color: kCitySmartMuted)),
              Text('\$${ticket.amount.toStringAsFixed(2)}', style: const TextStyle(color: kCitySmartText)),
            ],
          ),
          if (ticket.isOverdue) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Late fee:', style: TextStyle(color: Colors.red)),
                Text('\$15.00', style: TextStyle(color: Colors.red)),
              ],
            ),
          ],
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total:', style: TextStyle(color: kCitySmartText, fontWeight: FontWeight.bold)),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: kCitySmartYellow,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => onPay('card'),
            icon: const Icon(Icons.credit_card),
            label: const Text('Pay with card'),
            style: FilledButton.styleFrom(
              backgroundColor: kCitySmartYellow,
              foregroundColor: kCitySmartGreen,
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => onPay('ach'),
            icon: const Icon(Icons.account_balance),
            label: const Text('Pay with bank (ACH)'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Note: This marks the ticket as paid in your tracker. Visit milwaukee.gov to make actual payment.',
            style: TextStyle(color: kCitySmartMuted, fontSize: 11),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

class _ContestStep extends StatelessWidget {
  final String number;
  final String text;

  const _ContestStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: kCitySmartYellow,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: kCitySmartGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: kCitySmartMuted)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: kCitySmartMuted),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: kCitySmartText,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: kCitySmartMuted)),
        ],
      ),
    );
  }
}
