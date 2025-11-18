import 'package:flutter/material.dart';

class ParkingScreen extends StatelessWidget {
  const ParkingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF003E29),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003E29),
        title: const Text('MKEPark', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
    ),
drawer: Drawer(
  backgroundColor: const Color(0xFF003E29),
  child: Builder(
    builder: (context) => ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: const BoxDecoration(color: Color(0xFF003E29)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Text(
                  'P',
                  style: TextStyle(
                    fontSize: 30,
                    color: Color(0xFF003E29),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Milwaukee, WI',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.home, color: Colors.white),
          title: const Text('Home', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/');
          },
        ),
        ListTile(
          leading: const Icon(Icons.dashboard, color: Colors.white),
          title: const Text('Overview', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/overview');
          },
        ),
        ListTile(
          leading: const Icon(Icons.badge, color: Colors.white),
          title: const Text('Permit', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/permit');
          },
        ),
        ListTile(
          leading: const Icon(Icons.cleaning_services, color: Colors.white),
          title: const Text('Street Sweeping', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/sweeping');
          },
        ),
        ListTile(
          leading: const Icon(Icons.history, color: Colors.white),
          title: const Text('Parking History', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.location_on, color: Colors.white),
          title: const Text('Location Tracking', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.flag, color: Colors.white),
          title: const Text('TEST HERE', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
          },
        ),
      ],
    ),
  ),
),

      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Friday, April 18',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),

                SizedBox(height: 16),
                Text(
                  'Park on the odd-numbered side',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),

    );
  }
}
