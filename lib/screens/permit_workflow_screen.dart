import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/payment_receipt.dart';
import '../models/permit.dart';
import '../models/permit_eligibility.dart';
import '../providers/user_provider.dart';

class PermitWorkflowScreen extends StatefulWidget {
  const PermitWorkflowScreen({super.key});

  @override
  State<PermitWorkflowScreen> createState() => _PermitWorkflowScreenState();
}

class _PermitWorkflowScreenState extends State<PermitWorkflowScreen> {
  final _addressController = TextEditingController();
  int _unpaidTickets = 0;
  bool _hasProof = true;
  bool _isLowIncome = false;
  bool _isSenior = false;
  bool _ecoVehicle = true;
  PermitType _type = PermitType.residential;
  PermitEligibilityResult? _result;
  PaymentReceipt? _receipt;
  String _payMethod = 'card';

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _checkEligibility(UserProvider provider) {
    final result = provider.evaluatePermitEligibility(
      type: _type,
      hasProofOfResidence: _hasProof,
      unpaidTicketCount: _unpaidTickets,
      isLowIncome: _isLowIncome,
      isSenior: _isSenior,
      ecoVehicle: _ecoVehicle,
    );
    setState(() {
      _result = result;
      _receipt = null;
    });
  }

  void _settle(UserProvider provider) {
    if (_result == null || !_result!.eligible) return;
    final receipt = provider.settlePermit(
      result: _result!,
      method: _payMethod,
    );
    setState(() {
      _receipt = receipt;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Permit settled and receipt generated.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Permit eligibility & settlement'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Real-time eligibility',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<PermitType>(
                        initialValue: _type,
                        decoration: const InputDecoration(labelText: 'Permit type'),
                        items: PermitType.values
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type.name.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _type = value ?? PermitType.residential),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          hintText: '1234 E Sample St',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            selected: _hasProof,
                            label: const Text('Proof of residence'),
                            onSelected: (value) => setState(() => _hasProof = value),
                          ),
                          FilterChip(
                            selected: _ecoVehicle,
                            label: const Text('EV/Hybrid'),
                            onSelected: (value) => setState(() => _ecoVehicle = value),
                          ),
                          FilterChip(
                            selected: _isLowIncome,
                            label: const Text('Low-income'),
                            onSelected: (value) =>
                                setState(() => _isLowIncome = value),
                          ),
                          FilterChip(
                            selected: _isSenior,
                            label: const Text('Senior'),
                            onSelected: (value) => setState(() => _isSenior = value),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Unpaid tickets'),
                          const Spacer(),
                          IconButton(
                            onPressed: () => setState(
                              () => _unpaidTickets = (_unpaidTickets - 1).clamp(0, 99),
                            ),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('$_unpaidTickets'),
                          IconButton(
                            onPressed: () => setState(() => _unpaidTickets++),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => _checkEligibility(provider),
                        child: const Text('Check eligibility'),
                      ),
                    ],
                  ),
                ),
              ),
              if (_result != null) ...[
                const SizedBox(height: 12),
                _EligibilityResultCard(result: _result!),
                if (_result!.eligible) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Settle now',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'card', label: Text('Card')),
                              ButtonSegment(value: 'ach', label: Text('ACH')),
                            ],
                            selected: {_payMethod},
                            onSelectionChanged: (value) =>
                                setState(() => _payMethod = value.first),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () => _settle(provider),
                            icon: const Icon(Icons.verified),
                            label: Text('Pay \$${_result!.totalDue.toStringAsFixed(2)}'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
              if (_receipt != null) ...[
                const SizedBox(height: 12),
                _ReceiptCard(receipt: _receipt!),
              ],
              const SizedBox(height: 12),
              if (context.read<UserProvider>().receipts
                  .where((r) => r.category == 'permit')
                  .isNotEmpty) ...[
                Text(
                  'Permit receipts',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...context.read<UserProvider>().receipts
                    .where((r) => r.category == 'permit')
                    .map((r) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.receipt),
                            title: Text(r.reference),
                            subtitle: Text(
                              '\$${r.amountCharged.toStringAsFixed(2)} • ${r.method.toUpperCase()}',
                            ),
                            trailing: Text(
                              r.createdAt.toLocal().toString().split('.').first,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        )),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _EligibilityResultCard extends StatelessWidget {
  const _EligibilityResultCard({required this.result});
  final PermitEligibilityResult result;

  @override
  Widget build(BuildContext context) {
    final eligibleColor = result.eligible ? Colors.green : Colors.redAccent;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.eligible ? Icons.check_circle : Icons.error,
                  color: eligibleColor,
                ),
                const SizedBox(width: 8),
                Text(
                  result.eligible ? 'Eligible' : 'Not eligible',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(result.reason),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _FeeItem(label: 'Base fee', value: result.baseFee),
                _FeeItem(label: 'Surcharges', value: result.surcharges),
                _FeeItem(label: 'Waiver', value: -result.waiverAmount),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total due', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '\$${result.totalDue.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
              ],
            ),
            if (result.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...result.notes.map((note) => Text('• $note')),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeeItem extends StatelessWidget {
  const _FeeItem({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final display = value >= 0 ? '\$${value.toStringAsFixed(2)}' : '-\$${value.abs().toStringAsFixed(2)}';
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 4),
        Text(display, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.receipt});
  final PaymentReceipt receipt;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Receipt ${receipt.reference}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Method: ${receipt.method.toUpperCase()}'),
            Text('Charged: \$${receipt.amountCharged.toStringAsFixed(2)}'),
            if (receipt.waivedAmount > 0)
              Text('Waived: \$${receipt.waivedAmount.toStringAsFixed(2)}'),
            Text('Time: ${receipt.createdAt}'),
            if (receipt.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(receipt.description),
            ],
          ],
        ),
      ),
    );
  }
}
