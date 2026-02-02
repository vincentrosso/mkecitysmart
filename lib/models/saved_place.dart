import 'package:cloud_firestore/cloud_firestore.dart';

/// Place type for saved locations
enum PlaceType {
  home,
  work,
  favorite,
}

/// A saved place with location and metadata
/// Designed for scalability - supports future extensions like:
/// - Custom icons
/// - Notification radius
/// - Parking preferences per location
/// - Schedule-based alerts
class SavedPlace {
  final String id;
  final String userId;
  final String name;
  final String? nickname;
  final PlaceType type;
  final double latitude;
  final double longitude;
  final String? address;
  final String? geohash; // For efficient geo-queries
  final double notifyRadiusMiles; // Radius for parking alerts
  final bool notificationsEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata; // Future extensibility

  const SavedPlace({
    required this.id,
    required this.userId,
    required this.name,
    this.nickname,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.address,
    this.geohash,
    this.notifyRadiusMiles = 0.5,
    this.notificationsEnabled = true,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  /// Create from Firestore document
  factory SavedPlace.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return SavedPlace(
      id: doc.id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      nickname: data['nickname'] as String?,
      type: PlaceType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => PlaceType.favorite,
      ),
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      address: data['address'] as String?,
      geohash: data['geohash'] as String?,
      notifyRadiusMiles: (data['notifyRadiusMiles'] as num?)?.toDouble() ?? 0.5,
      notificationsEnabled: data['notificationsEnabled'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Create from JSON (for local cache)
  factory SavedPlace.fromJson(Map<String, dynamic> json) {
    return SavedPlace(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      nickname: json['nickname'] as String?,
      type: PlaceType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => PlaceType.favorite,
      ),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      geohash: json['geohash'] as String?,
      notifyRadiusMiles: (json['notifyRadiusMiles'] as num?)?.toDouble() ?? 0.5,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'nickname': nickname,
      'type': type.name,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'geohash': geohash,
      'notifyRadiusMiles': notifyRadiusMiles,
      'notificationsEnabled': notificationsEnabled,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  /// Convert to JSON (for local cache)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'nickname': nickname,
      'type': type.name,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'geohash': geohash,
      'notifyRadiusMiles': notifyRadiusMiles,
      'notificationsEnabled': notificationsEnabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  SavedPlace copyWith({
    String? name,
    String? nickname,
    PlaceType? type,
    double? latitude,
    double? longitude,
    String? address,
    String? geohash,
    double? notifyRadiusMiles,
    bool? notificationsEnabled,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return SavedPlace(
      id: id,
      userId: userId,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      type: type ?? this.type,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      geohash: geohash ?? this.geohash,
      notifyRadiusMiles: notifyRadiusMiles ?? this.notifyRadiusMiles,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Display name (nickname if set, otherwise name)
  String get displayName => nickname?.isNotEmpty == true ? nickname! : name;

  /// Get icon for place type
  static String iconForType(PlaceType type) {
    switch (type) {
      case PlaceType.home:
        return '🏠';
      case PlaceType.work:
        return '💼';
      case PlaceType.favorite:
        return '⭐';
    }
  }

  String get icon => iconForType(type);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedPlace &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
