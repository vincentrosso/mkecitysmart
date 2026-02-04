import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';

class CitySettingsScreen extends StatefulWidget {
  const CitySettingsScreen({super.key});

  @override
  State<CitySettingsScreen> createState() => _CitySettingsScreenState();
}

class _CitySettingsScreenState extends State<CitySettingsScreen> {
  late String _cityId;
  late String _languageCode;
  String? _selectedCity;

  // Milwaukee County municipalities - all covered by the app's data
  static const List<Map<String, dynamic>> _milwaukeeCountyCities = [
    {'name': 'Milwaukee', 'id': 'milwaukee', 'isMain': true},
    {'name': 'West Allis', 'id': 'west_allis', 'isMain': false},
    {'name': 'Wauwatosa', 'id': 'wauwatosa', 'isMain': false},
    {'name': 'Greenfield', 'id': 'greenfield', 'isMain': false},
    {'name': 'Oak Creek', 'id': 'oak_creek', 'isMain': false},
    {'name': 'South Milwaukee', 'id': 'south_milwaukee', 'isMain': false},
    {'name': 'Cudahy', 'id': 'cudahy', 'isMain': false},
    {'name': 'Franklin', 'id': 'franklin', 'isMain': false},
    {'name': 'Glendale', 'id': 'glendale', 'isMain': false},
    {'name': 'Shorewood', 'id': 'shorewood', 'isMain': false},
    {'name': 'Whitefish Bay', 'id': 'whitefish_bay', 'isMain': false},
    {'name': 'Brown Deer', 'id': 'brown_deer', 'isMain': false},
    {'name': 'St. Francis', 'id': 'st_francis', 'isMain': false},
    {'name': 'Bayside', 'id': 'bayside', 'isMain': false},
    {'name': 'Fox Point', 'id': 'fox_point', 'isMain': false},
    {'name': 'River Hills', 'id': 'river_hills', 'isMain': false},
    {'name': 'Hales Corners', 'id': 'hales_corners', 'isMain': false},
    {'name': 'Greendale', 'id': 'greendale', 'isMain': false},
    {'name': 'West Milwaukee', 'id': 'west_milwaukee', 'isMain': false},
  ];

  @override
  void initState() {
    super.initState();
    final provider = context.read<UserProvider>();
    _cityId = provider.cityId;
    _languageCode = provider.languageCode;

    // Ensure selected city matches one of the available cities
    // Default to 'milwaukee' if the current cityId isn't in the list
    final cityIds = _milwaukeeCountyCities
        .map((c) => c['id'] as String)
        .toList();
    if (cityIds.contains(_cityId)) {
      _selectedCity = _cityId;
    } else {
      _selectedCity = 'milwaukee';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        final pack = provider.rulePack;
        return Scaffold(
          appBar: AppBar(title: const Text('City & language')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Milwaukee County info banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF1565C0).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: const Color(0xFF1565C0)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Milwaukee County Coverage',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'All ${_milwaukeeCountyCities.length} municipalities in Milwaukee County are supported.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text('Your City', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Select your primary city for localized parking rules and alerts.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCity,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: _milwaukeeCountyCities
                    .map(
                      (city) => DropdownMenuItem(
                        value: city['id'] as String,
                        child: Row(
                          children: [
                            Text(city['name'] as String),
                            if (city['isMain'] == true) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1565C0),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'MAIN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _selectedCity = value;
                  _cityId = value ?? 'milwaukee';
                }),
              ),
              const SizedBox(height: 12),
              Text('Language', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _languageCode,
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'es', child: Text('Español')),
                  DropdownMenuItem(value: 'hmn', child: Text('Hmoob')),
                  DropdownMenuItem(value: 'ar', child: Text('العربية')),
                  DropdownMenuItem(value: 'fr', child: Text('Français')),
                ],
                onChanged: (value) =>
                    setState(() => _languageCode = value ?? 'en'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await provider.updateCityAndTenant(
                    cityId: _cityId,
                    tenantId: provider.tenantId,
                  );
                  await provider.updateLanguage(_languageCode);
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Settings updated')),
                  );
                },
                child: const Text('Save'),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rule pack (${pack.displayName})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _RuleItem(
                        label: 'Max vehicles',
                        value: pack.maxVehicles.toString(),
                      ),
                      _RuleItem(
                        label: 'Default alert radius',
                        value: '${pack.defaultAlertRadius} mi',
                      ),
                      _RuleItem(
                        label: 'Quota/hr',
                        value: pack.quotaRequestsPerHour.toString(),
                      ),
                      _RuleItem(
                        label: 'Rate limit/min',
                        value: pack.rateLimitPerMinute.toString(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RuleItem extends StatelessWidget {
  const _RuleItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
