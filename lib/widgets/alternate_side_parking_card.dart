import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/alternate_side_parking_service.dart';

/// Widget that displays alternate side parking information
class AlternateSideParkingCard extends StatelessWidget {
  final bool showUpcoming;
  final int upcomingDays;

  const AlternateSideParkingCard({
    super.key,
    this.showUpcoming = true,
    this.upcomingDays = 7,
  });

  @override
  Widget build(BuildContext context) {
    final service = AlternateSideParkingService.instance;
    final today = service.getTodayInstructions();
    final tomorrow = service.getTomorrowInstructions();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.swap_horiz,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alternate Side Parking',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Odd/Even Day Rules',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Today's Instructions
            _buildDayCard(
              context: context,
              label: 'TODAY',
              date: today.date,
              instructions: today,
              isToday: true,
            ),
            
            const SizedBox(height: 12),

            // Tomorrow's Instructions
            _buildDayCard(
              context: context,
              label: 'TOMORROW',
              date: tomorrow.date,
              instructions: tomorrow,
              isToday: false,
            ),

            // Switch Warning
            if (today.isSwitchingSoon) ...[
              const SizedBox(height: 16),
              _buildSwitchWarning(context, today),
            ],

            // Upcoming Days
            if (showUpcoming) ...[
              const SizedBox(height: 24),
              Text(
                'UPCOMING DAYS',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.grey[600],
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              _buildUpcomingDays(context, service),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard({
    required BuildContext context,
    required String label,
    required DateTime date,
    required ParkingInstructions instructions,
    required bool isToday,
  }) {
    final color = isToday 
        ? Theme.of(context).primaryColor 
        : Colors.grey[700]!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isToday 
            ? Theme.of(context).primaryColor.withOpacity(0.08)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday 
              ? Theme.of(context).primaryColor.withOpacity(0.3)
              : Colors.grey[200]!,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Day number circle
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: instructions.isOddDay 
                  ? const Color(0xFFE0C164)  // Theme yellow for odd
                  : const Color(0xFF4FC3F7), // Bright cyan for even
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '${instructions.dayOfMonth}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Instructions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Park on ${instructions.sideLabel} Side',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Addresses: ${instructions.sideExamples}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Icon indicator
          Icon(
            instructions.isOddDay ? Icons.looks_one : Icons.looks_two,
            color: instructions.isOddDay 
                ? const Color(0xFFE0C164) // Theme yellow
                : const Color(0xFF4FC3F7), // Bright cyan
            size: 32,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchWarning(BuildContext context, ParkingInstructions today) {
    final hours = today.timeUntilSwitch.inHours;
    final minutes = today.timeUntilSwitch.inMinutes % 60;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[300]!, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Side Changes Soon!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[900],
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Switch in ${hours}h ${minutes}m',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingDays(BuildContext context, AlternateSideParkingService service) {
    final upcoming = service.getUpcomingInstructions(upcomingDays);
    
    return Column(
      children: upcoming.skip(2).map((instructions) {
        final dateFormat = DateFormat('EEE, MMM d');
        final isOdd = instructions.isOddDay;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              // Date
              SizedBox(
                width: 100,
                child: Text(
                  dateFormat.format(instructions.date),
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ),
              
              // Day number badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isOdd 
                      ? const Color(0xFFE0C164).withOpacity(0.2) 
                      : const Color(0xFF4FC3F7).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isOdd 
                        ? const Color(0xFFE0C164) 
                        : const Color(0xFF4FC3F7),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${instructions.dayOfMonth}',
                    style: TextStyle(
                      color: isOdd 
                          ? const Color(0xFFE0C164) 
                          : const Color(0xFF4FC3F7),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Side label
              Expanded(
                child: Text(
                  '${instructions.sideLabel} Side',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Compact version for dashboard
class AlternateSideParkingTile extends StatelessWidget {
  const AlternateSideParkingTile({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AlternateSideParkingService.instance;
    final today = service.getTodayInstructions();
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to full alternate side parking screen
          Navigator.pushNamed(context, '/alternate-side-parking');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: today.isOddDay 
                      ? const Color(0xFFE0C164) 
                      : const Color(0xFF4FC3F7),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${today.dayOfMonth}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Park on ${today.sideLabel} Side',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Today: ${today.sideExamples}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
