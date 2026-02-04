import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({super.key, required this.alertId});

  final String alertId;

  @override
  Widget build(BuildContext context) {
    final docRef = FirebaseFirestore.instance.collection('alerts').doc(alertId);

    return Scaffold(
      appBar: AppBar(title: const Text('Alert detail')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: docRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final doc = snapshot.data!;
          if (!doc.exists) {
            return const Center(child: Text('Alert not found.'));
          }
          final data = doc.data()!;
          final title = (data['title'] ?? '').toString();
          final message = (data['message'] ?? '').toString();
          final location = (data['location'] ?? '').toString();
          final type = (data['type'] ?? '').toString();
          final createdAt = data['createdAt'] as Timestamp?;
          final expiresAt = data['expiresAt'] as Timestamp?;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isNotEmpty ? title : 'Alert',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                if (message.isNotEmpty)
                  Text(message, style: Theme.of(context).textTheme.bodyLarge),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.place, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text(location)),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Text('Type: ${type.isNotEmpty ? type : 'unknown'}'),
                if (createdAt != null) Text('Created: ${createdAt.toDate()}'),
                if (expiresAt != null) Text('Expires: ${expiresAt.toDate()}'),
              ],
            ),
          );
        },
      ),
    );
  }
}
