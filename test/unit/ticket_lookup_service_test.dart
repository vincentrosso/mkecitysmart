import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mkecitysmart/models/ticket.dart';
import 'package:mkecitysmart/services/ticket_lookup_service.dart';

void main() {
  group('TicketLookupService', () {
    test('lookupTickets parses list and honors headers', () async {
      late Uri calledUri;
      late Map<String, String> calledHeaders;
      final mockClient = MockClient((request) async {
        calledUri = request.url;
        calledHeaders = request.headers;
        final body = jsonEncode([
          {
            'id': 't1',
            'plate': 'ABC123',
            'amount': 42.5,
            'violation': 'Meter expired',
            'location': '123 Main',
            'issueDate': 1700000000000,
            'dueDate': '2024-03-01T12:00:00Z',
            'status': 'paid',
          },
        ]);
        return http.Response(body, 200);
      });

      final service = TicketLookupService(
        baseUrl: 'https://api.example.com',
        authToken: 'secret',
        client: mockClient,
      );

      final results = await service.lookupTickets(plate: 'ABC123', state: 'WI');

      expect(results, hasLength(1));
      final ticket = results.single;
      expect(ticket.id, 't1');
      expect(ticket.status, TicketStatus.paid);
      expect(ticket.amount, 42.5);
      expect(ticket.plate, 'ABC123');
      expect(calledUri.path, '/tickets');
      expect(calledUri.queryParameters, {'plate': 'ABC123', 'state': 'WI'});
      expect(calledHeaders['Authorization'], 'Bearer secret');
    });

    test('payTicket posts body and parses receipt', () async {
      late Map<String, dynamic> decodedBody;
      final mockClient = MockClient((request) async {
        decodedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'receiptId': 'r1',
            'status': 'paid',
            'paidAt': 'now',
            'receiptUrl': 'https://pay.example.com/r1',
          }),
          200,
        );
      });

      final service = TicketLookupService(
        baseUrl: 'https://api.example.com',
        client: mockClient,
      );

      final result = await service.payTicket(
        ticketId: 't1',
        amount: 10.0,
        paymentMethod: {'token': 'tok_123'},
        feeWaiverCode: 'WAIVE',
        email: 'user@example.com',
      );

      expect(decodedBody['amount'], 10.0);
      expect(decodedBody['payment']['token'], 'tok_123');
      expect(decodedBody['feeWaiverCode'], 'WAIVE');
      expect(decodedBody['email'], 'user@example.com');
      expect(result.receiptId, 'r1');
      expect(result.status, 'paid');
      expect(result.receiptUrl, contains('r1'));
    });

    test('lookupTickets throws on non-200', () async {
      final service = TicketLookupService(
        baseUrl: 'https://api.example.com',
        client: MockClient((_) async => http.Response('nope', 500)),
      );

      await expectLater(
        () => service.lookupTickets(plate: 'ABC', state: 'WI'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
