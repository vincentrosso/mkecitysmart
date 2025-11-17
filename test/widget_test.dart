import 'package:flutter_test/flutter_test.dart';
import 'package:citysmart_parking_app/main.dart';

void main() {
  testWidgets('App renders WelcomeScreen and navigates to Landing', (
    tester,
  ) async {
    // Build the app
    await tester.pumpWidget(const CitySmartParkingApp());

    // Verify WelcomeScreen content
    expect(find.text('Welcome to CitySmart Parking App'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    // Navigate to Landing
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Verify LandingScreen content
    expect(find.text('CitySmart Parking App'), findsOneWidget);
    expect(find.text('Welcome to CitySmart Parking App'), findsOneWidget);
    expect(find.text('Monitor parking regulations in your area'), findsOneWidget);
  });
}
