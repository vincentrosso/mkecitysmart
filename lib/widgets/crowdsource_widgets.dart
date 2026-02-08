import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/parking_report.dart';
import '../models/subscription_plan.dart';
import '../services/location_service.dart';
import '../services/parking_crowdsource_service.dart';
import '../services/zone_aggregation_service.dart';
import '../theme/app_theme.dart';
import 'feature_gate.dart';

// ---------------------------------------------------------------------------
// Report Submission Bottom-Sheet
// ---------------------------------------------------------------------------

/// Opens a bottom-sheet where the user picks a report type and submits.
///
/// Returns the created [ParkingReport] or `null` if dismissed / failed.
Future<ParkingReport?> showReportSheet(BuildContext context) {
  return showModalBottomSheet<ParkingReport>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ReportSheet(),
  );
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet();
  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final _crowdsource = ParkingCrowdsourceService.instance;
  final _locationService = LocationService();

  ReportType? _selected;
  Position? _position;
  bool _locating = true;
  bool _submitting = false;
  String? _error;
  String _note = '';

  @override
  void initState() {
    super.initState();
    _acquireLocation();
  }

  Future<void> _acquireLocation() async {
    try {
      final pos = await _locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _position = pos;
        _locating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Location unavailable. Enable GPS and try again.';
        _locating = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_selected == null || _position == null) return;
    setState(() => _submitting = true);

    final report = await _crowdsource.submitReport(
      reportType: _selected!,
      latitude: _position!.latitude,
      longitude: _position!.longitude,
      accuracyMeters: _position!.accuracy,
      note: _note.trim().isEmpty ? null : _note.trim(),
    );

    if (!mounted) return;

    if (report != null) {
      Navigator.pop(context, report);
    } else {
      setState(() {
        _error = 'Could not submit report. Try again shortly.';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F2B24), // slightly lighter than kCitySmartBg
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomPadding),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: kCitySmartMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Row(
              children: [
                const Icon(Icons.campaign, color: kCitySmartYellow, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Report Parking Info',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: kCitySmartText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Help other drivers by sharing what you see.',
                style: TextStyle(color: kCitySmartMuted, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),

            // GPS status chip
            _GpsChip(locating: _locating, accuracy: _position?.accuracy),
            const SizedBox(height: 16),

            // Report type grid
            _ReportTypeGrid(
              selected: _selected,
              onSelect: (t) => setState(() => _selected = t),
            ),
            const SizedBox(height: 12),

            // Optional note
            TextField(
              maxLength: 80,
              maxLines: 1,
              style: const TextStyle(color: kCitySmartText),
              decoration: InputDecoration(
                hintText: 'Add a quick note (optional)',
                hintStyle: TextStyle(
                  color: kCitySmartMuted.withValues(alpha: 0.6),
                ),
                filled: true,
                fillColor: kCitySmartCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1F3A34)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1F3A34)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kCitySmartYellow),
                ),
                counterStyle: const TextStyle(color: kCitySmartMuted),
              ),
              onChanged: (v) => _note = v,
            ),
            const SizedBox(height: 8),

            // Error
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 13,
                  ),
                ),
              ),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed:
                    (_selected != null && _position != null && !_submitting)
                    ? _submit
                    : null,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(_submitting ? 'Submitting…' : 'Submit Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kCitySmartYellow,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: kCitySmartYellow.withValues(
                    alpha: 0.3,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// GPS accuracy chip
// ---------------------------------------------------------------------------

class _GpsChip extends StatelessWidget {
  const _GpsChip({required this.locating, this.accuracy});
  final bool locating;
  final double? accuracy;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    final IconData icon;

    if (locating) {
      color = Colors.blue;
      label = 'Getting location…';
      icon = Icons.gps_not_fixed;
    } else if (accuracy == null) {
      color = Colors.orangeAccent;
      label = 'GPS unavailable';
      icon = Icons.gps_off;
    } else if (accuracy! <= 10) {
      color = const Color(0xFF4CAF50);
      label = 'GPS: ±${accuracy!.round()}m — excellent';
      icon = Icons.gps_fixed;
    } else if (accuracy! <= 30) {
      color = kCitySmartYellow;
      label = 'GPS: ±${accuracy!.round()}m — good';
      icon = Icons.gps_fixed;
    } else {
      color = Colors.orangeAccent;
      label = 'GPS: ±${accuracy!.round()}m — rough';
      icon = Icons.gps_not_fixed;
    }

    return Row(
      children: [
        if (locating)
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          )
        else
          Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Report type selection grid
// ---------------------------------------------------------------------------

class _ReportTypeGrid extends StatelessWidget {
  const _ReportTypeGrid({required this.selected, required this.onSelect});
  final ReportType? selected;
  final ValueChanged<ReportType> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: ReportType.values.map((type) {
        final isSelected = type == selected;
        return GestureDetector(
          onTap: () => onSelect(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: (MediaQuery.of(context).size.width - 70) / 2,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? kCitySmartYellow.withValues(alpha: 0.15)
                  : kCitySmartCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? kCitySmartYellow : const Color(0xFF1F3A34),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  type.icon,
                  size: 22,
                  color: isSelected ? kCitySmartYellow : kCitySmartMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    type.displayName,
                    style: TextStyle(
                      color: isSelected ? kCitySmartYellow : kCitySmartText,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Live Availability Banner
// ---------------------------------------------------------------------------

/// A compact, auto-updating banner showing real-time parking availability
/// for the user's current area. Uses Firestore snapshot stream.
class CrowdsourceAvailabilityBanner extends StatefulWidget {
  const CrowdsourceAvailabilityBanner({super.key});

  @override
  State<CrowdsourceAvailabilityBanner> createState() =>
      _CrowdsourceAvailabilityBannerState();
}

class _CrowdsourceAvailabilityBannerState
    extends State<CrowdsourceAvailabilityBanner>
    with SingleTickerProviderStateMixin {
  final _crowdsource = ParkingCrowdsourceService.instance;
  final _zoneService = ZoneAggregationService.instance;
  final _locationService = LocationService();

  StreamSubscription<List<ParkingReport>>? _sub;
  StreamSubscription<int>? _spotCountSub;
  SpotAvailability? _availability;
  int _reportCount = 0;
  int _zoneSpotCount = 0; // Aggregated spot count from zones
  bool _loading = true;

  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
    _startStream();
  }

  Future<void> _startStream() async {
    try {
      debugPrint('[CrowdsourceBanner] Starting stream...');
      final pos = await _locationService.getCurrentPosition().timeout(
        const Duration(seconds: 8),
      );
      if (pos == null || !mounted) {
        debugPrint('[CrowdsourceBanner] Location unavailable or not mounted');
        if (mounted) setState(() => _loading = false);
        return;
      }

      debugPrint(
        '[CrowdsourceBanner] Location acquired: ${pos.latitude}, ${pos.longitude}',
      );

      _sub = _crowdsource
          .nearbyReportsStream(latitude: pos.latitude, longitude: pos.longitude)
          .listen(
            (reports) {
              if (!mounted) return;
              debugPrint(
                '[CrowdsourceBanner] Received ${reports.length} reports',
              );
              final avail = ParkingCrowdsourceService.aggregateAvailability(
                reports,
              );
              final countChanged = reports.length != _reportCount;
              setState(() {
                _availability = avail;
                _reportCount = reports.length;
                _loading = false;
              });
              // Pulse animation when new data arrives
              if (countChanged && reports.isNotEmpty) {
                _pulse.forward(from: 0);
              }
            },
            onError: (e) {
              debugPrint('[CrowdsourceBanner] Reports stream error: $e');
              if (mounted) setState(() => _loading = false);
            },
          );

      // Also subscribe to zone-level aggregated spot counts
      _spotCountSub = _zoneService
          .nearbySpotCountStream(
            latitude: pos.latitude,
            longitude: pos.longitude,
          )
          .listen(
            (count) {
              if (!mounted) return;
              setState(() => _zoneSpotCount = count);
            },
            onError: (e) {
              debugPrint('[CrowdsourceBanner] Spot count stream error: $e');
            },
          );
    } catch (e) {
      debugPrint('[CrowdsourceBanner] Failed to start stream: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _spotCountSub?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '[CrowdsourceBanner] build: loading=$_loading, '
      'availability=$_availability, reportCount=$_reportCount',
    );
    if (_loading) {
      return const SizedBox.shrink(); // Don't show while loading
    }
    if (_availability == null || _reportCount == 0) {
      return _EmptyBanner(onReport: () => showReportSheet(context));
    }

    final avail = _availability!;
    // Pro users see zone-aggregated spot counts; Free users see basic labels
    final hasSpotAccess = FeatureGate.hasAccess(
      context,
      PremiumFeature.spotCounts,
    );

    // Prefer zone-aggregated spot count; fall back to signal-based estimate
    final spotCount = _zoneSpotCount > 0
        ? _zoneSpotCount
        : avail.estimatedOpenSpots;

    final String displayLabel;
    final Color displayColor;

    if (hasSpotAccess && spotCount > 0) {
      displayLabel = '~$spotCount spot${spotCount == 1 ? '' : 's'} open';
      displayColor = spotCount >= 5
          ? Colors.green
          : spotCount >= 2
          ? Colors.orange
          : Colors.orange;
    } else {
      displayLabel = avail.label;
      displayColor = avail.color;
    }

    return ScaleTransition(
      scale: _pulseAnim,
      child: Card(
        color: kCitySmartCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: displayColor.withValues(alpha: 0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Availability dot
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: displayColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: displayColor.withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Label + report count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayLabel,
                      style: TextStyle(
                        color: displayColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '$_reportCount report${_reportCount == 1 ? '' : 's'} nearby • Live',
                      style: const TextStyle(
                        color: kCitySmartMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Enforcement warning
              if (avail.hasEnforcement)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Tooltip(
                    message: 'Enforcement spotted nearby',
                    child: Icon(
                      Icons.policy,
                      color: Colors.redAccent.shade200,
                      size: 20,
                    ),
                  ),
                ),

              // Report button
              _MiniReportButton(
                onTap: () async {
                  final report = await showReportSheet(context);
                  if (report != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '✓ ${report.reportType.displayName} reported!',
                        ),
                        backgroundColor: const Color(0xFF4CAF50),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when there are no nearby reports yet — invites user to be the first.
class _EmptyBanner extends StatelessWidget {
  const _EmptyBanner({required this.onReport});
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kCitySmartCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF1F3A34)),
      ),
      child: InkWell(
        onTap: onReport,
        borderRadius: BorderRadius.circular(14),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.campaign_outlined, color: kCitySmartMuted, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No reports nearby yet — be the first!',
                  style: TextStyle(color: kCitySmartMuted, fontSize: 13),
                ),
              ),
              Icon(Icons.add_circle_outline, color: kCitySmartYellow, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small "+" button used inline.
class _MiniReportButton extends StatelessWidget {
  const _MiniReportButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kCitySmartYellow.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: kCitySmartYellow, size: 16),
              SizedBox(width: 4),
              Text(
                'Report',
                style: TextStyle(
                  color: kCitySmartYellow,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
