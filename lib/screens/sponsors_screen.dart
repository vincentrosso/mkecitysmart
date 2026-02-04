import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/citysmart_scaffold.dart';

/// Sponsor/Partner data model
class Sponsor {
  final String id;
  final String name;
  final String description;
  final String category;
  final String? imageUrl;
  final String? websiteUrl;
  final String? promoCode;
  final String? promoDescription;
  final bool isFeatured;

  const Sponsor({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.imageUrl,
    this.websiteUrl,
    this.promoCode,
    this.promoDescription,
    this.isFeatured = false,
  });
}

class SponsorsScreen extends StatelessWidget {
  const SponsorsScreen({super.key});

  // Sample sponsors - in production, fetch from Firestore or backend
  static const List<Sponsor> _sponsors = [
    // Featured Partners
    Sponsor(
      id: 'parking_mke_1',
      name: 'Milwaukee Parking Authority',
      description: 'Official city parking services and meter payment.',
      category: 'Parking',
      imageUrl: 'https://city.milwaukee.gov/images/parkinglogo.png',
      websiteUrl: 'https://city.milwaukee.gov/parking',
      isFeatured: true,
    ),
    Sponsor(
      id: 'spothero_1',
      name: 'SpotHero',
      description: 'Find and book parking spots in advance. Save up to 50%!',
      category: 'Parking',
      websiteUrl: 'https://spothero.com',
      promoCode: 'CITYSMART10',
      promoDescription: '10% off your first booking',
      isFeatured: true,
    ),
    // Auto Services
    Sponsor(
      id: 'midas_mke',
      name: 'Midas Milwaukee',
      description: 'Expert auto repair and maintenance services.',
      category: 'Auto Services',
      websiteUrl: 'https://midas.com',
      promoCode: 'MKESMART15',
      promoDescription: '15% off oil change',
    ),
    Sponsor(
      id: 'safelite_1',
      name: 'Safelite AutoGlass',
      description: 'Windshield repair and replacement.',
      category: 'Auto Services',
      websiteUrl: 'https://safelite.com',
      promoCode: 'CITY20',
      promoDescription: '\$20 off windshield replacement',
    ),
    // Insurance
    Sponsor(
      id: 'progressive_1',
      name: 'Progressive Insurance',
      description: 'Auto insurance with competitive rates.',
      category: 'Insurance',
      websiteUrl: 'https://progressive.com',
      promoDescription: 'Get a free quote',
    ),
    Sponsor(
      id: 'geico_1',
      name: 'GEICO',
      description: '15 minutes could save you 15% or more.',
      category: 'Insurance',
      websiteUrl: 'https://geico.com',
    ),
    // Local Deals
    Sponsor(
      id: 'lakefront_brewery',
      name: 'Lakefront Brewery',
      description: 'Milwaukee\'s favorite craft brewery. Free parking!',
      category: 'Local Business',
      websiteUrl: 'https://lakefrontbrewery.com',
      promoDescription: 'Free parking with brewery tour',
    ),
    Sponsor(
      id: 'summerfest',
      name: 'Summerfest',
      description: 'The World\'s Largest Music Festival',
      category: 'Events',
      websiteUrl: 'https://summerfest.com',
      promoDescription: 'Parking tips and shuttle info',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final featured = _sponsors.where((s) => s.isFeatured).toList();
    final categories = _sponsors.map((s) => s.category).toSet().toList();

    return CitySmartScaffold(
      title: 'Sponsors & Partners',
      currentIndex: -1, // Not in bottom nav
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF1565C0), const Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.handshake, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'Our Partners',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Supporting Milwaukee drivers with exclusive deals and services.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Featured Partners
          if (featured.isNotEmpty) ...[
            _SectionHeader(title: 'Featured Partners', icon: Icons.star),
            const SizedBox(height: 12),
            ...featured.map((s) => _FeaturedSponsorCard(sponsor: s)),
            const SizedBox(height: 24),
          ],

          // Categories
          ...categories
              .where(
                (c) => !featured.any(
                  (f) =>
                      f.category == c &&
                      featured.length ==
                          _sponsors.where((s) => s.category == c).length,
                ),
              )
              .map((category) {
                final categorySponsors = _sponsors
                    .where((s) => s.category == category && !s.isFeatured)
                    .toList();
                if (categorySponsors.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      title: category,
                      icon: _getCategoryIcon(category),
                    ),
                    const SizedBox(height: 12),
                    ...categorySponsors.map((s) => _SponsorCard(sponsor: s)),
                    const SizedBox(height: 20),
                  ],
                );
              }),

          // Become a sponsor CTA
          const SizedBox(height: 16),
          _BecomeASponsorCard(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Parking':
        return Icons.local_parking;
      case 'Auto Services':
        return Icons.build;
      case 'Insurance':
        return Icons.security;
      case 'Local Business':
        return Icons.store;
      case 'Events':
        return Icons.event;
      default:
        return Icons.business;
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: const Color(0xFF1565C0)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _FeaturedSponsorCard extends StatelessWidget {
  final Sponsor sponsor;

  const _FeaturedSponsorCard({required this.sponsor});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.amber.shade300, width: 2),
      ),
      child: InkWell(
        onTap: () => _launchUrl(sponsor.websiteUrl),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getSponsorIcon(sponsor.category),
                      size: 32,
                      color: const Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                sponsor.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'FEATURED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sponsor.category,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(sponsor.description, style: const TextStyle(fontSize: 14)),
              if (sponsor.promoCode != null ||
                  sponsor.promoDescription != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_offer,
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (sponsor.promoCode != null)
                              Text(
                                'Code: ${sponsor.promoCode}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            if (sponsor.promoDescription != null)
                              Text(
                                sponsor.promoDescription!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _launchUrl(sponsor.websiteUrl),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Visit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSponsorIcon(String category) {
    switch (category) {
      case 'Parking':
        return Icons.local_parking;
      case 'Auto Services':
        return Icons.build;
      case 'Insurance':
        return Icons.security;
      default:
        return Icons.business;
    }
  }
}

class _SponsorCard extends StatelessWidget {
  final Sponsor sponsor;

  const _SponsorCard({required this.sponsor});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _launchUrl(sponsor.websiteUrl),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getSponsorIcon(sponsor.category),
                  size: 24,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sponsor.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sponsor.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (sponsor.promoCode != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '🎁 ${sponsor.promoCode}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSponsorIcon(String category) {
    switch (category) {
      case 'Parking':
        return Icons.local_parking;
      case 'Auto Services':
        return Icons.build;
      case 'Insurance':
        return Icons.security;
      case 'Local Business':
        return Icons.store;
      case 'Events':
        return Icons.event;
      default:
        return Icons.business;
    }
  }
}

class _BecomeASponsorCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.campaign, size: 40, color: Colors.grey.shade600),
            const SizedBox(height: 12),
            const Text(
              'Become a Partner',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Reach Milwaukee drivers with targeted ads relevant to parking, auto services, and local businesses.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                _launchUrl(
                  'mailto:partners@mkecitysmart.com?subject=Partnership Inquiry',
                );
              },
              icon: const Icon(Icons.email),
              label: const Text('Contact Us'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _launchUrl(String? url) async {
  if (url == null) return;
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
