class GarbageSchedule {
  const GarbageSchedule({
    required this.routeId,
    required this.address,
    required this.pickupDate,
    required this.type,
  });

  final String routeId;
  final String address;
  final DateTime pickupDate;
  final PickupType type;

  bool get isPast => pickupDate.isBefore(DateTime.now());
}

enum PickupType { garbage, recycling }
