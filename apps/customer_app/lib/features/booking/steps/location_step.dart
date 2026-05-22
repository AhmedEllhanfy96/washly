import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/booking.dart';
import '../../../core/providers/booking_provider.dart';
import '../../../shared/widgets/primary_button.dart';

// Default center: Cairo, Egypt
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

  LatLng _center = _cairoCenter;
  bool _locating = false;
  bool _mapReady = false;

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
    super.dispose();
  }

  Future<void> _goToMyLocation() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Location denied. Move the map pin manually.')),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final point = LatLng(pos.latitude, pos.longitude);
      setState(() => _center = point);
      _mapController.move(point, 16);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              kIsWeb
                  ? 'Allow location in your browser, or drag the map pin manually.'
                  : 'Could not get GPS. Drag the pin manually.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _confirm() {
    final address = _addressCtrl.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your street address.')),
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
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // ── Instruction bar ──────────────────────────────────────────────
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
                  'Drag the map to move the pin to your exact location',
                  style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onPrimaryContainer),
                ),
              ),
            ],
          ),
        ),

        // ── Map ──────────────────────────────────────────────────────────
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
                      setState(() => _center = pos.center!);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.washly.customer',
                    maxZoom: 19,
                  ),
                ],
              ),

              // Fixed center pin
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_pin, color: Colors.red, size: 48),
                    SizedBox(height: 24), // offset shadow
                  ],
                ),
              ),

              // GPS button
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                ),
              ),

              // Coordinates chip
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

        // ── Address field + confirm ──────────────────────────────────────
        Container(
          color: theme.colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Confirm your street address',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  hintText:
                      'e.g. 15 شارع التحرير، المعادي، القاهرة',
                  prefixIcon: Icon(Icons.edit_location_alt_outlined),
                  isDense: true,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 14),
              PrimaryButton(label: 'Confirm Location', onPressed: _confirm),
            ],
          ),
        ),
      ],
    );
  }
}
