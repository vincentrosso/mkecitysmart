import '../models/parking_spot.dart';
import '../models/parking_reservation.dart';
import '../utils/config.dart';
import 'api_service.dart';

class ParkingService {
  final ApiService _apiService = ApiService();

  Future<List<ParkingSpot>> searchParkingSpots({
    required double latitude,
    required double longitude,
    double radius = ApiConfig.defaultSearchRadius,
    SpotType? spotType,
    double? maxHourlyRate,
    bool availableOnly = true,
  }) async {
    if (ApiConfig.useMockData) {
      return _getMockParkingSpots(latitude, longitude, radius);
    }

    try {
      final response = await _apiService.get(
        ApiEndpoints.parkingSearch,
        queryParameters: {
          'lat': latitude,
          'lng': longitude,
          'radius': radius,
          if (spotType != null) 'type': spotType.name,
          if (maxHourlyRate != null) 'max_rate': maxHourlyRate,
          'available_only': availableOnly,
        },
      );

      final List<dynamic> data = response.data['spots'] ?? [];
      return data.map((json) => ParkingSpot.fromJson(json)).toList();
    } catch (e) {
      print('Error searching parking spots: $e');
      // Return mock data as fallback
      return _getMockParkingSpots(latitude, longitude, radius);
    }
  }

  Future<ParkingSpot?> getParkingSpotDetails(String spotId) async {
    if (ApiConfig.useMockData) {
      return _getMockParkingSpots(
        ApiConfig.milwaukeeLatitude,
        ApiConfig.milwaukeeLongitude,
        1.0,
      ).firstWhere((spot) => spot.id == spotId);
    }

    try {
      final response = await _apiService.get(
        '${ApiEndpoints.parkingSpot}/$spotId',
      );
      return ParkingSpot.fromJson(response.data);
    } catch (e) {
      print('Error getting parking spot details: $e');
      return null;
    }
  }

  Future<ParkingReservation?> reserveParkingSpot({
    required String spotId,
    required String vehicleId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    if (ApiConfig.useMockData) {
      return _createMockReservation(spotId, vehicleId, startTime, endTime);
    }

    try {
      final response = await _apiService.post(
        ApiEndpoints.parkingReserve,
        data: {
          'spot_id': spotId,
          'vehicle_id': vehicleId,
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
        },
      );

      return ParkingReservation.fromJson(response.data);
    } catch (e) {
      print('Error reserving parking spot: $e');
      return null;
    }
  }

  Future<bool> cancelReservation(String reservationId) async {
    if (ApiConfig.useMockData) {
      return true; // Mock success
    }

    try {
      await _apiService.delete('${ApiEndpoints.parkingReserve}/$reservationId');
      return true;
    } catch (e) {
      print('Error cancelling reservation: $e');
      return false;
    }
  }

  Future<List<ParkingReservation>> getUserParkingHistory() async {
    if (ApiConfig.useMockData) {
      return _getMockParkingHistory();
    }

    try {
      final response = await _apiService.get(ApiEndpoints.parkingHistory);
      final List<dynamic> data = response.data['history'] ?? [];
      return data.map((json) => ParkingReservation.fromJson(json)).toList();
    } catch (e) {
      print('Error getting parking history: $e');
      return _getMockParkingHistory();
    }
  }

  // Mock data methods for development
  List<ParkingSpot> _getMockParkingSpots(
    double lat,
    double lng,
    double radius,
  ) {
    return [
      ParkingSpot(
        id: 'spot_1',
        latitude: lat + 0.001,
        longitude: lng + 0.001,
        address: '123 Water St, Milwaukee, WI',
        type: SpotType.street,
        status: SpotStatus.available,
        hourlyRate: 2.50,
        maxDuration: 2.0,
        restrictions: ['2 hour max', 'Mon-Fri 8AM-6PM'],
        distance: 0.1,
        availableUntil: DateTime.now().add(Duration(hours: 3)),
      ),
      ParkingSpot(
        id: 'spot_2',
        latitude: lat - 0.001,
        longitude: lng - 0.001,
        address: '456 Wisconsin Ave, Milwaukee, WI',
        type: SpotType.metered,
        status: SpotStatus.available,
        hourlyRate: 1.75,
        maxDuration: 4.0,
        restrictions: ['No parking Sunday'],
        distance: 0.2,
      ),
      ParkingSpot(
        id: 'spot_3',
        latitude: lat + 0.002,
        longitude: lng - 0.002,
        address: 'Cathedral Square Parking Garage',
        type: SpotType.garage,
        status: SpotStatus.available,
        hourlyRate: 3.00,
        maxDuration: 12.0,
        restrictions: [],
        distance: 0.3,
      ),
    ];
  }

  ParkingReservation _createMockReservation(
    String spotId,
    String vehicleId,
    DateTime startTime,
    DateTime endTime,
  ) {
    return ParkingReservation(
      id: 'reservation_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'user_123',
      spotId: spotId,
      vehicleId: vehicleId,
      startTime: startTime,
      endTime: endTime,
      status: ReservationStatus.confirmed,
      cost: 5.00,
      createdAt: DateTime.now(),
    );
  }

  List<ParkingReservation> _getMockParkingHistory() {
    final now = DateTime.now();
    return [
      ParkingReservation(
        id: 'res_1',
        userId: 'user_123',
        spotId: 'spot_1',
        vehicleId: 'vehicle_1',
        startTime: now.subtract(Duration(days: 1)),
        endTime: now.subtract(Duration(days: 1, hours: -2)),
        status: ReservationStatus.completed,
        cost: 5.00,
        createdAt: now.subtract(Duration(days: 1)),
      ),
      ParkingReservation(
        id: 'res_2',
        userId: 'user_123',
        spotId: 'spot_2',
        vehicleId: 'vehicle_1',
        startTime: now.subtract(Duration(days: 3)),
        endTime: now.subtract(Duration(days: 3, hours: -1)),
        status: ReservationStatus.completed,
        cost: 1.75,
        createdAt: now.subtract(Duration(days: 3)),
      ),
    ];
  }
}
