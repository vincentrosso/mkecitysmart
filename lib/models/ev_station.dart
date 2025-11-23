class EVStation {
  const EVStation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.network,
    required this.connectorTypes,
    required this.availablePorts,
    required this.totalPorts,
    required this.maxPowerKw,
    required this.pricePerKwh,
    required this.status,
    this.notes,
  });

  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String network;
  final List<String> connectorTypes;
  final int availablePorts;
  final int totalPorts;
  final double maxPowerKw;
  final double pricePerKwh;
  final String status;
  final String? notes;

  bool get hasAvailability => availablePorts > 0;
  bool get hasFastCharging => maxPowerKw >= 50;
}
