import 'package:flutter_test/flutter_test.dart';
import 'package:MKEPark_flutter_web/main.dart';

void main() {
  testWidgets('App renders WelcomeScreen and navigates to Parking', (tester) async {
    // Build the app
    await tester.pumpWidget(const MKEParkApp());

    // Verify WelcomeScreen content
    expect(find.text('Welcome to MKEPark'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    // Navigate to Parking
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Verify ParkingScreen content
    expect(find.text('Park on the odd-numbered side'), findsOneWidget);
  });
}
