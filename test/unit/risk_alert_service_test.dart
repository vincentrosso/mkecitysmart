import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:mkecitysmart/models/ticket.dart';
import 'package:mkecitysmart/models/user_preferences.dart';
import 'package:mkecitysmart/models/user_profile.dart';
import 'package:mkecitysmart/providers/user_provider.dart';
import 'package:mkecitysmart/services/city_ticket_stats_service.dart';
import 'package:mkecitysmart/services/location_service.dart';
import 'package:mkecitysmart/services/notification_service.dart';
import 'package:mkecitysmart/services/risk_alert_service.dart';
import 'package:mkecitysmart/services/ticket_risk_prediction_service.dart';

import 'risk_alert_service_test.mocks.dart';

@GenerateMocks([
  NotificationService,
  LocationService,
  TicketRiskPredictionService,
  CityTicketStatsService,
  UserProvider,
])
void main() {
  group('RiskAlertService', () {
    late MockNotificationService notification;
    late MockLocationService location;
    late MockTicketRiskPredictionService predictor;
    late MockCityTicketStatsService stats;
    late MockUserProvider provider;
    late DateTime now;
    late RiskAlertService service;

    setUp(() {
      notification = MockNotificationService();
      location = MockLocationService();
      predictor = MockTicketRiskPredictionService();
      stats = MockCityTicketStatsService();
      provider = MockUserProvider();
      now = DateTime(2024, 1, 1, 12);
      when(notification.showLocal(title: anyNamed('title'), body: anyNamed('body')))
          .thenAnswer((_) async {});
      when(predictor.riskMessage(any)).thenReturn('High risk');
      when(stats.lookup(
        cityId: anyNamed('cityId'),
        when: anyNamed('when'),
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
      )).thenReturn(const CityTicketStats(monthlyFactor: 0.5, hotspotDensity: 0.3));
      service = RiskAlertService.test(
        notificationService: notification,
        locationService: location,
        ticketRiskPredictionService: predictor,
        cityStatsService: stats,
        now: () => now,
      );
    });

    test('triggers high tow risk alert once within cooldown', () async {
      when(provider.towRiskIndex).thenReturn(80);
      when(provider.profile).thenReturn(null);
      when(provider.tickets).thenReturn(const []);
      when(provider.sightings).thenReturn(const []);
      when(provider.cityId).thenReturn('default');
      when(location.getCurrentPosition()).thenAnswer((_) async => null);

      service.start(provider);
      await Future.delayed(const Duration(milliseconds: 10));

      verify(notification.showLocal(
        title: argThat(contains('tow/ticket risk'), named: 'title'),
        body: anyNamed('body'),
      )).called(1);
      service.dispose();
    });

    test('sends ticket risk notification when predictor is high', () async {
      when(provider.towRiskIndex).thenReturn(10);
      when(provider.profile).thenReturn(
        UserProfile(
          id: 'u1',
          name: 'Test',
          email: 'e',
          preferences: UserPreferences.defaults().copyWith(ticketRiskAlerts: true),
          vehicles: const [],
        ),
      );
      when(provider.tickets).thenReturn([
        Ticket(
          id: 't1',
          plate: 'ABC',
          amount: 20,
          reason: 'test',
          location: 'loc',
          issuedAt: DateTime(2024),
          dueDate: DateTime(2024, 2),
        )
      ]);
      when(provider.sightings).thenReturn(const []);
      when(provider.cityId).thenReturn('default');
      when(location.getCurrentPosition()).thenAnswer((_) async => Position(
            latitude: 43.0,
            longitude: -87.0,
            timestamp: now,
            accuracy: 1,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            headingAccuracy: 0,
            altitudeAccuracy: 0,
          ));
      when(predictor.predictRiskWithCityStats(
        when: anyNamed('when'),
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
        eventLoad: anyNamed('eventLoad'),
        historicalDensity: anyNamed('historicalDensity'),
        monthlyFactor: anyNamed('monthlyFactor'),
        cityHotspotDensity: anyNamed('cityHotspotDensity'),
      )).thenReturn(0.8);

      service.start(provider);
      await Future.delayed(const Duration(milliseconds: 10));

      verify(notification.showLocal(
        title: argThat(contains('Ticket risk nearby'), named: 'title'),
        body: 'High risk',
      )).called(1);
      service.dispose();
    });
  });
}
