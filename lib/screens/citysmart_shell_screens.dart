import 'package:flutter/material.dart';

class ParkingShellScreen extends StatelessWidget {
  const ParkingShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimpleShellScaffold(
      title: 'Parking',
      body: 'Parking details go here',
    );
  }
}

class GarbageDayShellScreen extends StatelessWidget {
  const GarbageDayShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimpleShellScaffold(
      title: 'Garbage Day',
      body: 'Garbage schedule details go here',
    );
  }
}

class EVChargersShellScreen extends StatelessWidget {
  const EVChargersShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimpleShellScaffold(
      title: 'EV Chargers',
      body: 'Nearby EV charging stations go here',
    );
  }
}

class AlertsShellScreen extends StatelessWidget {
  const AlertsShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimpleShellScaffold(
      title: 'Alerts',
      body: 'Alert list goes here',
    );
  }
}

class _SimpleShellScaffold extends StatelessWidget {
  const _SimpleShellScaffold({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(body)),
    );
  }
}
