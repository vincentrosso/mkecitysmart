/// Represents a food resource location (pantry, grocery, farmers market).
class FoodLocation {
  const FoodLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.phone,
    this.hours,
    this.website,
    this.serviceAreaZips,
  });

  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final FoodLocationType type;
  final String? phone;
  final String? hours;
  final String? website;
  final String? serviceAreaZips;

  String get typeLabel {
    switch (type) {
      case FoodLocationType.pantry:
        return 'Food Pantry';
      case FoodLocationType.grocery:
        return 'Grocery Store';
      case FoodLocationType.farmersMarket:
        return 'Farmers Market';
    }
  }

  String get typeEmoji {
    switch (type) {
      case FoodLocationType.pantry:
        return '🏠';
      case FoodLocationType.grocery:
        return '🛒';
      case FoodLocationType.farmersMarket:
        return '🥕';
    }
  }
}

enum FoodLocationType { pantry, grocery, farmersMarket }
