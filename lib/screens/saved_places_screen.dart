import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/saved_place.dart';
import '../services/analytics_service.dart';
import '../services/location_service.dart';
import '../services/saved_places_service.dart';
import '../theme/app_theme.dart';
import '../widgets/citysmart_scaffold.dart';

/// Screen for managing saved places (home, work, favorites)
/// 
/// Features:
/// - Add/edit/delete places
/// - Quick set from current location
/// - Map picker integration (future)
/// - Notification settings per place
class SavedPlacesScreen extends StatelessWidget {
  const SavedPlacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CitySmartScaffold(
      title: 'Saved Places',
      currentIndex: -1, // Not in bottom nav
      body: _SavedPlacesBody(),
    );
  }
}

class _SavedPlacesBody extends StatefulWidget {
  const _SavedPlacesBody();

  @override
  State<_SavedPlacesBody> createState() => _SavedPlacesBodyState();
}

class _SavedPlacesBodyState extends State<_SavedPlacesBody> {
  final SavedPlacesService _service = SavedPlacesService.instance;
  List<SavedPlace> _places = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView('SavedPlacesScreen');
    _loadPlaces();
    
    // Listen to changes
    _service.placesStream.listen((places) {
      if (mounted) {
        setState(() => _places = places);
      }
    });
  }

  Future<void> _loadPlaces() async {
    setState(() => _loading = true);
    await _service.initialize();
    setState(() {
      _places = _service.places;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadPlaces,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Home & Work section
          _SectionHeader(title: 'Primary Locations'),
          const SizedBox(height: 12),
          _PrimaryPlaceCard(
            type: PlaceType.home,
            place: _service.home,
            onEdit: () => _showPlaceEditor(context, PlaceType.home, _service.home),
          ),
          const SizedBox(height: 12),
          _PrimaryPlaceCard(
            type: PlaceType.work,
            place: _service.work,
            onEdit: () => _showPlaceEditor(context, PlaceType.work, _service.work),
          ),
          
          const SizedBox(height: 24),
          
          // Favorites section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionHeader(title: 'Favorites'),
              IconButton(
                onPressed: () => _showPlaceEditor(context, PlaceType.favorite, null),
                icon: const Icon(Icons.add_circle_outline),
                color: kCitySmartYellow,
                tooltip: 'Add favorite',
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (_service.favorites.isEmpty)
            _EmptyFavoritesCard(
              onAdd: () => _showPlaceEditor(context, PlaceType.favorite, null),
            )
          else
            ...List.generate(_service.favorites.length, (i) {
              final place = _service.favorites[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _FavoriteCard(
                  place: place,
                  onEdit: () => _showPlaceEditor(context, PlaceType.favorite, place),
                  onDelete: () => _confirmDelete(context, place),
                ),
              );
            }),
          
          const SizedBox(height: 80), // Bottom padding for FAB
        ],
      ),
    );
  }

  void _showPlaceEditor(BuildContext context, PlaceType type, SavedPlace? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCitySmartGreen,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PlaceEditorSheet(
        type: type,
        existing: existing,
        onSave: (name, nickname, lat, lon, address, radius, notifications) async {
          Navigator.pop(ctx);
          
          if (existing != null) {
            await _service.updatePlace(
              existing.id,
              name: name,
              nickname: nickname,
              latitude: lat,
              longitude: lon,
              address: address,
              notifyRadiusMiles: radius,
              notificationsEnabled: notifications,
            );
          } else {
            await _service.addPlace(
              name: name,
              nickname: nickname,
              type: type,
              latitude: lat,
              longitude: lon,
              address: address,
              notifyRadiusMiles: radius,
              notificationsEnabled: notifications,
            );
          }
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(existing != null ? 'Place updated' : 'Place saved'),
                backgroundColor: Colors.green.shade700,
              ),
            );
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, SavedPlace place) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCitySmartGreen,
        title: const Text('Delete Place?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove "${place.displayName}" from your saved places?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _service.deletePlace(place.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${place.displayName} removed'),
                    backgroundColor: Colors.orange.shade700,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ==================== Section Header ====================

class _SectionHeader extends StatelessWidget {
  final String title;
  
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: kCitySmartYellow,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

// ==================== Primary Place Card (Home/Work) ====================

class _PrimaryPlaceCard extends StatelessWidget {
  final PlaceType type;
  final SavedPlace? place;
  final VoidCallback onEdit;

  const _PrimaryPlaceCard({
    required this.type,
    required this.place,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final icon = type == PlaceType.home ? Icons.home : Icons.work;
    final label = type == PlaceType.home ? 'Home' : 'Work';
    final isSet = place != null;

    return Card(
      color: kCitySmartGreen.withValues(alpha: 0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSet ? kCitySmartYellow.withValues(alpha: 0.5) : Colors.white24,
        ),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSet
                      ? kCitySmartYellow.withValues(alpha: 0.2)
                      : Colors.white12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSet ? kCitySmartYellow : Colors.white54,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isSet ? kCitySmartYellow : Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isSet
                          ? (place!.address ?? '${place!.latitude.toStringAsFixed(4)}, ${place!.longitude.toStringAsFixed(4)}')
                          : 'Tap to set your $label location',
                      style: TextStyle(
                        color: isSet ? Colors.white70 : Colors.white38,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isSet && place!.notificationsEnabled) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.notifications_active, size: 14, color: kCitySmartYellow.withValues(alpha: 0.7)),
                          const SizedBox(width: 4),
                          Text(
                            'Alerts within ${place!.notifyRadiusMiles} mi',
                            style: TextStyle(
                              color: kCitySmartYellow.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                isSet ? Icons.edit : Icons.add_location_alt,
                color: Colors.white38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== Favorite Card ====================

class _FavoriteCard extends StatelessWidget {
  final SavedPlace place;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FavoriteCard({
    required this.place,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(place.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // Handle delete in callback
      },
      child: Card(
        color: kCitySmartGreen.withValues(alpha: 0.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white12),
        ),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('⭐', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (place.address != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          place.address!,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (place.notificationsEnabled)
                  Icon(Icons.notifications_active, size: 16, color: kCitySmartYellow.withValues(alpha: 0.5)),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.white38),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== Empty Favorites Card ====================

class _EmptyFavoritesCard extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyFavoritesCard({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kCitySmartGreen.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white12, style: BorderStyle.solid),
      ),
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.star_border, size: 40, color: Colors.white38),
              const SizedBox(height: 12),
              const Text(
                'No favorites yet',
                style: TextStyle(color: Colors.white54, fontSize: 15),
              ),
              const SizedBox(height: 4),
              const Text(
                'Save your frequently visited spots',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Favorite'),
                style: TextButton.styleFrom(
                  foregroundColor: kCitySmartYellow,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== Place Editor Sheet ====================

class _PlaceEditorSheet extends StatefulWidget {
  final PlaceType type;
  final SavedPlace? existing;
  final Function(String name, String? nickname, double lat, double lon, String? address, double radius, bool notifications) onSave;

  const _PlaceEditorSheet({
    required this.type,
    required this.existing,
    required this.onSave,
  });

  @override
  State<_PlaceEditorSheet> createState() => _PlaceEditorSheetState();
}

class _PlaceEditorSheetState extends State<_PlaceEditorSheet> {
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _addressController = TextEditingController();
  double _latitude = 43.0389; // Milwaukee default
  double _longitude = -87.9065;
  double _notifyRadius = 0.5;
  bool _notificationsEnabled = true;
  bool _loading = false;
  bool _locationSet = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameController.text = widget.existing!.name;
      _nicknameController.text = widget.existing!.nickname ?? '';
      _addressController.text = widget.existing!.address ?? '';
      _latitude = widget.existing!.latitude;
      _longitude = widget.existing!.longitude;
      _notifyRadius = widget.existing!.notifyRadiusMiles;
      _notificationsEnabled = widget.existing!.notificationsEnabled;
      _locationSet = true;
    } else {
      // Default name based on type
      _nameController.text = widget.type == PlaceType.home
          ? 'Home'
          : widget.type == PlaceType.work
              ? 'Work'
              : '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _loading = true);
    
    try {
      final position = await LocationService().getCurrentPosition();
      if (position != null) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _locationSet = true;
        });
        
        // Try to get address (reverse geocode would go here in full implementation)
        // For now, just show coordinates
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location set to current position')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get location: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
    
    setState(() => _loading = false);
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }
    
    if (!_locationSet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set a location')),
      );
      return;
    }

    widget.onSave(
      name,
      _nicknameController.text.trim().isEmpty ? null : _nicknameController.text.trim(),
      _latitude,
      _longitude,
      _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      _notifyRadius,
      _notificationsEnabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    final typeLabel = widget.type == PlaceType.home
        ? 'Home'
        : widget.type == PlaceType.work
            ? 'Work'
            : 'Favorite';
    final isEditing = widget.existing != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(20),
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Title
          Text(
            isEditing ? 'Edit $typeLabel' : 'Add $typeLabel',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Name field
          _buildTextField(
            controller: _nameController,
            label: 'Name',
            hint: 'e.g., My $typeLabel',
            icon: Icons.label_outline,
          ),
          const SizedBox(height: 16),
          
          // Nickname (optional)
          if (widget.type == PlaceType.favorite) ...[
            _buildTextField(
              controller: _nicknameController,
              label: 'Nickname (optional)',
              hint: 'Short display name',
              icon: Icons.edit_outlined,
            ),
            const SizedBox(height: 16),
          ],
          
          // Address field
          _buildTextField(
            controller: _addressController,
            label: 'Address (optional)',
            hint: 'Street address',
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 16),
          
          // Location picker
          Card(
            color: Colors.white10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Location',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  if (_locationSet)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kCitySmartYellow.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kCitySmartYellow.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: kCitySmartYellow, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_latitude.toStringAsFixed(5)}, ${_longitude.toStringAsFixed(5)}',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const Text(
                      'No location set',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _useCurrentLocation,
                      icon: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(_loading ? 'Getting location...' : 'Use Current Location'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kCitySmartYellow,
                        side: BorderSide(color: kCitySmartYellow.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Notification settings
          Card(
            color: Colors.white10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Parking Alerts',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Switch(
                        value: _notificationsEnabled,
                        onChanged: (v) => setState(() => _notificationsEnabled = v),
                        activeColor: kCitySmartYellow,
                      ),
                    ],
                  ),
                  if (_notificationsEnabled) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Alert radius: ${_notifyRadius.toStringAsFixed(1)} miles',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    Slider(
                      value: _notifyRadius,
                      min: 0.1,
                      max: 2.0,
                      divisions: 19,
                      label: '${_notifyRadius.toStringAsFixed(1)} mi',
                      activeColor: kCitySmartYellow,
                      onChanged: (v) => setState(() => _notifyRadius = v),
                    ),
                    const Text(
                      'Get notified about parking enforcement and tow trucks near this location',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Save button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: kCitySmartYellow,
                foregroundColor: kCitySmartGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isEditing ? 'Update Place' : 'Save Place',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white54),
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(icon, color: Colors.white38),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kCitySmartYellow.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}
