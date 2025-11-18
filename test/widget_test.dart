import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mkeparkapp_flutter/main.dart';
import 'package:mkeparkapp_flutter/services/user_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Welcome screen directs unauthenticated users to auth flow', (
    tester,
  ) async {
    final repository = await UserRepository.create();
    await tester.pumpWidget(MKEParkApp(userRepository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to MKEPark'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Account Access'), findsOneWidget);
  });
}
