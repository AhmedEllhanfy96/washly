import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/models/booking.dart';
import '../../../core/models/saved_location.dart';
import '../../../core/providers/booking_provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/services/profile_service.dart';
import '../../../shared/widgets/primary_button.dart';

const _cairoCenter = LatLng(30.0444, 31.2357);

class LocationStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const LocationStep({super.key, required this.onNext});

  @override
  ConsumerState<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends ConsumerState<LocationStep> {
  final _mapController = MapController();
  final _addressCtrl = TextEditingController();
  final _labelCtrl = TextEditingController(text: 'Home');

  LatLng _center = _cairoCenter;
  bool _locating = false;
  bool _mapReady = false;
  bool _saveLocation = false;
  String? _selectedSavedLocationId;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(bookingFlowProvider).location;
    if (existing != null && existing.latitude != 0) {
      _center = LatLng(existing.latitude, existing.longitude);
      _addressCtrl.text = existing.address;
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _addressCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  void _selectSavedLocation(SavedLocation loc) {
    setState(() {
      _selectedSavedLocationId = loc.id;
      _center = LatLng(loc.latitude, loc.longitude);
      _saveLocation = false;
    });
    _addressCtrl.text = loc.address;
    if (_mapReady) _mapController.move(_center, 15);
  }

  Future<void> _deleteSavedLocation(String id) async {
    await ref.read(profileServiceProvider).deleteLocation(id);
    ref.invalidate(savedLocationsProvider);
    if (_selectedSavedLocationId == id) {
      setState(() => _selectedSavedLocationId = null);
    }
  }

  Future<void> _goToMyLocation() async {
    setState(() => _locating = true);
    try {
      // On web, skip the explicit permission check — it can return deniedForever
      // on browsers that don't support the Permissions API (Safari, Firefox).
      // Let getCurrentPosition() trigger the browser's native prompt directly.
      if (!kIsWeb) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.deniedForever) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.locationDenied)),
            );
          }
          return;
        }
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final point = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _center = point;
        _selectedSavedLocationId = null;
      });
      _mapController.move(point, 16);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              kIsWeb ? context.l10n.locationDeniedBrowser : context.l10n.couldNotGetGps,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _confirm() async {
    final l10n = context.l10n;
    final address = _addressCtrl.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterStreetAddress)),
      );
      return;
    }
    ref.read(bookingFlowProvider.notifier).setLocation(
          BookingLocation(
            address: address,
            latitude: _center.latitude,
            longitude: _center.longitude,
          ),
        );

    if (_saveLocation && _selectedSavedLocationId == null) {
      final label = _labelCtrl.text.trim().isEmpty ? 'Home' : _labelCtrl.text.trim();
      try {
        await ref.read(profileServiceProvider).saveLocation(
              label: label,
              address: address,
              latitude: _center.latitude,
              longitude: _center.longitude,
            );
        ref.invalidate(savedLocationsProvider);
      } catch (_) {}
    }

    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final savedLocsAsync = ref.watch(savedLocationsProvider);
    final l10n = context.l10n;

    return Column(
      children: [
        // Instruction bar
        Container(
          width: double.infinity,
          color: theme.colorScheme.primaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.touch_app,
                  size: 18, color: theme.colorScheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.dragMapPin,
                  style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onPrimaryContainer),
                ),
              ),
            ],
          ),
        ),

        // Map
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: 14,
                  onMapReady: () => setState(() => _mapReady = true),
                  onPositionChanged: (pos, _) {
                    if (pos.center != null) {
                      setState(() {
                        _center = pos.center!;
                        _selectedSavedLocationId = null;
                      });
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.washly.customer',
                    maxZoom: 19,
                  ),
                ],
              ),
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_pin, color: Colors.red, size: 48),
                    SizedBox(height: 24),
                  ],
                ),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: FloatingActionButton.small(
                  heroTag: 'gps',
                  onPressed: _locating ? null : _goToMyLocation,
                  tooltip: 'My location',
                  child: _locating
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location),
                ),
              ),
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_center.latitude.toStringAsFixed(4)}, '
                    '${_center.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom panel
        Container(
          color: theme.colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              savedLocsAsync.when(
                data: (locs) {
                  if (locs.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.savedLocations,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: locs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final loc = locs[i];
                            final selected =
                                _selectedSavedLocationId == loc.id;
                            return GestureDetector(
                              onLongPress: () => _deleteSavedLocation(loc.id),
                              child: FilterChip(
                                label: Text(loc.label),
                                selected: selected,
                                avatar: Icon(
                                  loc.label.toLowerCase().contains('work')
                                      ? Icons.work_outline
                                      : Icons.home_outlined,
                                  size: 16,
                                ),
                                onSelected: (_) =>
                                    _selectSavedLocation(loc),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(l10n.longPressToDelete,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500])),
                      const SizedBox(height: 10),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              Text(l10n.confirmStreetAddress,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _addressCtrl,
                decoration: InputDecoration(
                  hintText: l10n.addressHint,
                  prefixIcon: const Icon(Icons.edit_location_alt_outlined),
                  isDense: true,
                ),
                maxLines: 2,
                onChanged: (_) =>
                    setState(() => _selectedSavedLocationId = null),
              ),

              if (_selectedSavedLocationId == null) ...[
                const SizedBox(height: 6),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _saveLocation,
                  onChanged: (v) =>
                      setState(() => _saveLocation = v ?? false),
                  title: Text(l10n.saveThisLocation,
                      style: const TextStyle(fontSize: 14)),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                ),
                if (_saveLocation)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: TextField(
                      controller: _labelCtrl,
                      decoration: InputDecoration(
                        hintText: l10n.locationLabel,
                        isDense: true,
                        prefixIcon:
                            const Icon(Icons.label_outline, size: 18),
                      ),
                    ),
                  ),
              ],

              const SizedBox(height: 12),
              PrimaryButton(
                  label: l10n.confirmLocation, onPressed: _confirm),
            ],
          ),
        ),
      ],
    );
  }
}
