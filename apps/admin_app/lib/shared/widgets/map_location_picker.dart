import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/l10n/app_localizations.dart';

const _cairoCenter = LatLng(30.0444, 31.2357);

class LocationPickResult {
  final String address;
  final double latitude;
  final double longitude;
  const LocationPickResult({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

/// Full-screen map picker. Push with Navigator.push and await the result.
/// Returns [LocationPickResult] or null if cancelled.
class MapLocationPickerScreen extends StatefulWidget {
  final String? initialAddress;
  final double? initialLat;
  final double? initialLng;

  const MapLocationPickerScreen({
    super.key,
    this.initialAddress,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<MapLocationPickerScreen> createState() => _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  final _mapController = MapController();
  final _addressCtrl = TextEditingController();

  late LatLng _center;
  bool _locating = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    final hasCoords = widget.initialLat != null &&
        widget.initialLat != 0 &&
        widget.initialLng != null &&
        widget.initialLng != 0;
    _center = hasCoords
        ? LatLng(widget.initialLat!, widget.initialLng!)
        : _cairoCenter;
    _addressCtrl.text = widget.initialAddress ?? '';
  }

  @override
  void dispose() {
    _mapController.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _goToMyLocation() async {
    final l10n = context.l10n;
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.locationDenied)),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final point = LatLng(pos.latitude, pos.longitude);
      setState(() => _center = point);
      if (_mapReady) _mapController.move(point, 16);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(kIsWeb
                ? context.l10n.locationDenied
                : context.l10n.couldNotGetGps),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _confirm() {
    final l10n = context.l10n;
    final address = _addressCtrl.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterStreetAddress)),
      );
      return;
    }
    Navigator.pop(
      context,
      LocationPickResult(
        address: address,
        latitude: _center.latitude,
        longitude: _center.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pickFromMap),
        actions: [
          TextButton(
            onPressed: _confirm,
            child: Text(l10n.confirmLocation,
                style: TextStyle(color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: theme.colorScheme.primaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.touch_app, size: 18,
                    color: theme.colorScheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(l10n.dragMapPin,
                      style: TextStyle(fontSize: 13,
                          color: theme.colorScheme.onPrimaryContainer)),
                ),
              ],
            ),
          ),

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
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.washly.admin',
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
                      SizedBox(height: 24),
                    ],
                  ),
                ),
                // GPS button
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: FloatingActionButton.small(
                    heroTag: 'admin_gps',
                    onPressed: _locating ? null : _goToMyLocation,
                    tooltip: 'My location',
                    child: _locating
                        ? const SizedBox(
                            height: 18, width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location),
                  ),
                ),
                // Coordinate display
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

          // Address input
          Container(
            color: theme.colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.confirmStreetAddress,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _addressCtrl,
                  decoration: InputDecoration(
                    hintText: l10n.addressHint,
                    prefixIcon: const Icon(Icons.edit_location_alt_outlined),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _confirm,
                    icon: const Icon(Icons.check),
                    label: Text(l10n.confirmLocation,
                        style: const TextStyle(fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
