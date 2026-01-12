import 'package:cloud_firestore/cloud_firestore.dart';
class _FeedBody extends StatelessWidget {
  const _FeedBody();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Simple first pass: show newest sightings
    final query = FirebaseFirestore.instance
        .collection('sightings')
        .orderBy('createdAt', descending: true)
        .limit(25);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          children: [
            Text('Feed', style: textTheme.headlineMedium),
            const SizedBox(height: 20),

            // Keep your sponsored card
            SponsoredFeedCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SponsoredDetailScreen()),
              ),
            ),
            const SizedBox(height: 16),

            if (snapshot.hasError)
              Text('Feed error: ${snapshot.error}',
                  style: textTheme.bodyMedium),

            if (!snapshot.hasData)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(child: CircularProgressIndicator()),
              ),

            if (snapshot.hasData) ...[
              const SizedBox(height: 16),
              ...snapshot.data!.docs.map((doc) {
                final d = doc.data();

                final type = (d['type'] ?? 'unknown').toString();
                final location = (d['location'] ?? '').toString();
                final notes = (d['notes'] ?? '').toString();

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type == 'towTruck' ? 'Tow Sighting' : 'Enforcement Sighting',
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        if (location.isNotEmpty)
                          Text(location, style: textTheme.bodyMedium),
                        if (notes.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(notes, style: textTheme.bodySmall),
                        ],
                      ],
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
