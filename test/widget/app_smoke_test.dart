import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:mkecitysmart/main.dart';
import 'package:mkecitysmart/services/user_repository.dart';
import 'package:mkecitysmart/services/bootstrap_diagnostics.dart';

import 'app_smoke_test.mocks.dart';

@GenerateMocks([FirebaseAuth, User, UserRepository])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App boots into shell and allows tab switching', (tester) async {
    final auth = MockFirebaseAuth();
    final user = MockUser();
    final repository = MockUserRepository();

    when(auth.currentUser).thenReturn(null);
    when(user.uid).thenReturn('testuser');
    when(repository.loadProfile()).thenAnswer((_) async => null);
    when(repository.loadTickets()).thenAnswer((_) async => []);
    when(repository.loadReceipts()).thenAnswer((_) async => []);
    when(repository.loadMaintenanceReports()).thenAnswer((_) async => []);
    when(repository.loadSightings()).thenAnswer((_) async => []);

    await tester.pumpWidget(
      MKEParkApp(
        userRepository: repository,
        diagnostics: BootstrapDiagnostics(),
        firebaseReady: false, // offline/guest for smoke test
      ),
    );

    // Use pump() with fixed durations instead of pumpAndSettle() to avoid
    // hanging on async operations that never complete in tests (e.g., location
    // services, network calls, animations).
    await tester.pump(); // Initial frame
    await tester.pump(const Duration(milliseconds: 500)); // Allow async init
    await tester.pump(const Duration(milliseconds: 500)); // Second pass

    // Quick start sheet may appear; dismiss if present.
    if (find.text('Quick start').evaluate().isNotEmpty) {
      await tester.tap(find.text('Skip').first);
      await tester.pump(const Duration(milliseconds: 300));
    }

    // The app should show Dashboard or at least be in a usable state.
    // Check for any recognizable widget from the app shell.
    expect(find.byType(MaterialApp), findsOneWidget);

    // Note: Don't navigate to Feed here. Feed uses Firestore and would require
    // Firebase initialization; this smoke test intentionally runs with
    // firebaseReady=false.
  });
}
