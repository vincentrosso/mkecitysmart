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
  late List<String> _cities;
  String? _selectedOption;

  @override
  void initState() {
    super.initState();
    final provider = context.read<UserProvider>();
    _cityId = provider.cityId;
    _languageCode = provider.languageCode;
    _cities = const [
      'Milwaukee',
      'West Allis',
      'Wauwatosa',
      'Greenfield',
      'Oak Creek',
      'South Milwaukee',
      'Cudahy',
      'Franklin',
      'Glendale',
      'Shorewood',
      'Whitefish Bay',
      'Brown Deer',
      'St. Francis',
      'Bayside',
      'Fox Point',
      'Brookfield',
      'Madison',
      'Green Bay',
    ];
    _selectedOption = _cities.isNotEmpty ? _cities.first : null;
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
              Text('City', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_cities.isEmpty)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButton<String>(
                  value: _selectedOption,
                  hint: const Text('Select a city'),
                  items: _cities
                      .map(
                        (city) => DropdownMenuItem(
                          value: city,
                          child: Text(city),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    _selectedOption = value;
                    _cityId = value ?? 'default';
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
                onChanged: (value) => setState(() => _languageCode = value ?? 'en'),
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
                      Text('Rule pack (${pack.displayName})',
                          style: Theme.of(context).textTheme.titleMedium),
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
