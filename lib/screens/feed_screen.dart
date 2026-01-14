import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widgets/citysmart_scaffold.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CitySmartScaffold(
      title: 'MKE CitySmart',
      currentIndex: 2,
      body: _FeedBody(),
    );
  }
}

class _FeedBody extends StatelessWidget {
  const _FeedBody();

  // Centralize the alerts query so we don't accidentally read different paths/filters.
  // Order by createdAt DESC ensures the newest alert shows first and edits are obvious.
  Query<Map<String, dynamic>> _alertsQuery() {
    // NOTE: If this requires an index, Firestore will show a link to create it.
    return FirebaseFirestore.instance
        .collection('alerts')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(50);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _alertsQuery().snapshots(includeMetadataChanges: true),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final fromCache = snapshot.data?.metadata.isFromCache ?? false;

        if (kDebugMode) {
          debugPrint('[Feed] alerts docs=${docs.length} fromCache=$fromCache');
          if (docs.isNotEmpty) {
            final d0 = docs.first;
            debugPrint('[Feed] top docId=${d0.id} data=${d0.data()}');
          }
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          children: [
            Text('Feed', style: textTheme.headlineMedium),
            const SizedBox(height: 20),
            SponsoredFeedCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SponsoredDetailScreen()),
              ),
            ),
            const SizedBox(height: 16),
            if (snapshot.hasError)
              Text(
                'Feed error: ${snapshot.error}',
                style: textTheme.bodyMedium,
              ),
            if (!snapshot.hasData)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (snapshot.hasData) ...[
              const SizedBox(height: 16),
              ...docs.map((doc) {
                final d = doc.data();
                final type = (d['type'] ?? 'unknown').toString();
                final title = (d['title'] ?? '').toString();
                final message = (d['message'] ?? '').toString();
                final location = (d['location'] ?? '').toString();
                final createdAt = d['createdAt'] as Timestamp?;
                final createdAtRaw = d['createdAt'];

                return Card(
                  child: InkWell(
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/alert-detail',
                      arguments: doc.id,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.isNotEmpty
                                ? title
                                : type == 'tow' || type == 'towTruck'
                                    ? 'Tow Sighting'
                                    : 'Enforcement Sighting',
                            style: textTheme.titleMedium,
                          ),
                          if (message.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(message, style: textTheme.bodyMedium),
                          ],
                          const SizedBox(height: 6),
                          if (location.isNotEmpty)
                            Text(location, style: textTheme.bodyMedium),
                          if (createdAt != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Posted ${createdAt.toDate()}',
                              style: textTheme.bodySmall,
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            [
                              'id=${doc.id}',
                              if (createdAtRaw != null)
                                'createdAt=$createdAtRaw',
                              if (fromCache) '(cache)',
                            ].where((s) => s.trim().isNotEmpty).join(' • '),
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ],
        );
      },
    );
  }
}

class SponsoredFeedCard extends StatelessWidget {
  const SponsoredFeedCard({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.local_offer),
        title: const Text('Sponsored: City services near you'),
        subtitle: const Text('Tap to learn more'),
        onTap: onTap,
      ),
    );
  }
}

class SponsoredDetailScreen extends StatelessWidget {
  const SponsoredDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sponsored Detail')),
      body: const Center(
        child: Text('Sponsored content goes here.'),
      ),
    );
  }
}
