import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/l10n/app_localizations.dart';

const _cairoCenter = LatLng(30.0444, 31.2357);

// Height of the bottom confirm panel (label + field + button + padding)
const _panelHeight = 196.0;

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

class _SearchResult {
  final String displayName;
  final double lat;
  final double lon;
  const _SearchResult(
      {required this.displayName, required this.lat, required this.lon});
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
  State<MapLocationPickerScreen> createState() =>
      _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  final _mapController = MapController();
  final _addressCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  late LatLng _center;
  bool _locating = false;
  bool _mapReady = false;

  // Search state
  List<_SearchResult> _searchResults = [];
  bool _searchLoading = false;
  bool _showSearchResults = false;
  Timer? _debounce;

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
    _debounce?.cancel();
    _mapController.dispose();
    _addressCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _goToMyLocation() async {
    if (kIsWeb) {
      _showGpsError();
      return;
    }
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
      _showGpsError();
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _showGpsError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.couldNotGetGps)),
    );
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 3) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }
    setState(() => _searchLoading = true);
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      final results = await _nominatimSearch(query.trim());
      if (mounted) {
        setState(() {
          _searchResults = results;
          _searchLoading = false;
          _showSearchResults = results.isNotEmpty;
        });
      }
    });
  }

  Future<List<_SearchResult>> _nominatimSearch(String query) async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 6),
      ));
      final res = await dio.get<List<dynamic>>(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': '5',
          'countrycodes': 'eg',
          'accept-language': 'ar,en',
        },
        options: Options(headers: {'User-Agent': 'WashlyApp/1.0'}),
      );
      return (res.data ?? []).map((e) {
        final parts = (e['display_name'] as String).split(', ');
        final short = parts.take(3).join(', ');
        return _SearchResult(
          displayName: short,
          lat: double.parse(e['lat'] as String),
          lon: double.parse(e['lon'] as String),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  void _selectSearchResult(_SearchResult result) {
    final point = LatLng(result.lat, result.lon);
    setState(() {
      _center = point;
      _showSearchResults = false;
    });
    _searchCtrl.text = result.displayName;
    _addressCtrl.text = result.displayName;
    if (_mapReady) _mapController.move(point, 16);
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
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text(l10n.pickFromMap)),
      body: Stack(
        children: [
          // ── Column: instruction bar + map + placeholder ───────────────
          Column(
            children: [
              // Instruction strip
              Container(
                width: double.infinity,
                color: theme.colorScheme.primaryContainer,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.touch_app,
                        size: 16,
                        color: theme.colorScheme.onPrimaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(l10n.dragMapPin,
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onPrimaryContainer)),
                    ),
                  ],
                ),
              ),
              // Map with overlays inside its own Stack
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
                          userAgentPackageName: 'com.washly.admin',
                          maxZoom: 19,
                        ),
                      ],
                    ),

                    // Centre pin
                    const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_pin,
                              color: Colors.red, size: 48),
                          SizedBox(height: 24),
                        ],
                      ),
                    ),

                    // Search bar + results
                    Positioned(
                      top: 10,
                      left: 10,
                      right: 10,
                      child: Column(
                        children: [
                          Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(12),
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: _onSearchChanged,
                              onTap: () => setState(() =>
                                  _showSearchResults =
                                      _searchResults.isNotEmpty),
                              decoration: InputDecoration(
                                hintText: l10n.searchLocation,
                                prefixIcon: _searchLoading
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        ),
                                      )
                                    : const Icon(Icons.search),
                                suffixIcon: _searchCtrl.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close,
                                            size: 18),
                                        onPressed: () {
                                          _searchCtrl.clear();
                                          setState(() {
                                            _searchResults = [];
                                            _showSearchResults = false;
                                          });
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: Colors.white,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          if (_showSearchResults &&
                              _searchResults.isNotEmpty)
                            Material(
                              elevation: 6,
                              borderRadius: BorderRadius.circular(12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: _searchResults.length,
                                  separatorBuilder: (_, __) => const Divider(
                                      height: 1,
                                      indent: 16,
                                      endIndent: 16),
                                  itemBuilder: (_, i) {
                                    final r = _searchResults[i];
                                    return ListTile(
                                      dense: true,
                                      leading: Icon(Icons.location_on,
                                          color: theme.colorScheme.primary,
                                          size: 20),
                                      title: Text(r.displayName,
                                          style: const TextStyle(
                                              fontSize: 13)),
                                      onTap: () =>
                                          _selectSearchResult(r),
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Coords badge
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_center.latitude.toStringAsFixed(4)}, '
                          '${_center.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ),

                    // GPS button
                    if (!kIsWeb)
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: FloatingActionButton.small(
                          heroTag: 'admin_gps',
                          onPressed: _locating ? null : _goToMyLocation,
                          tooltip: 'My location',
                          child: _locating
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : const Icon(Icons.my_location),
                        ),
                      ),
                  ],
                ),
              ),
              // Placeholder so the pin sits above the bottom panel
              SizedBox(height: keyboardHeight > 0 ? 0 : _panelHeight),
            ],
          ),

          // ── Bottom confirm panel (floats above keyboard) ──────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: keyboardHeight,
            child: Container(
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
                      prefixIcon:
                          const Icon(Icons.edit_location_alt_outlined),
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
          ),
        ],
      ),
    );
  }
}
