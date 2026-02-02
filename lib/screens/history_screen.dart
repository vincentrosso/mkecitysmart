import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/parking_event.dart';
import '../models/subscription_plan.dart';
import '../providers/user_provider.dart';
import '../services/parking_history_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  ParkingEventType? _filterType;
  bool _isLoading = true;
  List<ParkingEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    await ParkingHistoryService.instance.initialize();
    _refreshEvents();
  }

  void _refreshEvents() {
    final userProvider = context.read<UserProvider>();
    final tier = userProvider.tier;

    setState(() {
      _events = ParkingHistoryService.instance.getEventsForTier(tier);
      if (_filterType != null) {
        _events = _events.where((e) => e.type == _filterType).toList();
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final tier = userProvider.tier;
    final historyDays = _getHistoryDaysLabel(tier);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF203731),
        title: const Text('Parking History'),
        actions: [
          PopupMenuButton<ParkingEventType?>(
            icon: Icon(
              _filterType != null
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
              color: Colors.white,
            ),
            tooltip: 'Filter by type',
            onSelected: (type) {
              setState(() {
                _filterType = type;
              });
              _refreshEvents();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Row(
                  children: [
                    Icon(Icons.clear_all, size: 20),
                    SizedBox(width: 8),
                    Text('All Events'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              ...ParkingEventType.values.map(
                (type) => PopupMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(
                        _getEventIcon(type),
                        size: 20,
                        color: _getEventColor(type),
                      ),
                      const SizedBox(width: 8),
                      Text(type.displayName),
                    ],
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              setState(() => _isLoading = true);
              _refreshEvents();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // History limit banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF203731).withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.history, size: 18, color: Color(0xFF203731)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Showing $historyDays of history',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF203731),
                    ),
                  ),
                ),
                if (tier.index < 2)
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/subscription'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Upgrade',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Filter chip if active
          if (_filterType != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Chip(
                    avatar: Icon(_getEventIcon(_filterType!), size: 18),
                    label: Text(_filterType!.displayName),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() => _filterType = null);
                      _refreshEvents();
                    },
                  ),
                ],
              ),
            ),

          // Events list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _events.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: () async {
                      _refreshEvents();
                    },
                    child: ListView.builder(
                      itemCount: _events.length,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemBuilder: (context, index) {
                        return _buildEventTile(_events[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _filterType != null ? Icons.filter_alt_off : Icons.history,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _filterType != null
                  ? 'No ${_filterType!.displayName.toLowerCase()} events'
                  : 'No parking history yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _filterType != null
                  ? 'Try a different filter or wait for events'
                  : 'Events will appear here as you use the app',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            if (_filterType != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  setState(() => _filterType = null);
                  _refreshEvents();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Filter'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEventTile(ParkingEvent event) {
    final isUrgent = event.type.isUrgent;

    return Dismissible(
      key: Key(event.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Event'),
            content: const Text('Are you sure you want to delete this event?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        await ParkingHistoryService.instance.deleteEvent(event.id);
        _refreshEvents();
      },
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getEventColor(event.type).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getEventIcon(event.type),
            color: _getEventColor(event.type),
            size: 22,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                event.title,
                style: TextStyle(
                  fontWeight: event.read ? FontWeight.normal : FontWeight.w600,
                ),
              ),
            ),
            if (isUrgent && !event.read)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'URGENT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  _formatTimestamp(event.timestamp),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                if (event.location != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.location_on,
                    size: 12,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.location!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: !event.read
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF5E8A45),
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () async {
          if (!event.read) {
            await ParkingHistoryService.instance.markAsRead(event.id);
            _refreshEvents();
          }
          _showEventDetails(event);
        },
      ),
    );
  }

  void _showEventDetails(ParkingEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getEventColor(event.type).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getEventIcon(event.type),
                        color: _getEventColor(event.type),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            event.type.displayName,
                            style: TextStyle(
                              fontSize: 14,
                              color: _getEventColor(event.type),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(event.description, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                _buildDetailRow(
                  Icons.access_time,
                  _formatTimestamp(event.timestamp),
                ),
                if (event.location != null)
                  _buildDetailRow(Icons.location_on, event.location!),
                if (event.metadata.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Additional Details',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ...event.metadata.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_formatMetadataKey(e.key)}: ',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              e.value.toString(),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  IconData _getEventIcon(ParkingEventType type) {
    switch (type) {
      case ParkingEventType.streetSweepingAlert:
        return Icons.cleaning_services;
      case ParkingEventType.alternateSideReminder:
        return Icons.swap_horiz;
      case ParkingEventType.enforcementSpotted:
        return Icons.local_police;
      case ParkingEventType.towTruckSpotted:
        return Icons.fire_truck;
      case ParkingEventType.citationRiskAlert:
        return Icons.warning_amber;
      case ParkingEventType.permitRenewed:
        return Icons.verified;
      case ParkingEventType.permitExpiring:
        return Icons.schedule;
      case ParkingEventType.sightingReported:
        return Icons.visibility;
      case ParkingEventType.parkingStarted:
        return Icons.local_parking;
      case ParkingEventType.parkingEnded:
        return Icons.directions_car;
      case ParkingEventType.meterExpiring:
        return Icons.timer;
      case ParkingEventType.garbageReminder:
        return Icons.delete_outline;
      case ParkingEventType.moveVehicleReminder:
        return Icons.drive_eta;
      case ParkingEventType.generalNotification:
        return Icons.notifications;
    }
  }

  Color _getEventColor(ParkingEventType type) {
    switch (type) {
      case ParkingEventType.streetSweepingAlert:
        return const Color(0xFF4299E1); // Info blue
      case ParkingEventType.alternateSideReminder:
        return const Color(0xFF5E8A45); // Primary green
      case ParkingEventType.enforcementSpotted:
        return Colors.red;
      case ParkingEventType.towTruckSpotted:
        return Colors.red.shade800;
      case ParkingEventType.citationRiskAlert:
        return const Color(0xFFED8936); // Warning orange
      case ParkingEventType.permitRenewed:
        return const Color(0xFF7CA726); // Secondary green
      case ParkingEventType.permitExpiring:
        return const Color(0xFFE0B000); // Accent gold
      case ParkingEventType.sightingReported:
        return Colors.purple;
      case ParkingEventType.parkingStarted:
        return const Color(0xFF5E8A45);
      case ParkingEventType.parkingEnded:
        return Colors.grey.shade600;
      case ParkingEventType.meterExpiring:
        return const Color(0xFFED8936);
      case ParkingEventType.garbageReminder:
        return Colors.brown;
      case ParkingEventType.moveVehicleReminder:
        return const Color(0xFFED8936);
      case ParkingEventType.generalNotification:
        return const Color(0xFF4299E1);
    }
  }

  String _getHistoryDaysLabel(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return '7 days';
      case SubscriptionTier.pro:
        return '1 year';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[timestamp.month - 1]} ${timestamp.day}';
    }
  }

  String _formatMetadataKey(String key) {
    // Convert camelCase to Title Case
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1)}'
              : '',
        )
        .join(' ')
        .trim();
  }
}
