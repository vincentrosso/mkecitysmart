import 'package:flutter/foundation.dart';

/// Tracks bootstrap steps so debugging hangs during startup is easier.
class BootstrapDiagnostics {
  BootstrapDiagnostics() {
    _sessionStart = DateTime.now();
  }

  late final DateTime _sessionStart;
  final List<BootstrapEntry> _entries = <BootstrapEntry>[];
  final Map<String, String> _metadata = <String, String>{};

  List<BootstrapEntry> get entries => List.unmodifiable(_entries);
  Map<String, String> get metadata => Map.unmodifiable(_metadata);
  DateTime get sessionStart => _sessionStart;

  void addMetadata(String key, Object value) {
    _metadata[key] = value.toString();
  }

  void recordStatus(
    String label,
    BootstrapStatus status, {
    String? details,
    Duration duration = Duration.zero,
  }) {
    final entry = BootstrapEntry(
      label: label,
      status: status,
      duration: duration,
      details: details,
    );
    _entries.add(entry);
    _debugLog(entry);
  }

  Future<T> recordFuture<T>(
    String label,
    Future<T> Function() runner, {
    void Function(T value, BootstrapEntry entry)? onSuccess,
    void Function(Object error, BootstrapEntry entry)? onError,
  }) async {
    final stopwatch = Stopwatch()..start();
    final entry = BootstrapEntry(label: label);
    try {
      final value = await runner();
      stopwatch.stop();
      entry
        ..duration = stopwatch.elapsed
        ..status = BootstrapStatus.success;
      onSuccess?.call(value, entry);
      _entries.add(entry);
      _debugLog(entry);
      return value;
    } catch (err) {
      stopwatch.stop();
      entry
        ..duration = stopwatch.elapsed
        ..status = BootstrapStatus.failed
        ..details = err.toString();
      onError?.call(err, entry);
      _entries.add(entry);
      _debugLog(entry);
      rethrow;
    }
  }

  void _debugLog(BootstrapEntry entry) {
    debugPrint(
      '[Bootstrap] ${entry.label} '
      '(${entry.duration.inMilliseconds}ms) '
      '- ${entry.status.name}${entry.details == null ? '' : ': ${entry.details}'}',
    );
  }
}

enum BootstrapStatus { success, failed, warning, skipped, info }

class BootstrapEntry {
  BootstrapEntry({
    required this.label,
    this.status = BootstrapStatus.info,
    this.duration = Duration.zero,
    this.details,
  });

  final String label;
  BootstrapStatus status;
  Duration duration;
  String? details;

  void setStatus(BootstrapStatus newStatus, {String? message}) {
    status = newStatus;
    if (message != null) details = message;
  }
}
