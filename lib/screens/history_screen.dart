import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  final List<String> historyItems = [
    'April 21 - Street Sweeping Alert',
    'April 18 - Park on the odd-numbered side',
    'April 10 - Permit renewed',
    'March 25 - Street Sweeping Alert',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF203731),
        title: Text('Parking History'),
      ),
      body: ListView.builder(
        itemCount: historyItems.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.history, color: Color(0xFF203731)),
            title: Text(historyItems[index]),
          );
        },
      ),
    );
  }
}
