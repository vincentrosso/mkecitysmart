import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/payment_provider.dart';
import '../models/payment.dart';
import '../citysmart/theme.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentProvider>().loadPaymentCards();
      context.read<PaymentProvider>().loadPaymentHistory();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CitySmartTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Payment & Billing',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: CitySmartTheme.primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: CitySmartTheme.secondaryYellow,
          tabs: const [
            Tab(icon: Icon(Icons.credit_card), text: 'Payment Methods'),
            Tab(icon: Icon(Icons.history), text: 'Transaction History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_PaymentMethodsTab(), _TransactionHistoryTab()],
      ),
    );
  }
}

class _PaymentMethodsTab extends StatelessWidget {
  const _PaymentMethodsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, child) {
        if (paymentProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: CitySmartTheme.primaryGreen,
            ),
          );
        }

        if (paymentProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  paymentProvider.errorMessage!,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => paymentProvider.loadPaymentCards(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CitySmartTheme.primaryGreen,
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: paymentProvider.paymentCards.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.credit_card,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No payment methods',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add a credit card or debit card to get started',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[500]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: paymentProvider.paymentCards.length,
                      itemBuilder: (context, index) {
                        final card = paymentProvider.paymentCards[index];
                        return _PaymentCardWidget(card: card);
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddCardDialog(context),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Add Payment Method',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CitySmartTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddCardDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const _AddCardDialog());
  }
}

class _PaymentCardWidget extends StatelessWidget {
  final PaymentCard card;

  const _PaymentCardWidget({required this.card});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: card.isDefault
              ? CitySmartTheme.primaryGreen
              : Colors.grey.shade300,
          width: card.isDefault ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getCardColor(card.cardType),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    card.cardType.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                if (card.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: CitySmartTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'DEFAULT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'default') {
                      context.read<PaymentProvider>().setDefaultCard(card.id);
                    } else if (value == 'delete') {
                      _showDeleteCardDialog(context, card);
                    }
                  },
                  itemBuilder: (context) => [
                    if (!card.isDefault)
                      const PopupMenuItem(
                        value: 'default',
                        child: Row(
                          children: [
                            Icon(Icons.star, size: 20),
                            SizedBox(width: 8),
                            Text('Set as Default'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Delete Card',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              card.maskedCardNumber,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  card.holderName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const Spacer(),
                Text(
                  '${card.expiryMonth}/${card.expiryYear}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getCardColor(String cardType) {
    switch (cardType.toLowerCase()) {
      case 'visa':
        return const Color(0xFF1A1F71);
      case 'mastercard':
        return const Color(0xFFEB001B);
      case 'amex':
        return const Color(0xFF006FCF);
      case 'discover':
        return const Color(0xFFFF6000);
      default:
        return Colors.grey[600]!;
    }
  }

  void _showDeleteCardDialog(BuildContext context, PaymentCard card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Method'),
        content: Text(
          'Are you sure you want to delete the ${card.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<PaymentProvider>().deletePaymentCard(card.id);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _AddCardDialog extends StatefulWidget {
  const _AddCardDialog();

  @override
  State<_AddCardDialog> createState() => _AddCardDialogState();
}

class _AddCardDialogState extends State<_AddCardDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  bool _setAsDefault = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Payment Method'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _cardNumberController,
              decoration: const InputDecoration(
                labelText: 'Card Number',
                hintText: '1234 5678 9012 3456',
                prefixIcon: Icon(Icons.credit_card),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CardNumberInputFormatter(),
              ],
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter card number';
                }
                if (value!.replaceAll(' ', '').length < 13) {
                  return 'Please enter valid card number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryController,
                    decoration: const InputDecoration(
                      labelText: 'MM/YY',
                      hintText: '12/25',
                      prefixIcon: Icon(Icons.calendar_month),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _ExpiryDateInputFormatter(),
                    ],
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Required';
                      }
                      if (value!.length < 5) {
                        return 'Invalid date';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _cvvController,
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                      prefixIcon: Icon(Icons.security),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Required';
                      }
                      if (value!.length < 3) {
                        return 'Invalid CVV';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Cardholder Name',
                hintText: 'John Doe',
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter cardholder name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Set as default payment method'),
              value: _setAsDefault,
              onChanged: (value) {
                setState(() {
                  _setAsDefault = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: CitySmartTheme.primaryGreen,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addCard,
          style: ElevatedButton.styleFrom(
            backgroundColor: CitySmartTheme.primaryGreen,
          ),
          child: const Text('Add Card', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  void _addCard() async {
    if (_formKey.currentState!.validate()) {
      final expiry = _expiryController.text.split('/');
      final success = await context.read<PaymentProvider>().addPaymentCard(
        cardNumber: _cardNumberController.text.replaceAll(' ', ''),
        expiryMonth: expiry[0],
        expiryYear: expiry[1],
        cvv: _cvvController.text,
        holderName: _nameController.text,
        setAsDefault: _setAsDefault,
      );

      if (success) {
        Navigator.of(context).pop();
      }
    }
  }
}

class _TransactionHistoryTab extends StatelessWidget {
  const _TransactionHistoryTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, child) {
        if (paymentProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: CitySmartTheme.primaryGreen,
            ),
          );
        }

        if (paymentProvider.paymentHistory.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No transactions yet',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your payment history will appear here',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: paymentProvider.paymentHistory.length,
          itemBuilder: (context, index) {
            final transaction = paymentProvider.paymentHistory[index];
            return _TransactionWidget(transaction: transaction);
          },
        );
      },
    );
  }
}

class _TransactionWidget extends StatelessWidget {
  final PaymentTransaction transaction;

  const _TransactionWidget({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(transaction.status),
          child: Icon(
            _getIconForTransactionType(transaction.type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          transaction.typeDisplayText,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              transaction.description ?? 'No description',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              _formatDate(transaction.createdAt),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              transaction.formattedAmount,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getAmountColor(transaction.type),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(transaction.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                transaction.statusDisplayText,
                style: TextStyle(
                  fontSize: 10,
                  color: _getStatusColor(transaction.status),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        onTap: () => _showTransactionDetails(context, transaction),
      ),
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.pending:
      case PaymentStatus.processing:
        return Colors.orange;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.refunded:
        return Colors.blue;
      case PaymentStatus.cancelled:
        return Colors.grey;
    }
  }

  Color _getAmountColor(TransactionType type) {
    switch (type) {
      case TransactionType.refund:
        return Colors.green;
      case TransactionType.fine:
        return Colors.red;
      default:
        return Colors.black87;
    }
  }

  IconData _getIconForTransactionType(TransactionType type) {
    switch (type) {
      case TransactionType.parking:
        return Icons.local_parking;
      case TransactionType.permit:
        return Icons.card_membership;
      case TransactionType.fine:
        return Icons.warning;
      case TransactionType.refund:
        return Icons.keyboard_return;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showTransactionDetails(
    BuildContext context,
    PaymentTransaction transaction,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction Details',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _DetailRow('Amount', transaction.formattedAmount),
            _DetailRow('Type', transaction.typeDisplayText),
            _DetailRow('Status', transaction.statusDisplayText),
            _DetailRow('Date', _formatDate(transaction.createdAt)),
            if (transaction.card != null)
              _DetailRow('Payment Method', transaction.card!.displayName),
            if (transaction.description != null)
              _DetailRow('Description', transaction.description!),
            if (transaction.failureReason != null)
              _DetailRow('Failure Reason', transaction.failureReason!),
            const SizedBox(height: 24),
            if (transaction.status == PaymentStatus.completed &&
                transaction.type != TransactionType.refund &&
                transaction.createdAt.isAfter(
                  DateTime.now().subtract(const Duration(days: 30)),
                ))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showRefundDialog(context, transaction);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text(
                    'Request Refund',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showRefundDialog(BuildContext context, PaymentTransaction transaction) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Refund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Request a refund for ${transaction.formattedAmount}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for refund',
                hintText: 'Please explain why you need a refund',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await context
                  .read<PaymentProvider>()
                  .requestRefund(transaction.id, reasonController.text);
              Navigator.of(context).pop();

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Refund request submitted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Submit Request',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

// Input formatters for credit card fields
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');

    if (text.length >= 2) {
      final month = text.substring(0, 2);
      final year = text.length > 2
          ? text.substring(2, text.length.clamp(0, 4))
          : '';
      final formatted = year.isNotEmpty ? '$month/$year' : month;

      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
