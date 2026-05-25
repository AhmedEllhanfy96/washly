import 'dart:async';

import 'package:dio/dio.dart';
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

class _SearchResult {
  final String displayName;
  final double lat;
  final double lon;
  const _SearchResult(
      {required this.displayName, required this.lat, required this.lon});
}

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
  final _searchCtrl = TextEditingController();

  LatLng _center = _cairoCenter;
  bool _locating = false;
  bool _mapReady = false;
  bool _saveLocation = false;
  String? _selectedSavedLocationId;
  bool _showNewAddressForm = false;

  // Search state
  List<_SearchResult> _searchResults = [];
  bool _searchLoading = false;
  bool _showSearchResults = false;
  Timer? _debounce;

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
    _debounce?.cancel();
    _mapController.dispose();
    _addressCtrl.dispose();
    _labelCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _selectSavedLocation(SavedLocation loc) {
    setState(() {
      _selectedSavedLocationId = loc.id;
      _center = LatLng(loc.latitude, loc.longitude);
      _saveLocation = false;
      _showNewAddressForm = false;
      _showSearchResults = false;
    });
    _addressCtrl.text = loc.address;
    _searchCtrl.clear();
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
      if (kIsWeb) {
        // Chrome blocks geolocation on HTTP (non-localhost)
        final base = Uri.base;
        final secure = base.scheme == 'https' ||
            base.host == 'localhost' ||
            base.host == '127.0.0.1';
        if (!secure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.locationRequiresHttps)),
            );
          }
          return;
        }
      } else {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.locationServiceDisabled)),
            );
          }
          return;
        }
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.locationDenied)),
            );
          }
          return;
        }
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy:
            kIsWeb ? LocationAccuracy.medium : LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      final point = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _center = point;
        _selectedSavedLocationId = null;
        _showNewAddressForm = true;
      });
      _mapController.move(point, 16);
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotGetGps)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(kIsWeb
                ? context.l10n.locationDeniedBrowser
                : context.l10n.couldNotGetGps),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
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
        options: Options(
          headers: {'User-Agent': 'WashlyApp/1.0'},
        ),
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
      _selectedSavedLocationId = null;
      _showSearchResults = false;
      _showNewAddressForm = true;
    });
    _searchCtrl.text = result.displayName;
    _addressCtrl.text = result.displayName;
    if (_mapReady) _mapController.move(point, 16);
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
      final label =
          _labelCtrl.text.trim().isEmpty ? 'Home' : _labelCtrl.text.trim();
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
        // ── Map ────────────────────────────────────────────────────────────
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
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.washly.customer',
                    maxZoom: 19,
                  ),
                ],
              ),

              // Centre pin
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_pin, color: Colors.red, size: 48),
                    SizedBox(height: 24),
                  ],
                ),
              ),

              // ── Search bar ─────────────────────────────────────────────
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
                        onTap: () => setState(() => _showSearchResults =
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
                                  icon: const Icon(Icons.close, size: 18),
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

                    // Search results dropdown
                    if (_showSearchResults && _searchResults.isNotEmpty)
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
                                height: 1, indent: 16, endIndent: 16),
                            itemBuilder: (_, i) {
                              final r = _searchResults[i];
                              return ListTile(
                                dense: true,
                                leading: Icon(Icons.location_on,
                                    color:
                                        theme.colorScheme.primary, size: 20),
                                title: Text(r.displayName,
                                    style: const TextStyle(fontSize: 13)),
                                onTap: () => _selectSearchResult(r),
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
                    style:
                        const TextStyle(color: Colors.white, fontSize: 11),
                  ),
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
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location),
                ),
              ),
            ],
          ),
        ),

        // ── Bottom panel ──────────────────────────────────────────────────
        Container(
          color: theme.colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Saved locations chips
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
                              onLongPress: () =>
                                  _deleteSavedLocation(loc.id),
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

              // When saved location is selected and not entering new address
              if (_selectedSavedLocationId != null && !_showNewAddressForm)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _addressCtrl.text,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedSavedLocationId = null;
                          _showNewAddressForm = true;
                        });
                        _addressCtrl.clear();
                      },
                      icon: const Icon(Icons.edit_location_alt, size: 16),
                      label: Text(l10n.useDifferentAddress,
                          style: const TextStyle(fontSize: 13)),
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    ),
                    const SizedBox(height: 12),
                  ],
                )
              else ...[
                // Address text field (new address entry or no saved locations)
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
                    isDense: true,
                  ),
                  maxLines: 2,
                  onChanged: (_) => setState(
                      () => _selectedSavedLocationId = null),
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
              ],

              PrimaryButton(
                  label: l10n.confirmLocation, onPressed: _confirm),
            ],
          ),
        ),
      ],
    );
  }
}
