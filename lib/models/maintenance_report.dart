enum MaintenanceCategory {
  pothole,
  streetlight,
  signage,
  graffiti,
  trash,
  tree,
  snow,
  water,
}

class MaintenanceReport {
  const MaintenanceReport({
    required this.id,
    required this.category,
    required this.description,
    required this.location,
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.photoPath,
    this.department = 'General Services',
    this.status = 'Submitted',
  });

  final String id;
  final MaintenanceCategory category;
  final String description;
  final String location;
  final double? latitude;
  final double? longitude;
  final String? photoPath;
  final String department;
  final String status;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category.name,
    'description': description,
    'location': location,
    'latitude': latitude,
    'longitude': longitude,
    'photoPath': photoPath,
    'department': department,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
  };

  factory MaintenanceReport.fromJson(Map<String, dynamic> json) {
    final categoryName =
        json['category'] as String? ?? MaintenanceCategory.pothole.name;
    return MaintenanceReport(
      id: json['id'] as String? ?? '',
      category: MaintenanceCategory.values.firstWhere(
        (value) => value.name == categoryName,
        orElse: () => MaintenanceCategory.pothole,
      ),
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      photoPath: json['photoPath'] as String?,
      department: json['department'] as String? ?? 'General Services',
      status: json['status'] as String? ?? 'Submitted',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
