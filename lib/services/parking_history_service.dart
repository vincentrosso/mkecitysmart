import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/parking_event.dart';
import '../models/subscription_plan.dart';

/// Service for logging and retrieving parking history events
class ParkingHistoryService {
  ParkingHistoryService._();
  static final ParkingHistoryService instance = ParkingHistoryService._();

  static const _storageKey = 'parking_history_events';
  static const _maxEventsStored = 500; // Keep last 500 events in storage

  List<ParkingEvent> _events = [];
  bool _initialized = false;

  /// Initialize the service and load events from storage
  Future<void> initialize() async {
    if (_initialized) return;
    await _loadFromStorage();
    _initialized = true;
  }

  /// Get all events (optionally filtered by days based on subscription)
  List<ParkingEvent> getEvents({
    int? limitDays,
    ParkingEventType? filterType,
    bool unreadOnly = false,
  }) {
    var events = List<ParkingEvent>.from(_events);

    // Filter by days if specified
    if (limitDays != null) {
      final cutoff = DateTime.now().subtract(Duration(days: limitDays));
      events = events.where((e) => e.timestamp.isAfter(cutoff)).toList();
    }

    // Filter by type if specified
    if (filterType != null) {
      events = events.where((e) => e.type == filterType).toList();
    }

    // Filter by read status if specified
    if (unreadOnly) {
      events = events.where((e) => !e.read).toList();
    }

    // Sort by timestamp descending (newest first)
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return events;
  }

  /// Get events for a subscription tier (respects history days limit)
  List<ParkingEvent> getEventsForTier(SubscriptionTier tier) {
    final historyDays = _getHistoryDaysForTier(tier);
    return getEvents(limitDays: historyDays);
  }

  int _getHistoryDaysForTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 7;
      case SubscriptionTier.pro:
        return 365;
    }
  }

  /// Get count of unread events
  int get unreadCount => _events.where((e) => !e.read).length;

  /// Get recent urgent events (last 24 hours)
  List<ParkingEvent> getRecentUrgentEvents() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    return _events
        .where((e) => e.type.isUrgent && e.timestamp.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Log a new parking event
  Future<ParkingEvent> logEvent({
    required ParkingEventType type,
    required String title,
    required String description,
    String? location,
    double? latitude,
    double? longitude,
    String? vehicleId,
    Map<String, dynamic> metadata = const {},
  }) async {
    final event = ParkingEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      title: title,
      description: description,
      timestamp: DateTime.now(),
      location: location,
      latitude: latitude,
      longitude: longitude,
      vehicleId: vehicleId,
      metadata: metadata,
      read: false,
    );

    _events.insert(0, event); // Add to front of list

    // Trim old events if we have too many
    if (_events.length > _maxEventsStored) {
      _events = _events.sublist(0, _maxEventsStored);
    }

    await _saveToStorage();
    debugPrint(
      '[ParkingHistory] Logged event: ${event.type.name} - ${event.title}',
    );

    return event;
  }

  /// Log a street sweeping alert
  Future<ParkingEvent> logStreetSweepingAlert({
    required String streetName,
    required DateTime sweepingTime,
    String? location,
  }) {
    return logEvent(
      type: ParkingEventType.streetSweepingAlert,
      title: 'Street Sweeping Alert',
      description: 'Street sweeping scheduled for $streetName',
      location: location,
      metadata: {
        'streetName': streetName,
        'sweepingTime': sweepingTime.toIso8601String(),
      },
    );
  }

  /// Log an alternate side parking reminder
  Future<ParkingEvent> logAlternateSideReminder({
    required bool isOddDay,
    required String side,
    required String addressExamples,
  }) {
    return logEvent(
      type: ParkingEventType.alternateSideReminder,
      title: 'Alternate Side Parking',
      description:
          'Park on the $side side today (${isOddDay ? "Odd" : "Even"} day addresses: $addressExamples)',
      metadata: {
        'isOddDay': isOddDay,
        'side': side,
        'addressExamples': addressExamples,
      },
    );
  }

  /// Log an enforcement/tow sighting alert
  Future<ParkingEvent> logEnforcementAlert({
    required bool isTowTruck,
    required String description,
    String? location,
    double? latitude,
    double? longitude,
  }) {
    return logEvent(
      type: isTowTruck
          ? ParkingEventType.towTruckSpotted
          : ParkingEventType.enforcementSpotted,
      title: isTowTruck ? 'Tow Truck Alert' : 'Enforcement Alert',
      description: description,
      location: location,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Log a citation risk alert
  Future<ParkingEvent> logCitationRiskAlert({
    required String riskLevel,
    required String reason,
    String? location,
    double? latitude,
    double? longitude,
  }) {
    return logEvent(
      type: ParkingEventType.citationRiskAlert,
      title: 'Citation Risk: $riskLevel',
      description: reason,
      location: location,
      latitude: latitude,
      longitude: longitude,
      metadata: {'riskLevel': riskLevel},
    );
  }

  /// Log a permit renewal
  Future<ParkingEvent> logPermitRenewal({
    required String permitType,
    required DateTime expirationDate,
    String? vehicleId,
  }) {
    return logEvent(
      type: ParkingEventType.permitRenewed,
      title: 'Permit Renewed',
      description:
          '$permitType renewed. Valid until ${_formatDate(expirationDate)}',
      vehicleId: vehicleId,
      metadata: {
        'permitType': permitType,
        'expirationDate': expirationDate.toIso8601String(),
      },
    );
  }

  /// Log a permit expiring warning
  Future<ParkingEvent> logPermitExpiring({
    required String permitType,
    required DateTime expirationDate,
    required int daysRemaining,
    String? vehicleId,
  }) {
    return logEvent(
      type: ParkingEventType.permitExpiring,
      title: 'Permit Expiring Soon',
      description:
          '$permitType expires in $daysRemaining day${daysRemaining == 1 ? "" : "s"} (${_formatDate(expirationDate)})',
      vehicleId: vehicleId,
      metadata: {
        'permitType': permitType,
        'expirationDate': expirationDate.toIso8601String(),
        'daysRemaining': daysRemaining,
      },
    );
  }

  /// Log a user-reported sighting
  Future<ParkingEvent> logSightingReported({
    required String sightingType,
    required String location,
    double? latitude,
    double? longitude,
    String? notes,
  }) {
    return logEvent(
      type: ParkingEventType.sightingReported,
      title: 'You Reported: $sightingType',
      description: 'Sighting at $location${notes != null ? ". $notes" : ""}',
      location: location,
      latitude: latitude,
      longitude: longitude,
      metadata: {
        'sightingType': sightingType,
        if (notes != null) 'notes': notes,
      },
    );
  }

  /// Log a parking session start
  Future<ParkingEvent> logParkingStarted({
    required String location,
    double? latitude,
    double? longitude,
    String? vehicleId,
    Duration? estimatedDuration,
  }) {
    return logEvent(
      type: ParkingEventType.parkingStarted,
      title: 'Parking Started',
      description:
          'Parked at $location${estimatedDuration != null ? " for ~${estimatedDuration.inMinutes} min" : ""}',
      location: location,
      latitude: latitude,
      longitude: longitude,
      vehicleId: vehicleId,
      metadata: {
        if (estimatedDuration != null)
          'estimatedMinutes': estimatedDuration.inMinutes,
      },
    );
  }

  /// Log a parking session end
  Future<ParkingEvent> logParkingEnded({
    required String location,
    double? latitude,
    double? longitude,
    String? vehicleId,
    Duration? totalDuration,
  }) {
    return logEvent(
      type: ParkingEventType.parkingEnded,
      title: 'Parking Ended',
      description:
          'Left $location${totalDuration != null ? " after ${_formatDuration(totalDuration)}" : ""}',
      location: location,
      latitude: latitude,
      longitude: longitude,
      vehicleId: vehicleId,
      metadata: {
        if (totalDuration != null) 'totalMinutes': totalDuration.inMinutes,
      },
    );
  }

  /// Log a meter expiring warning
  Future<ParkingEvent> logMeterExpiring({
    required int minutesRemaining,
    String? location,
    double? latitude,
    double? longitude,
  }) {
    return logEvent(
      type: ParkingEventType.meterExpiring,
      title: 'Meter Expiring Soon',
      description:
          'Your meter expires in $minutesRemaining minute${minutesRemaining == 1 ? "" : "s"}',
      location: location,
      latitude: latitude,
      longitude: longitude,
      metadata: {'minutesRemaining': minutesRemaining},
    );
  }

  /// Log a garbage/recycling reminder
  Future<ParkingEvent> logGarbageReminder({
    required String collectionType,
    required DateTime collectionDate,
  }) {
    return logEvent(
      type: ParkingEventType.garbageReminder,
      title: '$collectionType Collection',
      description: '$collectionType pickup on ${_formatDate(collectionDate)}',
      metadata: {
        'collectionType': collectionType,
        'collectionDate': collectionDate.toIso8601String(),
      },
    );
  }

  /// Log a move vehicle reminder
  Future<ParkingEvent> logMoveVehicleReminder({
    required String reason,
    String? location,
    String? vehicleId,
  }) {
    return logEvent(
      type: ParkingEventType.moveVehicleReminder,
      title: 'Move Your Vehicle',
      description: reason,
      location: location,
      vehicleId: vehicleId,
    );
  }

  /// Mark an event as read
  Future<void> markAsRead(String eventId) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      _events[index] = _events[index].copyWith(read: true);
      await _saveToStorage();
    }
  }

  /// Mark all events as read
  Future<void> markAllAsRead() async {
    _events = _events.map((e) => e.copyWith(read: true)).toList();
    await _saveToStorage();
  }

  /// Delete an event
  Future<void> deleteEvent(String eventId) async {
    _events.removeWhere((e) => e.id == eventId);
    await _saveToStorage();
  }

  /// Clear all events
  Future<void> clearAll() async {
    _events.clear();
    await _saveToStorage();
  }

  /// Get statistics for a time period
  Map<String, dynamic> getStatistics({int days = 30}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final recentEvents = _events
        .where((e) => e.timestamp.isAfter(cutoff))
        .toList();

    final typeCount = <ParkingEventType, int>{};
    for (final event in recentEvents) {
      typeCount[event.type] = (typeCount[event.type] ?? 0) + 1;
    }

    return {
      'totalEvents': recentEvents.length,
      'urgentEvents': recentEvents.where((e) => e.type.isUrgent).length,
      'eventsByType': typeCount.map((k, v) => MapEntry(k.name, v)),
      'periodDays': days,
    };
  }

  // Private methods

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        _events = jsonList
            .map((item) => ParkingEvent.fromJson(item as Map<String, dynamic>))
            .toList();
        debugPrint(
          '[ParkingHistory] Loaded ${_events.length} events from storage',
        );
      }
    } catch (e) {
      debugPrint('[ParkingHistory] Error loading events: $e');
      _events = [];
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _events.map((e) => e.toJson()).toList();
      await prefs.setString(_storageKey, json.encode(jsonList));
    } catch (e) {
      debugPrint('[ParkingHistory] Error saving events: $e');
    }
  }

  String _formatDate(DateTime date) {
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return '${hours}h ${minutes}m';
    }
    return '${duration.inMinutes}m';
  }
}
