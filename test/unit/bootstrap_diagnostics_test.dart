import 'package:flutter_test/flutter_test.dart';
import 'package:mkecitysmart/services/bootstrap_diagnostics.dart';

void main() {
  group('BootstrapDiagnostics', () {
    test('records statuses and metadata', () {
      final diagnostics = BootstrapDiagnostics();
      diagnostics.addMetadata('Key', 'Value');
      diagnostics.recordStatus('Step', BootstrapStatus.success);

      expect(diagnostics.metadata['Key'], 'Value');
      expect(diagnostics.entries, hasLength(1));
      expect(diagnostics.entries.first.status, BootstrapStatus.success);
    });

    test('recordFuture captures duration and errors', () async {
      final diagnostics = BootstrapDiagnostics();
      final result = await diagnostics.recordFuture<int>(
        'addition',
        () async => 2 + 2,
      );
      expect(result, 4);
      expect(diagnostics.entries.single.status, BootstrapStatus.success);

      final failing = BootstrapDiagnostics();
      await expectLater(
        failing.recordFuture<void>('fail', () async => throw StateError('boom')),
        throwsA(isA<StateError>()),
      );
      expect(failing.entries.single.status, BootstrapStatus.failed);
      expect(failing.entries.single.details, contains('boom'));
    });
  });
}
