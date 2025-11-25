import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
        ),
        title: const Text('CitySmart'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        children: [
          Text('Feed', style: textTheme.headlineMedium),
          const SizedBox(height: 20),
          SponsoredFeedCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SponsoredDetailScreen(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AlertFeedCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AlertDetailScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SponsoredFeedCard extends StatelessWidget {
  const SponsoredFeedCard({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sponsored', style: textTheme.labelSmall),
                  const Icon(Icons.chevron_right, color: kCitySmartMuted),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 150,
                  color: const Color(0xFF25322C),
                  child: const Center(
                    child: Icon(
                      Icons.directions_car,
                      size: 48,
                      color: kCitySmartYellow,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Get Ahead With Auto Loan Rates',
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Make your move with a flexible car loan today',
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AlertFeedCard extends StatelessWidget {
  const AlertFeedCard({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: kCitySmartYellow.withOpacity(0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: kCitySmartYellow,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Alert', style: textTheme.labelSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Tow Sighting',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tow trucks spotted near 3rd St. & Maple Ave.',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
        child: Text('Sponsored content details...'),
      ),
    );
  }
}

class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alert Detail')),
      body: const Center(
        child: Text('Alert details...'),
      ),
    );
  }
}
