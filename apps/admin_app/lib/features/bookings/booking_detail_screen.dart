import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../core/models/booking.dart';
import '../../core/models/team_member.dart';
import '../../core/providers/bookings_provider.dart';
import '../../core/services/booking_service.dart';
import '../../shared/widgets/status_badge.dart';

class BookingDetailScreen extends ConsumerWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(allBookingsProvider);
    final team = ref.watch(teamMembersProvider);
    final fmt = DateFormat('EEEE, MMMM d, yyyy • h:mm a');

    return bookings.when(
      data: (list) {
        final booking = list.where((b) => b.id == bookingId).firstOrNull;
        if (booking == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Booking')),
            body: const Center(child: Text('Booking not found')),
          );
        }

        final lat = (booking.location['latitude'] as num?)?.toDouble() ?? 0;
        final lng = (booking.location['longitude'] as num?)?.toDouble() ?? 0;
        final hasCoords = lat != 0 && lng != 0;

        return Scaffold(
          appBar: AppBar(
            title: Text('#${booking.id.substring(0, 6).toUpperCase()}'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: StatusBadge(status: booking.status),
              ),
            ],
          ),
          body: ListView(
            children: [
              // ── Map ───────────────────────────────────────────────────
              SizedBox(
                height: 220,
                child: hasCoords
                    ? Stack(
                        children: [
                          FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(lat, lng),
                              initialZoom: 15,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.pinchZoom |
                                    InteractiveFlag.drag,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.washly.admin',
                                maxZoom: 19,
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(lat, lng),
                                    width: 40,
                                    height: 40,
                                    child: const Icon(
                                      Icons.location_pin,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Address overlay at bottom of map
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              color: Colors.black54,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      color: Colors.white, size: 16),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      booking.address,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 13),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        color: Colors.grey[100],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_off,
                                size: 40, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(booking.address,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ── Customer ────────────────────────────────────────
                    _Section(
                      title: 'Customer',
                      icon: Icons.person,
                      children: [
                        _Row('Name', booking.customerName),
                        if (booking.customerPhone.isNotEmpty)
                          _Row('Phone', booking.customerPhone),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Car ─────────────────────────────────────────────
                    _Section(
                      title: 'Car',
                      icon: Icons.directions_car,
                      children: [
                        _Row('Vehicle', booking.carSummary),
                        _Row('Plate',
                            booking.car['plateNumber'] as String? ?? ''),
                        if ((booking.car['color'] as String?)?.isNotEmpty ==
                            true)
                          _Row('Color',
                              booking.car['color'] as String? ?? ''),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Service ─────────────────────────────────────────
                    _Section(
                      title: 'Service',
                      icon: Icons.cleaning_services,
                      children: [
                        _Row(
                          'Type',
                          booking.serviceType == ServiceType.fullService
                              ? 'Full Interior + Exterior — 250 EGP'
                              : 'Exterior Only — 195 EGP',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Schedule ────────────────────────────────────────
                    _Section(
                      title: 'Schedule',
                      icon: Icons.calendar_today,
                      children: [
                        _Row('Date & Time', fmt.format(booking.scheduledAt)),
                        _Row('Slot', booking.timeSlot),
                        if (booking.assignedTo != null)
                          _Row('Assigned to', booking.assignedTo!),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Copy message ─────────────────────────────────────
                    _CopyMessageButton(booking: booking, lat: lat, lng: lng),
                    const SizedBox(height: 20),

                    // ── Actions ─────────────────────────────────────────
                    if (booking.status == BookingStatus.pending) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Actions',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const SizedBox(height: 12),
                      team.when(
                        data: (members) => _AssignSection(
                          booking: booking,
                          teamMembers:
                              members.where((m) => m.isAvailable).toList(),
                          ref: ref,
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) =>
                            const Text('Could not load team'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await ref
                              .read(adminBookingServiceProvider)
                              .updateStatus(
                                  booking.id, BookingStatus.cancelled);
                          if (context.mounted) context.pop();
                        },
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        label: const Text('Reject Booking',
                            style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ],

                    if (booking.status == BookingStatus.confirmed)
                      ElevatedButton.icon(
                        onPressed: () async {
                          await ref
                              .read(adminBookingServiceProvider)
                              .updateStatus(
                                  booking.id, BookingStatus.inProgress);
                        },
                        icon: const Icon(Icons.local_car_wash),
                        label: const Text('Mark as In Progress'),
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52)),
                      ),

                    if (booking.status == BookingStatus.inProgress)
                      ElevatedButton.icon(
                        onPressed: () async {
                          await ref
                              .read(adminBookingServiceProvider)
                              .updateStatus(
                                  booking.id, BookingStatus.completed);
                          if (context.mounted) context.pop();
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Mark as Completed'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
                        ),
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

// ── Copy message button ───────────────────────────────────────────────────────

class _CopyMessageButton extends StatelessWidget {
  final AdminBooking booking;
  final double lat;
  final double lng;

  const _CopyMessageButton({
    required this.booking,
    required this.lat,
    required this.lng,
  });

  String _buildMessage() {
    final fmt = DateFormat('EEEE, MMMM d, yyyy');
    final hasCoords = lat != 0 && lng != 0;
    final mapLink = hasCoords
        ? 'https://maps.google.com/?q=$lat,$lng'
        : null;

    final service = booking.serviceType == ServiceType.fullService
        ? 'Full Interior + Exterior — 250 EGP'
        : 'Exterior Only — 195 EGP';

    final buffer = StringBuffer();
    buffer.writeln('🚗 Washly — New Booking');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln();
    buffer.writeln('👤 Customer: ${booking.customerName}');
    if (booking.customerPhone.isNotEmpty) {
      buffer.writeln('📞 Phone: ${booking.customerPhone}');
    }
    buffer.writeln();
    buffer.writeln('🚙 Car: ${booking.carSummary}');
    if ((booking.car['plateNumber'] as String?)?.isNotEmpty == true) {
      buffer.writeln('🔢 Plate: ${booking.car['plateNumber']}');
    }
    buffer.writeln();
    buffer.writeln('🧹 Service: $service');
    buffer.writeln();
    buffer.writeln('📍 Address: ${booking.address}');
    if (mapLink != null) {
      buffer.writeln('🗺️  Map: $mapLink');
    }
    buffer.writeln();
    buffer.writeln('📅 Date: ${fmt.format(booking.scheduledAt)}');
    buffer.writeln('⏰ Time: ${booking.timeSlot}');
    if (booking.assignedTo != null) {
      buffer.writeln();
      buffer.writeln('👷 Assigned to: ${booking.assignedTo}');
    }
    buffer.writeln();
    buffer.writeln('Booking ID: #${booking.id.substring(0, 6).toUpperCase()}');
    return buffer.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final msg = _buildMessage();
        await Clipboard.setData(ClipboardData(text: msg));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Message copied — paste it in WhatsApp or SMS'),
                ],
              ),
              backgroundColor: Colors.green[700],
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      icon: const Icon(Icons.copy),
      label: const Text('Copy Message for Team'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ── Assign section ────────────────────────────────────────────────────────────

class _AssignSection extends StatefulWidget {
  final AdminBooking booking;
  final List<TeamMember> teamMembers;
  final WidgetRef ref;

  const _AssignSection({
    required this.booking,
    required this.teamMembers,
    required this.ref,
  });

  @override
  State<_AssignSection> createState() => _AssignSectionState();
}

class _AssignSectionState extends State<_AssignSection> {
  String? _selected;
  bool _loading = false;

  Future<void> _assign() async {
    if (_selected == null) return;
    setState(() => _loading = true);
    await widget.ref
        .read(adminBookingServiceProvider)
        .assignTeamMember(widget.booking.id, _selected!);
    setState(() => _loading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Booking confirmed & assigned!'),
            backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.teamMembers.isEmpty) {
      return ElevatedButton.icon(
        onPressed: _loading
            ? null
            : () async {
                setState(() => _loading = true);
                await widget.ref
                    .read(adminBookingServiceProvider)
                    .updateStatus(
                        widget.booking.id, BookingStatus.confirmed);
                setState(() => _loading = false);
              },
        icon: const Icon(Icons.check),
        label: const Text('Approve Booking'),
        style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52)),
      );
    }

    return Column(
      children: [
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Assign to Team Member',
            prefixIcon: Icon(Icons.person_pin),
          ),
          value: _selected,
          items: widget.teamMembers
              .map((m) =>
                  DropdownMenuItem(value: m.id, child: Text(m.name)))
              .toList(),
          onChanged: (v) => setState(() => _selected = v),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: (_selected != null && !_loading) ? _assign : null,
          icon: _loading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.check),
          label: const Text('Confirm & Assign'),
          style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52)),
        ),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _Section(
      {required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary)),
              ],
            ),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Expanded(
              child: Text(value,
                  style:
                      const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
