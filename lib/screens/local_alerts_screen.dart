import 'package:flutter/material.dart';

class LocalAlertsScreen extends StatelessWidget {
  const LocalAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Local Alerts')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'This is the Local Alerts screen. Replace with your real implementation.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
