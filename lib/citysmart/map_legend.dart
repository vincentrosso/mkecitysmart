import 'package:flutter/material.dart';

class MapLegend extends StatelessWidget {
  const MapLegend({super.key});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xCC0B0C10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0B000), width: 1.5),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LegendRow(color: Color(0xFFE0B000), label: "Parking"),
            SizedBox(height: 6),
            _LegendRow(color: Color(0xFF7CA726), label: "Garbage Route"),
            SizedBox(height: 6),
            _LegendRow(color: Color(0xFF1ABC9C), label: "EV Chargers"),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendRow({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(color: Colors.white)),
    ],
  );
}
