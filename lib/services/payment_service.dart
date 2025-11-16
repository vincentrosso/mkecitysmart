import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/payment.dart';
import '../models/parking_reservation.dart';
import '../models/permit.dart';

class PaymentService {
  static const String _baseUrl = 'https://api.citysmartparking.com/payments';

  // Mock payment processing - in production this would integrate with Stripe, PayPal, etc.
  Future<PaymentTransaction> processPayment({
    required double amount,
    required PaymentMethod paymentMethod,
    required TransactionType type,
    PaymentCard? card,
    String? description,
    String? referenceId,
  }) async {
    // Simulate API delay
    await Future.delayed(Duration(seconds: 2));

    // Simulate payment processing with 95% success rate
    final random = Random();
    final isSuccess = random.nextDouble() > 0.05;

    final transaction = PaymentTransaction(
      id: _generateTransactionId(),
      amount: amount,
      paymentMethod: paymentMethod,
      status: isSuccess ? PaymentStatus.completed : PaymentStatus.failed,
      type: type,
      createdAt: DateTime.now(),
      completedAt: isSuccess ? DateTime.now() : null,
      description: description,
      referenceId: referenceId,
      card: card,
      failureReason: isSuccess ? null : _getRandomFailureReason(),
    );

    return transaction;
  }

  Future<ParkingPayment> processParkingPayment({
    required String spotId,
    required String reservationId,
    required double hourlyRate,
    required int durationMinutes,
    required PaymentMethod paymentMethod,
    required DateTime startTime,
    required DateTime endTime,
    PaymentCard? card,
  }) async {
    // Calculate payment details
    final hours = durationMinutes / 60.0;
    final subtotal = hourlyRate * hours;
    final tax = subtotal * 0.08; // 8% tax
    final processingFee = paymentMethod == PaymentMethod.creditCard
        ? 0.30
        : 0.0;
    final totalAmount = subtotal + tax + processingFee;

    // Process the payment
    final transaction = await processPayment(
      amount: totalAmount,
      paymentMethod: paymentMethod,
      type: TransactionType.parking,
      card: card,
      description: 'Parking payment for ${hours.toStringAsFixed(1)} hours',
      referenceId: spotId,
    );

    final payment = ParkingPayment(
      id: transaction.id,
      spotId: spotId,
      reservationId: reservationId,
      hourlyRate: hourlyRate,
      durationMinutes: durationMinutes,
      totalAmount: totalAmount,
      tax: tax,
      processingFee: processingFee,
      paymentMethod: paymentMethod,
      card: card,
      startTime: startTime,
      endTime: endTime,
      status: transaction.status,
      createdAt: transaction.createdAt,
    );

    return payment;
  }

  Future<PaymentTransaction> processPermitRenewal({
    required String permitId,
    required double amount,
    required PaymentMethod paymentMethod,
    PaymentCard? card,
  }) async {
    return await processPayment(
      amount: amount,
      paymentMethod: paymentMethod,
      type: TransactionType.permit,
      card: card,
      description: 'Parking permit renewal',
      referenceId: permitId,
    );
  }

  Future<PaymentCard> addPaymentCard({
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
    required String holderName,
    bool setAsDefault = false,
  }) async {
    // Simulate API delay
    await Future.delayed(Duration(seconds: 1));

    // Validate card (mock validation)
    if (!_isValidCard(cardNumber)) {
      throw Exception('Invalid card number');
    }

    final card = PaymentCard(
      id: _generateCardId(),
      lastFourDigits: cardNumber.substring(cardNumber.length - 4),
      cardType: _getCardType(cardNumber),
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
      holderName: holderName,
      isDefault: setAsDefault,
    );

    return card;
  }

  Future<List<PaymentCard>> getUserPaymentCards() async {
    // Simulate API delay
    await Future.delayed(Duration(seconds: 1));

    // Return mock cards for development
    return [
      PaymentCard(
        id: 'card_1',
        lastFourDigits: '4242',
        cardType: 'visa',
        expiryMonth: '12',
        expiryYear: '25',
        holderName: 'John Doe',
        isDefault: true,
      ),
      PaymentCard(
        id: 'card_2',
        lastFourDigits: '5555',
        cardType: 'mastercard',
        expiryMonth: '08',
        expiryYear: '26',
        holderName: 'John Doe',
        isDefault: false,
      ),
    ];
  }

  Future<bool> deletePaymentCard(String cardId) async {
    // Simulate API delay
    await Future.delayed(Duration(seconds: 1));

    // Mock deletion - always succeeds in development
    return true;
  }

  Future<PaymentCard> setDefaultCard(String cardId) async {
    // Simulate API delay
    await Future.delayed(Duration(seconds: 1));

    // Return updated card
    return PaymentCard(
      id: cardId,
      lastFourDigits: '4242',
      cardType: 'visa',
      expiryMonth: '12',
      expiryYear: '25',
      holderName: 'John Doe',
      isDefault: true,
    );
  }

  Future<List<PaymentTransaction>> getPaymentHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    // Simulate API delay
    await Future.delayed(Duration(seconds: 1));

    // Return mock transaction history
    return _generateMockTransactions(limit);
  }

  Future<PaymentTransaction> getTransactionDetails(String transactionId) async {
    // Simulate API delay
    await Future.delayed(Duration(seconds: 1));

    // Return mock transaction
    return PaymentTransaction(
      id: transactionId,
      amount: 15.50,
      paymentMethod: PaymentMethod.creditCard,
      status: PaymentStatus.completed,
      type: TransactionType.parking,
      createdAt: DateTime.now().subtract(Duration(hours: 2)),
      completedAt: DateTime.now().subtract(Duration(hours: 2, minutes: 30)),
      description: 'Parking payment for 2.5 hours',
      referenceId: 'spot_123',
      card: PaymentCard(
        id: 'card_1',
        lastFourDigits: '4242',
        cardType: 'visa',
        expiryMonth: '12',
        expiryYear: '25',
        holderName: 'John Doe',
        isDefault: true,
      ),
    );
  }

  Future<bool> requestRefund(String transactionId, String reason) async {
    // Simulate API delay
    await Future.delayed(Duration(seconds: 2));

    // Mock refund processing - 90% success rate
    final random = Random();
    return random.nextDouble() > 0.1;
  }

  // Utility methods
  String _generateTransactionId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return 'TXN_${List.generate(8, (index) => chars[random.nextInt(chars.length)]).join()}';
  }

  String _generateCardId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return 'card_${List.generate(8, (index) => chars[random.nextInt(chars.length)]).join()}';
  }

  bool _isValidCard(String cardNumber) {
    // Basic Luhn algorithm check
    final cleanNumber = cardNumber.replaceAll(' ', '');
    if (cleanNumber.length < 13 || cleanNumber.length > 19) {
      return false;
    }

    int sum = 0;
    bool alternate = false;

    for (int i = cleanNumber.length - 1; i >= 0; i--) {
      int n = int.parse(cleanNumber[i]);

      if (alternate) {
        n *= 2;
        if (n > 9) {
          n = (n % 10) + 1;
        }
      }

      sum += n;
      alternate = !alternate;
    }

    return (sum % 10 == 0);
  }

  String _getCardType(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(' ', '');

    if (cleanNumber.startsWith('4')) {
      return 'visa';
    } else if (cleanNumber.startsWith(RegExp(r'5[1-5]'))) {
      return 'mastercard';
    } else if (cleanNumber.startsWith(RegExp(r'3[47]'))) {
      return 'amex';
    } else if (cleanNumber.startsWith('6')) {
      return 'discover';
    } else {
      return 'unknown';
    }
  }

  String _getRandomFailureReason() {
    final reasons = [
      'Insufficient funds',
      'Card declined',
      'Expired card',
      'Invalid CVV',
      'Processing error',
      'Bank rejection',
    ];

    final random = Random();
    return reasons[random.nextInt(reasons.length)];
  }

  List<PaymentTransaction> _generateMockTransactions(int count) {
    final transactions = <PaymentTransaction>[];
    final random = Random();

    for (int i = 0; i < count; i++) {
      final daysAgo = random.nextInt(30);
      final amount = 5.0 + (random.nextDouble() * 50.0);
      final type =
          TransactionType.values[random.nextInt(TransactionType.values.length)];

      transactions.add(
        PaymentTransaction(
          id: _generateTransactionId(),
          amount: double.parse(amount.toStringAsFixed(2)),
          paymentMethod: PaymentMethod.creditCard,
          status: PaymentStatus.completed,
          type: type,
          createdAt: DateTime.now().subtract(Duration(days: daysAgo)),
          completedAt: DateTime.now().subtract(Duration(days: daysAgo)),
          description: _getDescriptionForType(type),
          referenceId: 'ref_${random.nextInt(1000)}',
        ),
      );
    }

    return transactions;
  }

  String _getDescriptionForType(TransactionType type) {
    switch (type) {
      case TransactionType.parking:
        return 'Parking payment for ${(1 + Random().nextDouble() * 4).toStringAsFixed(1)} hours';
      case TransactionType.permit:
        return 'Monthly parking permit';
      case TransactionType.fine:
        return 'Parking violation fine';
      case TransactionType.refund:
        return 'Refund for cancelled reservation';
    }
  }
}
