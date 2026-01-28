import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mkeparkapp_flutter/services/open_charge_map_service.dart';

void main() {
  group('OpenChargeMapService', () {
    test('parses stations and availability', () async {
      final mockClient = MockClient((request) async {
        final payload = [
          {
            'ID': 1,
            'AddressInfo': {
              'Title': 'Main St Charger',
              'AddressLine1': '123 Main St',
              'Town': 'Milwaukee',
              'StateOrProvince': 'WI',
              'Latitude': 43.0,
              'Longitude': -87.9,
            },
            'OperatorInfo': {'Title': 'ChargeCo'},
            'StatusType': {'Title': 'Operational'},
            'UsageCost': '\$0.20 per kWh',
            'Connections': [
              {
                'ConnectionType': {'Title': 'CCS'},
                'PowerKW': 50,
              },
              {
                'ConnectionType': {'Title': 'CHAdeMO'},
                'PowerKW': 100,
              },
            ],
          },
          {
            'ID': 2,
            'AddressInfo': {'Title': 'Unknown Addr'},
            'StatusType': {'Title': 'Out of service'},
            'Connections': [],
          }
        ];
        return http.Response(jsonEncode(payload), 200);
      });

      final service = OpenChargeMapService(client: mockClient);
      final stations = await service.fetchStations(
        lat: 43.0,
        lng: -87.9,
        distanceKm: 5,
        maxResults: 5,
      );

      expect(stations, hasLength(2));
      final first = stations.first;
      expect(first.name, 'Main St Charger');
      expect(first.connectorTypes, contains('CCS'));
      expect(first.maxPowerKw, 100);
      expect(first.availablePorts, greaterThan(0));
      expect(first.hasAvailability, isTrue);
      expect(first.hasFastCharging, isTrue);
      expect(first.pricePerKwh, closeTo(0.20, 0.001));

      final second = stations[1];
      expect(second.availablePorts, 0);
      expect(second.address, 'Address unavailable');
    });

    test('throws on non-200', () async {
      final service = OpenChargeMapService(
        client: MockClient((_) async => http.Response('nope', 500)),
      );

      await expectLater(
        () => service.fetchStations(lat: 0, lng: 0),
        throwsA(isA<Exception>()),
      );
    });
  });
}
