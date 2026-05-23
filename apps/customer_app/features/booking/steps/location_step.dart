import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../core/models/booking.dart';
import '../../../core/providers/booking_provider.dart';
import '../../../shared/widgets/primary_button.dart';

class LocationStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const LocationStep({super.key, required this.onNext});

  @override
  ConsumerState<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends ConsumerState<LocationStep> {
  final _addressCtrl = TextEditingController();
  bool _detecting = false;
  BookingLocation? _location;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(bookingFlowProvider).location;
    if (existing != null) {
      _location = existing;
      _addressCtrl.text = existing.address;
    }
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() => _detecting = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Location permission permanently denied. '
                    'Please enable in Settings.')),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      final place = placemarks.first;
      final address =
          '${place.street}, ${place.locality}, ${place.country}';

      setState(() {
        _location = BookingLocation(
          address: address,
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
        _addressCtrl.text = address;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not detect location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _detecting = false);
    }
  }

  void _useManualAddress() {
    final addr = _addressCtrl.text.trim();
    if (addr.isEmpty) return;
    // For manual entry without geocoding coordinates, use 0,0 as placeholder.
    // In production, geocode the address using geocoding package.
    setState(() {
      _location = BookingLocation(
        address: addr,
        latitude: 0,
        longitude: 0,
      );
    });
  }

  void _submit() {
    if (_location == null) return;
    ref.read(bookingFlowProvider.notifier).setLocation(_location!);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Where is your car?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('We\'ll come to you.',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 32),

          // Auto-detect
          OutlinedButton.icon(
            onPressed: _detecting ? null : _detectLocation,
            icon: _detecting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: Text(_detecting ? 'Detecting...' : 'Use My Current Location'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('or enter manually'),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _addressCtrl,
            decoration: InputDecoration(
              labelText: 'Street address',
              hintText: 'e.g. 123 Main St, City',
              prefixIcon: const Icon(Icons.location_on_outlined),
              suffixIcon: IconButton(
                icon: const Icon(Icons.check),
                onPressed: _useManualAddress,
              ),
            ),
            maxLines: 2,
            onChanged: (_) => setState(() => _location = null),
          ),

          if (_location != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _location!.address,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Spacer(),
          PrimaryButton(
            label: 'Continue',
            onPressed: _location != null ? _submit : null,
          ),
        ],
      ),
    );
  }
}
