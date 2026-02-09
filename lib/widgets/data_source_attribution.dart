import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A small, reusable widget that shows the official data source for a screen.
///
/// Google Play requires that apps displaying government information provide
/// clear, accessible links to the original source(s).
class DataSourceAttribution extends StatelessWidget {
  const DataSourceAttribution({
    super.key,
    required this.source,
    required this.url,
    this.prefix = 'Source',
  });

  /// Display name of the source, e.g. "City of Milwaukee DPW"
  final String source;

  /// The official URL to link to, e.g. "https://city.milwaukee.gov/dpw"
  final String url;

  /// Optional prefix text, defaults to "Source"
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.open_in_new,
            size: 12,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                children: [
                  TextSpan(text: '$prefix: '),
                  TextSpan(
                    text: source,
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _openUrl(url),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// A larger disclaimer card for the About / Legal section of the app.
///
/// Shows the full "not affiliated with government" disclaimer and lists
/// all official data sources used in the app.
class GovernmentDataDisclaimer extends StatelessWidget {
  const GovernmentDataDisclaimer({super.key});

  static const _sources = [
    _Source(
      'Parking & street data',
      'Milwaukee Maps (ArcGIS)',
      'https://milwaukeemaps.milwaukee.gov/arcgis/rest/services/',
    ),
    _Source(
      'Garbage & recycling schedules',
      'Milwaukee DPW',
      'https://itmdapps.milwaukee.gov/DpwServletsPublic/garbage_day',
    ),
    _Source(
      'Alternate side parking',
      'City of Milwaukee DPW',
      'https://city.milwaukee.gov/dpw/infrastructure/Street-Maintenance/Alternate-Side-Parking',
    ),
    _Source(
      'Street sweeping',
      'City of Milwaukee DPW',
      'https://city.milwaukee.gov/dpw/infrastructure/Street-Maintenance/Street-Sweeping',
    ),
    _Source(
      'Parking tickets',
      'City of Milwaukee',
      'https://city.milwaukee.gov/parkingtickets',
    ),
    _Source(
      'Weather alerts',
      'National Weather Service (NOAA)',
      'https://api.weather.gov',
    ),
    _Source(
      'EV charging stations',
      'OpenChargeMap',
      'https://openchargemap.org',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Data Sources & Disclaimer',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'MKE CitySmart is an independent application and is not '
              'affiliated with, endorsed by, or operated by the City of '
              'Milwaukee, Milwaukee County, or any government entity.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'City data is sourced from publicly available official sources:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            ..._sources.map((s) => _SourceRow(source: s)),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                children: [
                  const TextSpan(text: 'For official city services, visit '),
                  TextSpan(
                    text: 'city.milwaukee.gov',
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        final uri = Uri.parse('https://city.milwaukee.gov');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Source {
  const _Source(this.label, this.name, this.url);
  final String label;
  final String name;
  final String url;
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.source});
  final _Source source;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
            height: 1.6,
          ),
          children: [
            const TextSpan(text: '• '),
            TextSpan(
              text: '${source.label}: ',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            TextSpan(
              text: source.name,
              style: const TextStyle(decoration: TextDecoration.underline),
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  final uri = Uri.parse(source.url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
            ),
          ],
        ),
      ),
    );
  }
}
