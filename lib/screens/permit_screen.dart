import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/permit.dart';
import '../widgets/app_drawer.dart';

class PermitScreen extends StatelessWidget {
  const PermitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF003E29),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003E29),
        title: const Text('Permits', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddPermitDialog(context),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final permits = userProvider.permits;
          final activePermits = userProvider.getActivePermits();

          if (permits.isEmpty) {
            return _buildEmptyState(context);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active Permits Section
                if (activePermits.isNotEmpty) ...[
                  const Text(
                    'Active Permits',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...activePermits.map(
                    (permit) => _buildPermitCard(context, permit, true),
                  ),
                  const SizedBox(height: 24),
                ],

                // All Permits Section
                const Text(
                  'All Permits',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...permits.map(
                  (permit) => _buildPermitCard(context, permit, false),
                ),

                const SizedBox(height: 100), // Space for FAB
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFC107),
        foregroundColor: Colors.black,
        onPressed: () => _showAddPermitDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.credit_card, size: 80, color: Colors.white54),
            const SizedBox(height: 24),
            const Text(
              'No Permits Found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first parking permit to get started',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showAddPermitDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Permit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermitCard(BuildContext context, Permit permit, bool showQR) {
    final isExpired = permit.isExpired;
    final isActive = permit.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF006A3B) : Colors.grey.shade700,
        borderRadius: BorderRadius.circular(12),
        border: isExpired
            ? Border.all(color: Colors.red, width: 2)
            : isActive
            ? Border.all(color: const Color(0xFFFFC107), width: 2)
            : null,
      ),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: isActive ? const Color(0xFFFFC107) : Colors.grey,
              child: Icon(_getPermitTypeIcon(permit.type), color: Colors.black),
            ),
            title: Text(
              permit.permitNumber,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getPermitTypeName(permit.type),
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  permit.vehicle.licensePlate,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (permit.zone != null)
                  Text(
                    'Zone: ${permit.zone}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
              ],
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isExpired
                        ? Colors.red
                        : isActive
                        ? Colors.green
                        : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isExpired
                        ? 'Expired'
                        : isActive
                        ? 'Active'
                        : 'Inactive',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Expires: ${_formatDate(permit.endDate)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
            onTap: () => _showPermitDetails(context, permit),
          ),

          // QR Code Section (only for active permits or when requested)
          if (showQR && isActive) ...[
            const Divider(color: Colors.white24),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Show to parking enforcement',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(Icons.qr_code, size: 80, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    permit.permitNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showPermitDetails(BuildContext context, Permit permit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF003E29),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Permit Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // QR Code
              if (permit.isActive) ...[
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.qr_code,
                        size: 120,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Permit Information
              _buildDetailRow('Permit Number', permit.permitNumber),
              _buildDetailRow('Type', _getPermitTypeName(permit.type)),
              _buildDetailRow(
                'Status',
                permit.isActive
                    ? 'Active'
                    : permit.isExpired
                    ? 'Expired'
                    : 'Inactive',
              ),
              _buildDetailRow(
                'Vehicle',
                '${permit.vehicle.make} ${permit.vehicle.model} (${permit.vehicle.licensePlate})',
              ),
              if (permit.zone != null) _buildDetailRow('Zone', permit.zone!),
              _buildDetailRow('Start Date', _formatDate(permit.startDate)),
              _buildDetailRow('End Date', _formatDate(permit.endDate)),
              _buildDetailRow('Cost', '\$${permit.cost.toStringAsFixed(2)}'),

              if (!permit.isExpired) ...[
                _buildDetailRow(
                  'Time Remaining',
                  _formatDuration(permit.timeRemaining),
                ),
              ],

              const SizedBox(height: 24),

              // Action Buttons
              if (permit.isExpired || permit.timeRemaining.inDays < 30) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/permits/renew/${permit.id}');
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Renew Permit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddPermitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF003E29),
        title: const Text(
          'Add New Permit',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This feature would connect to your city\'s permit system to add or renew parking permits.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Feature coming soon!'),
                  backgroundColor: Color(0xFFFFC107),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC107),
              foregroundColor: Colors.black,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  IconData _getPermitTypeIcon(PermitType type) {
    switch (type) {
      case PermitType.residential:
        return Icons.home;
      case PermitType.visitor:
        return Icons.person;
      case PermitType.business:
        return Icons.business;
      case PermitType.handicap:
        return Icons.accessible;
      case PermitType.monthly:
        return Icons.calendar_month;
      case PermitType.annual:
        return Icons.calendar_today;
      case PermitType.temporary:
        return Icons.schedule;
    }
  }

  String _getPermitTypeName(PermitType type) {
    switch (type) {
      case PermitType.residential:
        return 'Residential';
      case PermitType.visitor:
        return 'Visitor';
      case PermitType.business:
        return 'Business';
      case PermitType.handicap:
        return 'Handicap';
      case PermitType.monthly:
        return 'Monthly';
      case PermitType.annual:
        return 'Annual';
      case PermitType.temporary:
        return 'Temporary';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    }
  }
}
