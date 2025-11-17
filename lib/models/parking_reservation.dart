enum ReservationStatus { pending, confirmed, active, completed, cancelled }

class ParkingReservation {
  final String id;
  final String userId;
  final String spotId;
  final String vehicleId;
  final DateTime startTime;
  final DateTime endTime;
  final ReservationStatus status;
  final double cost;
  final DateTime createdAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final String? qrCode;

  ParkingReservation({
    required this.id,
    required this.userId,
    required this.spotId,
    required this.vehicleId,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.cost,
    required this.createdAt,
    this.cancelledAt,
    this.cancellationReason,
    this.qrCode,
  });

  factory ParkingReservation.fromJson(Map<String, dynamic> json) {
    return ParkingReservation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      spotId: json['spot_id'] as String,
      vehicleId: json['vehicle_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      status: ReservationStatus.values.firstWhere(
        (e) => e.toString() == 'ReservationStatus.${json['status']}',
        orElse: () => ReservationStatus.pending,
      ),
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at'] as String),
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      cancellationReason: json['cancellation_reason'] as String?,
      qrCode: json['qr_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'spot_id': spotId,
      'vehicle_id': vehicleId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'status': status.toString().split('.').last,
      'cost': cost,
      'created_at': createdAt.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'cancellation_reason': cancellationReason,
      'qr_code': qrCode,
    };
  }

  Duration get duration => endTime.difference(startTime);

  bool get isActive {
    final now = DateTime.now();
    return status == ReservationStatus.active &&
        now.isAfter(startTime) &&
        now.isBefore(endTime);
  }

  bool get isUpcoming {
    final now = DateTime.now();
    return (status == ReservationStatus.confirmed ||
            status == ReservationStatus.pending) &&
        startTime.isAfter(now);
  }

  bool get isPast {
    return status == ReservationStatus.completed ||
        endTime.isBefore(DateTime.now());
  }

  String get statusDisplayText {
    switch (status) {
      case ReservationStatus.pending:
        return 'Pending';
      case ReservationStatus.confirmed:
        return 'Confirmed';
      case ReservationStatus.active:
        return 'Active';
      case ReservationStatus.completed:
        return 'Completed';
      case ReservationStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get formattedCost {
    return '\$${cost.toStringAsFixed(2)}';
  }

  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    } else {
      return '${minutes}m';
    }
  }
}
