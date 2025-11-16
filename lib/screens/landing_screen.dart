import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LandingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF203731),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'CitySmart Parking App',
              style: TextStyle(
                color: Color(0xFFFFB612),
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Welcome to CitySmart Parking App',
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
            SizedBox(height: 10),
            Text(
              'Monitor parking regulations in your area',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFB612),
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () {
                context.go('/history');
              },
              child: Text('View History'),
            ),
          ],
        ),
      ),
    );
  }
}
