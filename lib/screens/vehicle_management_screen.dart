import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vehicle.dart';
import '../providers/user_provider.dart';
import '../widgets/citysmart_scaffold.dart';

class VehicleManagementScreen extends StatelessWidget {
  const VehicleManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        if (provider.isInitializing) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final profile = provider.profile;
        if (profile == null) {
          return const CitySmartScaffold(
            title: 'Vehicles',
            currentIndex: 0,
            body: Center(
              child: Text('Sign in to manage vehicles.'),
            ),
          );
        }

        final vehicles = profile.vehicles;
        return CitySmartScaffold(
          title: 'My Vehicles',
          currentIndex: 0,
          body: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: vehicles.isEmpty ? 1 : vehicles.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (vehicles.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Sign in to manage vehicles.',
                    ),
                  ),
                );
              }
              final vehicle = vehicles[index];
              final isDefault =
                  profile.preferences.defaultVehicleId == vehicle.id;
              return Dismissible(
                key: ValueKey(vehicle.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Remove vehicle?'),
                          content: Text(
                            'Remove ${vehicle.nickname.isEmpty ? vehicle.licensePlate : vehicle.nickname}?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                },
                onDismissed: (_) => provider.removeVehicle(vehicle.id),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  color: Colors.redAccent,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: Card(
                  child: ListTile(
                    title: Text(
                      vehicle.nickname.isEmpty
                          ? vehicle.licensePlate
                          : vehicle.nickname,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${vehicle.color} ${vehicle.make} ${vehicle.model}\nPlate: ${vehicle.licensePlate}',
                    ),
                    isThreeLine: true,
                    trailing: Wrap(
                      direction: Axis.vertical,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () =>
                              _showVehicleSheet(context, provider, vehicle),
                        ),
                        if (isDefault)
                          const Text(
                            'Default',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showVehicleSheet(context, provider, null),
            label: const Text('Add Vehicle'),
            icon: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Future<void> _showVehicleSheet(
    BuildContext context,
    UserProvider provider,
    Vehicle? vehicle,
  ) async {
    final formKey = GlobalKey<FormState>();
    final nicknameController = TextEditingController(
      text: vehicle?.nickname ?? '',
    );
    final makeController = TextEditingController(text: vehicle?.make ?? '');
    final modelController = TextEditingController(text: vehicle?.model ?? '');
    final colorController = TextEditingController(text: vehicle?.color ?? '');
    final plateController = TextEditingController(
      text: vehicle?.licensePlate ?? '',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  vehicle == null ? 'Add vehicle' : 'Edit vehicle',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nicknameController,
                  decoration: const InputDecoration(
                    labelText: 'Nickname (optional)',
                  ),
                ),
                TextFormField(
                  controller: makeController,
                  decoration: const InputDecoration(labelText: 'Make'),
                  validator: (value) => value != null && value.isNotEmpty
                      ? null
                      : 'Provide a make',
                ),
                TextFormField(
                  controller: modelController,
                  decoration: const InputDecoration(labelText: 'Model'),
                  validator: (value) => value != null && value.isNotEmpty
                      ? null
                      : 'Provide a model',
                ),
                TextFormField(
                  controller: colorController,
                  decoration: const InputDecoration(labelText: 'Color'),
                ),
                TextFormField(
                  controller: plateController,
                  decoration: const InputDecoration(labelText: 'License Plate'),
                  validator: (value) => value != null && value.isNotEmpty
                      ? null
                      : 'Plate is required',
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    final newVehicle = Vehicle(
                      id:
                          vehicle?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      make: makeController.text.trim(),
                      model: modelController.text.trim(),
                      color: colorController.text.trim(),
                      licensePlate: plateController.text.trim(),
                      nickname: nicknameController.text.trim(),
                    );
                    if (vehicle == null) {
                      provider.addVehicle(newVehicle);
                    } else {
                      provider.updateVehicle(newVehicle);
                    }
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      vehicle == null ? 'Add vehicle' : 'Save changes',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
