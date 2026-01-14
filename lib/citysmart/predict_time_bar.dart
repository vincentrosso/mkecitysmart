import 'package:flutter/material.dart';

class PredictTimeBar extends StatefulWidget {
  final void Function(DateTime whenLocal) onApply;
  const PredictTimeBar({super.key, required this.onApply});
  @override
  State<PredictTimeBar> createState() => _PredictTimeBarState();
}

class _PredictTimeBarState extends State<PredictTimeBar> {
  DateTime _when = DateTime.now();
  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (d != null) {
      setState(() => _when = DateTime(d.year, d.month, d.day, _when.hour));
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _when.hour, minute: 0),
    );
    if (t != null) {
      setState(
        () => _when = DateTime(_when.year, _when.month, _when.day, t.hour),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xD90B0C10).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0B000), width: 1.5),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: _pickDate,
            child: const Icon(Icons.calendar_month, color: Color(0xFFE0B000)),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _pickTime,
            child: const Icon(Icons.access_time, color: Color(0xFFE0B000)),
          ),
          const Spacer(),
          TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFE0B000),
              foregroundColor: const Color(0xFF0B0C10),
            ),
            onPressed: () => widget.onApply(_when),
            icon: const Icon(Icons.refresh),
            label: const Text("Preview"),
          ),
        ],
      ),
    );
  }
}
