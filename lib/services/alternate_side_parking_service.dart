/// Alternate Side Parking Service
/// 
/// Determines which side of the street to park on based on odd/even day rules.
/// Many cities use this system for street cleaning and snow removal.
class AlternateSideParkingService {
  AlternateSideParkingService._();
  static final AlternateSideParkingService instance = AlternateSideParkingService._();

  /// Public factory so existing call sites that use `AlternateSideParkingService()`
  /// continue to work and receive the singleton instance.
  factory AlternateSideParkingService() => instance;

  /// Get parking instructions for a specific date
  ParkingInstructions getParkingInstructions(DateTime date) {
    final dayOfMonth = date.day;
    final isOddDay = dayOfMonth % 2 == 1;
    
    return ParkingInstructions(
      date: date,
      dayOfMonth: dayOfMonth,
      isOddDay: isOddDay,
      parkingSide: isOddDay ? ParkingSide.odd : ParkingSide.even,
      nextSwitchDate: _getNextSwitchDate(date),
    );
  }



  /// Get parking instructions for today
  ParkingInstructions getTodayInstructions() {
    return getParkingInstructions(DateTime.now());
  }

  /// Get parking instructions for tomorrow
  ParkingInstructions getTomorrowInstructions() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return getParkingInstructions(tomorrow);
  }

  /// Check if parking side will change tomorrow
  bool willSideChangeTomorrow() {
    final today = getTodayInstructions();
    final tomorrow = getTomorrowInstructions();
    return today.parkingSide != tomorrow.parkingSide;
  }

  /// Get the next date when parking side changes
  DateTime _getNextSwitchDate(DateTime currentDate) {
    // Side changes at midnight, so the next switch is tomorrow at 00:00
    final tomorrow = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day + 1,
    );
    return tomorrow;
  }

  /// Get parking instructions for the next N days
  List<ParkingInstructions> getUpcomingInstructions(int days) {
    final instructions = <ParkingInstructions>[];
    final now = DateTime.now();
    
    for (int i = 0; i < days; i++) {
      final date = now.add(Duration(days: i));
      instructions.add(getParkingInstructions(date));
    }
    
    return instructions;
  }

  /// Get a human-readable parking reminder
  String getParkingReminder({DateTime? forDate, bool includeTime = false}) {
    final instructions = forDate != null 
        ? getParkingInstructions(forDate)
        : getTodayInstructions();
    
    final side = instructions.parkingSide == ParkingSide.odd ? 'odd' : 'even';
    final dayName = _getDayName(instructions.date);
    final dateStr = _formatDate(instructions.date);
    
    if (includeTime) {
      final timeUntilSwitch = instructions.nextSwitchDate.difference(DateTime.now());
      final hours = timeUntilSwitch.inHours;
      final minutes = timeUntilSwitch.inMinutes % 60;
      
      return 'Park on the $side-numbered side today ($dayName, $dateStr). '
             'Switch in ${hours}h ${minutes}m.';
    }
    
    return 'Park on the $side-numbered side today ($dayName, ${instructions.dayOfMonth})';
  }

  /// UI-friendly status object. Kept intentionally small so callers
  /// can ask for `service.status(addressNumber: 123).sideToday`.
  AlternateSideStatus status({int? addressNumber}) {
    final instructions = getTodayInstructions();
    return AlternateSideStatus(sideToday: instructions.parkingSide);
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  /// Get day name
  String _getDayName(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  /// Check if a vehicle is parked on the correct side
  /// @param vehicleSide: The side where the vehicle is currently parked
  bool isCorrectSide(ParkingSide vehicleSide, {DateTime? forDate}) {
    final instructions = forDate != null
        ? getParkingInstructions(forDate)
        : getTodayInstructions();
    
    return vehicleSide == instructions.parkingSide;
  }

  /// Get a notification message for alternate side parking
  NotificationMessage getNotificationMessage({
    required NotificationType type,
    DateTime? forDate,
  }) {
    final instructions = forDate != null
        ? getParkingInstructions(forDate)
        : getTodayInstructions();
    
    switch (type) {
      case NotificationType.morningReminder:
        return NotificationMessage(
          title: '🅿️ Parking Reminder',
          body: 'Today is ${instructions.isOddDay ? "odd" : "even"}. '
                'Park on the ${instructions.isOddDay ? "odd" : "even"}-numbered side.',
          priority: NotificationPriority.normal,
        );
      
      case NotificationType.eveningWarning:
        final tomorrow = getTomorrowInstructions();
        return NotificationMessage(
          title: '⚠️ Parking Side Changes Tonight',
          body: 'Move your car before midnight! '
                'Tomorrow (${tomorrow.dayOfMonth}) park on the ${tomorrow.isOddDay ? "odd" : "even"} side.',
          priority: NotificationPriority.high,
        );
      
      case NotificationType.midnightAlert:
        return NotificationMessage(
          title: '🚨 Switch Parking Side Now!',
          body: 'It\'s past midnight. Park on the ${instructions.isOddDay ? "odd" : "even"}-numbered side (day ${instructions.dayOfMonth}).',
          priority: NotificationPriority.urgent,
        );
    }
  }
}

/// Parking side enum
enum ParkingSide {
  odd,   // Odd-numbered addresses (1, 3, 5, 7, etc.)
  even,  // Even-numbered addresses (2, 4, 6, 8, etc.)
}

/// Parking instructions for a specific date
class ParkingInstructions {
  final DateTime date;
  final int dayOfMonth;
  final bool isOddDay;
  final ParkingSide parkingSide;
  final DateTime nextSwitchDate;

  ParkingInstructions({
    required this.date,
    required this.dayOfMonth,
    required this.isOddDay,
    required this.parkingSide,
    required this.nextSwitchDate,
  });

  /// Get user-friendly side label
  String get sideLabel => isOddDay ? 'Odd' : 'Even';

  /// Get side number examples
  String get sideExamples => isOddDay 
      ? '1, 3, 5, 7, 9...' 
      : '2, 4, 6, 8, 10...';

  /// Get time until next switch
  Duration get timeUntilSwitch => nextSwitchDate.difference(DateTime.now());

  /// Check if switch is happening soon (within next 2 hours)
  bool get isSwitchingSoon => timeUntilSwitch.inHours < 2;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'dayOfMonth': dayOfMonth,
    'isOddDay': isOddDay,
    'parkingSide': parkingSide.name,
    'nextSwitchDate': nextSwitchDate.toIso8601String(),
  };

  /// Create from JSON
  factory ParkingInstructions.fromJson(Map<String, dynamic> json) {
    return ParkingInstructions(
      date: DateTime.parse(json['date'] as String),
      dayOfMonth: json['dayOfMonth'] as int,
      isOddDay: json['isOddDay'] as bool,
      parkingSide: ParkingSide.values.firstWhere(
        (e) => e.name == json['parkingSide'],
      ),
      nextSwitchDate: DateTime.parse(json['nextSwitchDate'] as String),
    );
  }
}

/// Notification type for alternate side parking
enum NotificationType {
  morningReminder,   // Daily morning reminder
  eveningWarning,    // Evening before switch
  midnightAlert,     // Right after midnight when side changes
}

/// Notification message
class NotificationMessage {
  final String title;
  final String body;
  final NotificationPriority priority;

  NotificationMessage({
    required this.title,
    required this.body,
    required this.priority,
  });
}

/// Minimal status object used by UI helpers that expect a
/// `status(...).sideToday` shape.
class AlternateSideStatus {
  final ParkingSide sideToday;
  AlternateSideStatus({required this.sideToday});
}

/// Notification priority
enum NotificationPriority {
  normal,
  high,
  urgent,
}
