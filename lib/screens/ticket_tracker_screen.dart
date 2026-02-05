import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ticket.dart';
import '../models/user_preferences.dart';
import '../providers/user_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/citysmart_scaffold.dart';

/// Milwaukee parking violation types from 466K citation data analysis
/// Ordered by frequency (most common first)
const kMilwaukeeViolationTypes = [
  'NIGHT PARKING',
  'NIGHT PARKING - WINTER RESTRICTED',
  'PARKING PROHIBITED BY OFFICIAL SIGN',
  'NIGHT PARKING - WRONG SIDE',
  'METER PARKING VIOLATION',
  'PARKED IN EXCESS OF 2 HOURS PROHIBITED',
  'FAILURE TO DISPLAY CURRENT REGISTRATION',
  'UNREGISTERED/ IMPROPERLY REGISTERED VEHICLE',
  'PARKED LESS THAN 15 FEET FROM CROSSWALK',
  'PARKED WITHIN 4 FEET OF DRIVE OR ALLEY',
  'PARKED IN EXCESS OF 1 HOUR PROHIBITED',
  'RESIDENTIAL PARKING PROGRAM',
  'PARKED WITHIN 10 FEET OF FIRE HYDRANT',
  'OBSTRUCTING BUS LOADING ZONE',
  'TOW-AWAY ZONE (BLOCKING TRAFFIC)',
  'PARKED IN EXCESS OF 3 HOURS PROHIBITED',
  'PARKED IN LOADING ZONE',
  'PARKING IN EXCESS OF 24 HOURS',
  'NIGHT PARKING IN ALLEY',
  'PARKED MORE THAN 12 INCHES FROM CURB',
  'SNOW EMERGENCY',
  'PARKED POSTED PRIVATE PROPERTY',
  'NIGHT PARKING - INELIGIBLE VEHICLE',
  'PARKING IN HANDICAPPED AREA',
  'PARKED IN SCHOOL ZONE',
  'PARKED IN SAFETY ZONE',
  'PARKED ON SIDEWALK (SIDEWALK AREA)',
  'OTHER',
];

/// Enhanced ticket tracking screen with photo capture and manual entry
class TicketTrackerScreen extends StatefulWidget {
  const TicketTrackerScreen({super.key});

  @override
  State<TicketTrackerScreen> createState() => _TicketTrackerScreenState();
}

class _TicketTrackerScreenState extends State<TicketTrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showSampleHint = false;
  static const _sampleHintDismissedKey = 'ticket_sample_hint_dismissed';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkSampleHintStatus();
  }

  Future<void> _checkSampleHintStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool(_sampleHintDismissedKey) ?? false;
    if (mounted && !dismissed) {
      setState(() => _showSampleHint = true);
    }
  }

  Future<void> _dismissSampleHint() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sampleHintDismissedKey, true);
    if (mounted) {
      setState(() => _showSampleHint = false);
    }
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
        final openTickets = tickets
            .where((t) => t.status == TicketStatus.open)
            .toList();
        final paidTickets = tickets
            .where((t) => t.status != TicketStatus.open)
            .toList();

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
              // Summary card - uses currentAmountOwed for accurate late fee calculation
              _TicketSummaryCard(
                openCount: openTickets.length,
                totalOwed: openTickets.fold(
                  0.0,
                  (sum, t) => sum + t.currentAmountOwed,
                ),
                overdueCount: openTickets.where((t) => t.isOverdue).length,
                lateFeeCount: openTickets
                    .where((t) => t.hasLateFeeApplied)
                    .length,
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

              // Sample tickets hint - only show if there are sample tickets and hint not dismissed
              if (_showSampleHint && tickets.any((t) => t.isSample))
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kCitySmartYellow.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: kCitySmartYellow.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: kCitySmartYellow,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sample tickets for demo',
                              style: TextStyle(
                                color: kCitySmartYellow,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Swipe left on any ticket to delete it. These are just examples to show you how the tracker works.',
                              style: TextStyle(
                                color: kCitySmartText.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _dismissSampleHint,
                        icon: const Icon(
                          Icons.close,
                          color: kCitySmartMuted,
                          size: 20,
                        ),
                        tooltip: 'Dismiss',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
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
                            itemBuilder: (context, index) {
                              final ticket = openTickets[index];
                              return Dismissible(
                                key: Key(ticket.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                confirmDismiss: (direction) async {
                                  return await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Ticket?'),
                                          content: Text(
                                            ticket.isSample
                                                ? 'Remove this sample ticket?'
                                                : 'Are you sure you want to delete this ticket? This cannot be undone.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ) ??
                                      false;
                                },
                                onDismissed: (direction) {
                                  provider.deleteTicket(ticket.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        ticket.isSample
                                            ? 'Sample ticket removed'
                                            : 'Ticket deleted',
                                      ),
                                    ),
                                  );
                                },
                                child: _TicketCard(
                                  ticket: ticket,
                                  onPay: () =>
                                      _showPayDialog(context, provider, ticket),
                                  onContest: () =>
                                      _showContestDialog(context, ticket),
                                  onSetReminder: () =>
                                      _showReminderDialog(context, ticket),
                                ),
                              );
                            },
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
                            itemBuilder: (context, index) {
                              final ticket = paidTickets[index];
                              return Dismissible(
                                key: Key(ticket.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                confirmDismiss: (direction) async {
                                  return await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Ticket?'),
                                          content: Text(
                                            ticket.isSample
                                                ? 'Remove this sample ticket?'
                                                : 'Remove this paid ticket from history?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ) ??
                                      false;
                                },
                                onDismissed: (direction) {
                                  provider.deleteTicket(ticket.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        ticket.isSample
                                            ? 'Sample ticket removed'
                                            : 'Ticket removed from history',
                                      ),
                                    ),
                                  );
                                },
                                child: _PaidTicketCard(ticket: ticket),
                              );
                            },
                          ),

                    // Add new ticket
                    _AddTicketForm(
                      onSubmit: (ticket) {
                        provider.addTicket(ticket);
                        _tabController.animateTo(0);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ticket added for tracking'),
                          ),
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

  void _showPayDialog(
    BuildContext context,
    UserProvider provider,
    Ticket ticket,
  ) {
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Payment recorded!')));
        },
      ),
    );
  }

  void _showContestDialog(BuildContext context, Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCitySmartCard,
        title: const Text(
          'Contest ticket',
          style: TextStyle(color: kCitySmartText),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To contest a Milwaukee parking ticket:',
              style: TextStyle(color: kCitySmartText),
            ),
            const SizedBox(height: 12),
            _ContestStep(
              number: '1',
              text: 'Visit milwaukee.gov/parkingtickets',
            ),
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

  void _showReminderDialog(BuildContext context, Ticket ticket) {
    final daysUntilDue = ticket.dueDate.difference(DateTime.now()).inDays;
    final dueDateFormatted = DateFormat('MMM d, yyyy').format(ticket.dueDate);

    showModalBottomSheet(
      context: context,
      backgroundColor: kCitySmartCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4FC3F7).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_active,
                    color: Color(0xFF4FC3F7),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Set Payment Reminder',
                        style: TextStyle(
                          color: kCitySmartText,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ticket #${ticket.id} • Due $dueDateFormatted',
                        style: const TextStyle(
                          color: kCitySmartMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Late fees add \$15 after the due date. Don\'t let a forgotten ticket cost you more!',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Choose reminder timing:',
              style: TextStyle(
                color: kCitySmartText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _ReminderOption(
              icon: Icons.today,
              title: '1 day before',
              subtitle: daysUntilDue > 1 ? 'Recommended' : 'Not available',
              enabled: daysUntilDue > 1,
              onTap: () => _scheduleReminder(context, ticket, 1),
            ),
            _ReminderOption(
              icon: Icons.date_range,
              title: '3 days before',
              subtitle: daysUntilDue > 3
                  ? 'Good for planning'
                  : 'Not available',
              enabled: daysUntilDue > 3,
              onTap: () => _scheduleReminder(context, ticket, 3),
            ),
            _ReminderOption(
              icon: Icons.calendar_month,
              title: '1 week before',
              subtitle: daysUntilDue > 7 ? 'Early heads up' : 'Not available',
              enabled: daysUntilDue > 7,
              onTap: () => _scheduleReminder(context, ticket, 7),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _scheduleReminder(
    BuildContext context,
    Ticket ticket,
    int daysBefore,
  ) async {
    // Check if user has ticket due date reminders enabled (privacy option)
    final provider = context.read<UserProvider>();
    final prefs = provider.profile?.preferences ?? UserPreferences.defaults();
    if (!prefs.ticketDueDateReminders) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ticket reminders are disabled. Enable in Settings > Preferences.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final reminderDate = ticket.dueDate.subtract(Duration(days: daysBefore));
    final reminderTime = DateTime(
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      9,
      0,
    ); // 9 AM

    await NotificationService.instance.scheduleLocal(
      title: '💳 Parking Ticket Due Soon!',
      body:
          'Ticket #${ticket.id} for \$${ticket.amount.toStringAsFixed(2)} is due in $daysBefore day${daysBefore == 1 ? '' : 's'}. Pay now to avoid late fees!',
      when: reminderTime,
      id: ticket.id.hashCode + daysBefore,
    );

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reminder set for ${DateFormat('MMM d').format(reminderTime)} at 9:00 AM',
          ),
          backgroundColor: const Color(0xFF4FC3F7),
        ),
      );
    }
  }
}

class _TicketSummaryCard extends StatelessWidget {
  final int openCount;
  final double totalOwed;
  final int overdueCount;
  final int lateFeeCount;

  const _TicketSummaryCard({
    required this.openCount,
    required this.totalOwed,
    required this.overdueCount,
    this.lateFeeCount = 0,
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
                  openCount == 0
                      ? 'All clear!'
                      : '$openCount open ticket${openCount == 1 ? '' : 's'}',
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
                      const Icon(
                        Icons.warning_amber,
                        color: Colors.yellow,
                        size: 16,
                      ),
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
  final VoidCallback? onSetReminder;

  const _TicketCard({
    required this.ticket,
    required this.onPay,
    required this.onContest,
    this.onSetReminder,
  });

  @override
  Widget build(BuildContext context) {
    final daysUntilDue = ticket.dueDate.difference(DateTime.now()).inDays;
    // Use the model's currentAmountOwed for accurate late fee calculation
    final totalDue = ticket.currentAmountOwed;
    final lateFee = ticket.lateFeeAmount ?? 15.0;

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
                        style: const TextStyle(
                          color: kCitySmartMuted,
                          fontSize: 13,
                        ),
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
                        color: ticket.hasLateFeeApplied
                            ? Colors.red
                            : kCitySmartYellow,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    if (ticket.hasLateFeeApplied)
                      Text(
                        '+\$${lateFee.toStringAsFixed(0)} late fee',
                        style: const TextStyle(color: Colors.red, fontSize: 11),
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
                    style: const TextStyle(
                      color: kCitySmartMuted,
                      fontSize: 12,
                    ),
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
                    fontWeight: ticket.isOverdue
                        ? FontWeight.bold
                        : FontWeight.normal,
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
            // Reminder button - help avoid late fees
            if (!ticket.isOverdue && onSetReminder != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onSetReminder,
                  icon: const Icon(Icons.notifications_active, size: 18),
                  label: Text(
                    daysUntilDue <= 3
                        ? 'Set reminder - Due soon!'
                        : 'Set payment reminder',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: daysUntilDue <= 3
                        ? Colors.orange
                        : const Color(0xFF4FC3F7),
                    side: BorderSide(
                      color: daysUntilDue <= 3
                          ? Colors.orange
                          : const Color(0xFF4FC3F7),
                    ),
                  ),
                ),
              ),
            ],
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
          style: const TextStyle(
            color: kCitySmartText,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${ticket.reason} • ${ticket.status == TicketStatus.waived ? "Waived" : "Paid"} ${ticket.paidAt != null ? DateFormat('M/d/yy').format(ticket.paidAt!) : ""}',
          style: const TextStyle(color: kCitySmartMuted, fontSize: 12),
        ),
        trailing: Text(
          '\$${ticket.amount.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
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
  final _amountController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedViolation;
  String? _selectedVehicleId;
  String _manualPlate = '';
  DateTime _issuedDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 14));
  File? _photoFile;
  bool _useManualPlate = false;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _ticketIdController.dispose();
    _amountController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() => _photoFile = File(photo.path));
        // Future enhancement: Use ML Kit OCR to extract ticket details from photo
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Photo captured! Enter details manually.'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Camera error: $e');
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to access camera. Check permissions in Settings.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final photo = await _picker.pickImage(source: ImageSource.gallery);
      if (photo != null) {
        setState(() => _photoFile = File(photo.path));
      }
    } catch (e) {
      debugPrint('❌ Gallery error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to access photo library. Check permissions in Settings.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Save photo to app's local documents directory
  Future<String?> _savePhotoLocally(File photo, String ticketId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final ticketPhotosDir = Directory('${appDir.path}/ticket_photos');
      if (!await ticketPhotosDir.exists()) {
        await ticketPhotosDir.create(recursive: true);
      }
      final fileName =
          'ticket_${ticketId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = '${ticketPhotosDir.path}/$fileName';
      await photo.copy(savedPath);
      debugPrint('📷 Ticket photo saved to: $savedPath');
      return savedPath;
    } catch (e) {
      debugPrint('❌ Failed to save ticket photo: $e');
      return null;
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Get plate from vehicle or manual entry
      final provider = context.read<UserProvider>();
      String plate;
      String? vehicleId;

      if (_useManualPlate) {
        plate = _manualPlate.trim().toUpperCase();
      } else if (_selectedVehicleId != null) {
        final vehicle = provider.profile?.vehicles.firstWhere(
          (v) => v.id == _selectedVehicleId,
          orElse: () => provider.profile!.vehicles.first,
        );
        plate = vehicle?.licensePlate ?? '';
        vehicleId = _selectedVehicleId;
      } else {
        plate = '';
      }

      // Save photo locally if captured
      String? savedPhotoPath;
      final ticketId = _ticketIdController.text.trim();
      if (_photoFile != null) {
        savedPhotoPath = await _savePhotoLocally(_photoFile!, ticketId);
      }

      // Try to geocode the location for risk engine data
      double? latitude;
      double? longitude;
      final locationText = _locationController.text.trim();
      if (locationText.isNotEmpty) {
        try {
          // Add Milwaukee, WI context for better geocoding results
          final searchText = locationText.contains('Milwaukee')
              ? locationText
              : '$locationText, Milwaukee, WI';
          final locations = await geocoding.locationFromAddress(searchText);
          if (locations.isNotEmpty) {
            latitude = locations.first.latitude;
            longitude = locations.first.longitude;
            debugPrint('📍 Ticket location geocoded: $latitude, $longitude');
          }
        } catch (e) {
          debugPrint('⚠️ Could not geocode ticket location: $e');
          // Continue without coordinates - not critical
        }
      }

      final ticket = Ticket(
        id: ticketId,
        plate: plate,
        amount: double.tryParse(_amountController.text) ?? 0,
        reason: _selectedViolation ?? 'OTHER',
        location: locationText,
        issuedAt: _issuedDate,
        dueDate: _dueDate,
        photoPath: savedPhotoPath,
        vehicleId: vehicleId,
        latitude: latitude,
        longitude: longitude,
      );
      widget.onSubmit(ticket);

      // Log citation data for risk engine improvement
      if (latitude != null && longitude != null) {
        debugPrint(
          '🎯 Citation data logged for risk engine: $locationText ($latitude, $longitude) - $_selectedViolation',
        );
      }

      // Clear form
      _ticketIdController.clear();
      _amountController.clear();
      _locationController.clear();
      setState(() {
        _photoFile = null;
        _selectedViolation = null;
        _selectedVehicleId = null;
        _manualPlate = '';
        _useManualPlate = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    final vehicles = provider.profile?.vehicles ?? [];

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
                      style: TextStyle(
                        color: kCitySmartText,
                        fontWeight: FontWeight.w600,
                      ),
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
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () =>
                                  setState(() => _photoFile = null),
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

            // Vehicle selection - dropdown or manual entry
            if (vehicles.isNotEmpty && !_useManualPlate) ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedVehicleId,
                decoration: const InputDecoration(
                  labelText: 'Vehicle *',
                  prefixIcon: Icon(Icons.directions_car),
                ),
                items: vehicles.map((v) {
                  return DropdownMenuItem(
                    value: v.id,
                    child: Text(
                      '${v.nickname.isNotEmpty ? v.nickname : v.make} - ${v.licensePlate}',
                    ),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedVehicleId = value),
                validator: (v) => v == null ? 'Select a vehicle' : null,
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => setState(() => _useManualPlate = true),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Enter plate manually'),
              ),
            ] else ...[
              TextFormField(
                initialValue: _manualPlate,
                decoration: InputDecoration(
                  labelText: 'License plate *',
                  hintText: 'e.g., ABC-1234',
                  prefixIcon: const Icon(Icons.directions_car),
                  suffixIcon: vehicles.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.list),
                          tooltip: 'Select from vehicles',
                          onPressed: () => setState(() {
                            _useManualPlate = false;
                            _manualPlate = '';
                          }),
                        )
                      : null,
                ),
                textCapitalization: TextCapitalization.characters,
                onChanged: (v) => _manualPlate = v,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
            ],
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

            // Violation type dropdown with real Milwaukee data
            DropdownButtonFormField<String>(
              initialValue: _selectedViolation,
              decoration: const InputDecoration(
                labelText: 'Violation type *',
                prefixIcon: Icon(Icons.warning_amber),
              ),
              isExpanded: true,
              items: kMilwaukeeViolationTypes.map((violation) {
                return DropdownMenuItem(
                  value: violation,
                  child: Text(
                    violation,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedViolation = value),
              validator: (v) => v == null ? 'Select a violation type' : null,
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
              const Text(
                'Base amount:',
                style: TextStyle(color: kCitySmartMuted),
              ),
              Text(
                '\$${ticket.amount.toStringAsFixed(2)}',
                style: const TextStyle(color: kCitySmartText),
              ),
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
              const Text(
                'Total:',
                style: TextStyle(
                  color: kCitySmartText,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
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

class _ReminderOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  const _ReminderOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: enabled
                ? kCitySmartGreen.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled
                  ? kCitySmartGreen.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: enabled
                      ? const Color(0xFF4FC3F7).withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: enabled ? const Color(0xFF4FC3F7) : Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: enabled ? kCitySmartText : kCitySmartMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: enabled ? kCitySmartMuted : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (enabled)
                const Icon(Icons.chevron_right, color: kCitySmartMuted),
            ],
          ),
        ),
      ),
    );
  }
}
