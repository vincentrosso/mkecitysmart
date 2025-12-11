import 'package:flutter_test/flutter_test.dart';

import 'package:mkecitysmart/services/ticket_api_service.dart';
import 'package:mkecitysmart/data/sample_tickets.dart';

void main() {
  group('TicketApiService', () {
    final service = TicketApiService();

    test('fetchTickets returns sample tickets', () async {
      final tickets = await service.fetchTickets();
      expect(tickets, isNotEmpty);
      expect(tickets.length, sampleTickets.length);
    });

    test('syncTickets completes without error', () async {
      await expectLater(service.syncTickets(sampleTickets), completes);
    });
  });
}
