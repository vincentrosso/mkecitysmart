import 'package:flutter/material.dart';
import '../services/parking_risk_service.dart';

/// Widget to display parking risk score
class ParkingRiskBadge extends StatelessWidget {
  final LocationRisk risk;
  final bool compact;

  const ParkingRiskBadge({
    super.key,
    required this.risk,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(risk.colorValue);
    final textColor = risk.riskLevel == RiskLevel.low 
        ? Colors.white 
        : Colors.white;

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${risk.riskPercentage}%',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(_getRiskIcon(), color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                'Risk: ${risk.riskLevel.name.toUpperCase()}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${risk.riskPercentage}%',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            risk.message,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 14,
            ),
          ),
          if (risk.topViolations.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: risk.topViolations.take(3).map((v) {
                return Chip(
                  label: Text(
                    v.replaceAll('_', ' '),
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: Colors.grey[200],
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
          if (risk.peakHours.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Peak: ${_formatPeakHours()}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _getRiskIcon() {
    switch (risk.riskLevel) {
      case RiskLevel.high:
        return Icons.warning_amber_rounded;
      case RiskLevel.medium:
        return Icons.info_outline;
      case RiskLevel.low:
        return Icons.check_circle_outline;
    }
  }

  String _formatPeakHours() {
    return risk.peakHours.take(3).map((h) {
      final suffix = h >= 12 ? 'PM' : 'AM';
      final hour12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      return '$hour12$suffix';
    }).join(', ');
  }
}

/// Loading state for risk badge
class ParkingRiskBadgeLoading extends StatelessWidget {
  const ParkingRiskBadgeLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 2),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Calculating risk...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Smart risk card that fetches and displays risk data
class ParkingRiskCard extends StatefulWidget {
  final double latitude;
  final double longitude;
  final bool showOnLowRisk;

  const ParkingRiskCard({
    super.key,
    required this.latitude,
    required this.longitude,
    this.showOnLowRisk = true,
  });

  @override
  State<ParkingRiskCard> createState() => _ParkingRiskCardState();
}

class _ParkingRiskCardState extends State<ParkingRiskCard> {
  LocationRisk? _risk;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRisk();
  }

  @override
  void didUpdateWidget(ParkingRiskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      _fetchRisk();
    }
  }

  Future<void> _fetchRisk() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final risk = await ParkingRiskService.instance.getRiskForLocation(
      widget.latitude,
      widget.longitude,
    );

    if (mounted) {
      setState(() {
        _risk = risk;
        _loading = false;
        _error = risk == null ? 'Unable to fetch risk data' : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ParkingRiskBadgeLoading();
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.grey[500], size: 20),
            const SizedBox(width: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const Spacer(),
            TextButton(
              onPressed: _fetchRisk,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_risk == null) {
      return const SizedBox.shrink();
    }

    // Optionally hide on low risk
    if (!widget.showOnLowRisk && _risk!.riskLevel == RiskLevel.low) {
      return const SizedBox.shrink();
    }

    return ParkingRiskBadge(risk: _risk!);
  }
}
