import 'package:flutter/material.dart';

import 'charging_map_screen.dart';

/// Wrapper that shows the actual charging map screen.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Leverage existing ChargingMapScreen so the map shows real content.
    return const ChargingMapScreen();
  }
}
