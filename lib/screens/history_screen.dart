import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  static const List<String> _historyItems = [
    'April 21 - Street Sweeping Alert',
    'April 18 - Park on the odd-numbered side',
    'April 10 - Permit renewed',
    'March 25 - Street Sweeping Alert',
  ];

  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF203731),
        title: const Text('Parking History'),
      ),
      body: ListView.builder(
        itemCount: _historyItems.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.history, color: Color(0xFF203731)),
            title: Text(_historyItems[index]),
          );
        },
      ),
    );
  }
}
