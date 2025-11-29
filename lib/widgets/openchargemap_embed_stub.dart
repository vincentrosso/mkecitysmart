import 'package:flutter/material.dart';

Widget buildOpenChargeMapEmbed(VoidCallback onOpenExternal) {
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'OpenChargeMap',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'View the live EV charging map in your browser. We’ll open the official OpenChargeMap experience.',
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onOpenExternal,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open full map'),
          ),
        ],
      ),
    ),
  );
}
