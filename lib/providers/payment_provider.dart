import 'package:flutter/foundation.dart';
import '../models/payment.dart';
import '../services/payment_service.dart';
import '../services/storage_service.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _paymentService = PaymentService();

  List<PaymentCard> _paymentCards = [];
  List<PaymentTransaction> _paymentHistory = [];
  PaymentCard? _defaultCard;
  bool _isLoading = false;
  String? _errorMessage;

  List<PaymentCard> get paymentCards => _paymentCards;
  List<PaymentTransaction> get paymentHistory => _paymentHistory;
  PaymentCard? get defaultCard => _defaultCard;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadPaymentCards() async {
    _setLoading(true);
    _clearError();

    try {
      _paymentCards = await _paymentService.getUserPaymentCards();
      if (_paymentCards.isNotEmpty) {
        _defaultCard = _paymentCards.firstWhere(
          (card) => card.isDefault,
          orElse: () => _paymentCards.first,
        );
      }
    } catch (e) {
      _setError('Error loading payment cards: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addPaymentCard({
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
    required String holderName,
    bool setAsDefault = false,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final card = await _paymentService.addPaymentCard(
        cardNumber: cardNumber,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        cvv: cvv,
        holderName: holderName,
        setAsDefault: setAsDefault,
      );

      _paymentCards.add(card);

      if (setAsDefault || _defaultCard == null) {
        // Update other cards to not be default
        for (var existingCard in _paymentCards) {
          if (existingCard.id != card.id) {
            final updatedCard = PaymentCard(
              id: existingCard.id,
              lastFourDigits: existingCard.lastFourDigits,
              cardType: existingCard.cardType,
              expiryMonth: existingCard.expiryMonth,
              expiryYear: existingCard.expiryYear,
              holderName: existingCard.holderName,
              isDefault: false,
            );
            final index = _paymentCards.indexWhere(
              (c) => c.id == existingCard.id,
            );
            if (index != -1) {
              _paymentCards[index] = updatedCard;
            }
          }
        }
        _defaultCard = card;
      }

      return true;
    } catch (e) {
      _setError('Error adding payment card: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deletePaymentCard(String cardId) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _paymentService.deletePaymentCard(cardId);

      if (success) {
        _paymentCards.removeWhere((card) => card.id == cardId);

        // If deleted card was default, set another as default
        if (_defaultCard?.id == cardId) {
          _defaultCard = _paymentCards.isNotEmpty ? _paymentCards.first : null;
          if (_defaultCard != null) {
            await setDefaultCard(_defaultCard!.id);
          }
        }

        return true;
      } else {
        _setError('Failed to delete payment card');
        return false;
      }
    } catch (e) {
      _setError('Error deleting payment card: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> setDefaultCard(String cardId) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedCard = await _paymentService.setDefaultCard(cardId);

      // Update all cards to remove default status
      for (int i = 0; i < _paymentCards.length; i++) {
        if (_paymentCards[i].id == cardId) {
          _paymentCards[i] = updatedCard;
          _defaultCard = updatedCard;
        } else {
          _paymentCards[i] = PaymentCard(
            id: _paymentCards[i].id,
            lastFourDigits: _paymentCards[i].lastFourDigits,
            cardType: _paymentCards[i].cardType,
            expiryMonth: _paymentCards[i].expiryMonth,
            expiryYear: _paymentCards[i].expiryYear,
            holderName: _paymentCards[i].holderName,
            isDefault: false,
          );
        }
      }

      return true;
    } catch (e) {
      _setError('Error setting default card: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<PaymentTransaction?> processParkingPayment({
    required String spotId,
    required String reservationId,
    required double hourlyRate,
    required int durationMinutes,
    required PaymentMethod paymentMethod,
    required DateTime startTime,
    required DateTime endTime,
    PaymentCard? card,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final payment = await _paymentService.processParkingPayment(
        spotId: spotId,
        reservationId: reservationId,
        hourlyRate: hourlyRate,
        durationMinutes: durationMinutes,
        paymentMethod: paymentMethod,
        startTime: startTime,
        endTime: endTime,
        card: card ?? _defaultCard,
      );

      // Add to payment history
      final transaction = PaymentTransaction(
        id: payment.id,
        amount: payment.totalAmount,
        paymentMethod: payment.paymentMethod,
        status: payment.status,
        type: TransactionType.parking,
        createdAt: payment.createdAt,
        completedAt: payment.status == PaymentStatus.completed
            ? payment.createdAt
            : null,
        description: 'Parking payment for ${payment.formattedDuration}',
        referenceId: payment.spotId,
        card: payment.card,
      );

      _paymentHistory.insert(0, transaction);

      return transaction;
    } catch (e) {
      _setError('Error processing parking payment: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<PaymentTransaction?> processPermitRenewal({
    required String permitId,
    required double amount,
    PaymentMethod? paymentMethod,
    PaymentCard? card,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final transaction = await _paymentService.processPermitRenewal(
        permitId: permitId,
        amount: amount,
        paymentMethod: paymentMethod ?? PaymentMethod.creditCard,
        card: card ?? _defaultCard,
      );

      _paymentHistory.insert(0, transaction);

      return transaction;
    } catch (e) {
      _setError('Error processing permit renewal: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadPaymentHistory() async {
    _setLoading(true);
    _clearError();

    try {
      _paymentHistory = await _paymentService.getPaymentHistory();
    } catch (e) {
      _setError('Error loading payment history: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<PaymentTransaction?> getTransactionDetails(
    String transactionId,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      return await _paymentService.getTransactionDetails(transactionId);
    } catch (e) {
      _setError('Error loading transaction details: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> requestRefund(String transactionId, String reason) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _paymentService.requestRefund(
        transactionId,
        reason,
      );

      if (success) {
        // Update transaction status in history
        final index = _paymentHistory.indexWhere((t) => t.id == transactionId);
        if (index != -1) {
          final originalTransaction = _paymentHistory[index];
          _paymentHistory[index] = PaymentTransaction(
            id: originalTransaction.id,
            amount: originalTransaction.amount,
            paymentMethod: originalTransaction.paymentMethod,
            status: PaymentStatus.refunded,
            type: originalTransaction.type,
            createdAt: originalTransaction.createdAt,
            completedAt: DateTime.now(),
            description: originalTransaction.description,
            referenceId: originalTransaction.referenceId,
            card: originalTransaction.card,
          );

          // Add refund transaction
          final refundTransaction = PaymentTransaction(
            id: 'REF_${originalTransaction.id}',
            amount: originalTransaction.amount,
            paymentMethod: originalTransaction.paymentMethod,
            status: PaymentStatus.completed,
            type: TransactionType.refund,
            createdAt: DateTime.now(),
            completedAt: DateTime.now(),
            description: 'Refund for ${originalTransaction.description}',
            referenceId: originalTransaction.referenceId,
            card: originalTransaction.card,
          );

          _paymentHistory.insert(0, refundTransaction);
        }
      }

      return success;
    } catch (e) {
      _setError('Error requesting refund: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Calculate payment breakdown for UI
  Map<String, double> calculateParkingPayment({
    required double hourlyRate,
    required int durationMinutes,
    PaymentMethod paymentMethod = PaymentMethod.creditCard,
  }) {
    final hours = durationMinutes / 60.0;
    final subtotal = hourlyRate * hours;
    final tax = subtotal * 0.08; // 8% tax
    final processingFee = paymentMethod == PaymentMethod.creditCard
        ? 0.30
        : 0.0;
    final total = subtotal + tax + processingFee;

    return {
      'subtotal': double.parse(subtotal.toStringAsFixed(2)),
      'tax': double.parse(tax.toStringAsFixed(2)),
      'processingFee': double.parse(processingFee.toStringAsFixed(2)),
      'total': double.parse(total.toStringAsFixed(2)),
    };
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}
