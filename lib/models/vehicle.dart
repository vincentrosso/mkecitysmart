class Vehicle {
  const Vehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.licensePlate,
    required this.color,
    required this.nickname,
  });

  final String id;
  final String make;
  final String model;
  final String licensePlate;
  final String color;
  final String nickname;

  Vehicle copyWith({
    String? make,
    String? model,
    String? licensePlate,
    String? color,
    String? nickname,
  }) {
    return Vehicle(
      id: id,
      make: make ?? this.make,
      model: model ?? this.model,
      licensePlate: licensePlate ?? this.licensePlate,
      color: color ?? this.color,
      nickname: nickname ?? this.nickname,
    );
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      make: json['make'] as String? ?? '',
      model: json['model'] as String? ?? '',
      licensePlate: json['licensePlate'] as String? ?? '',
      color: json['color'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'make': make,
    'model': model,
    'licensePlate': licensePlate,
    'color': color,
    'nickname': nickname,
  };
}
