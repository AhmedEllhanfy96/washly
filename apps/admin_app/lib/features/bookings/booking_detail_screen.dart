import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/booking.dart';
import '../../core/models/worker.dart';
import '../../core/providers/bookings_provider.dart';
import '../../core/services/booking_service.dart';
import '../../shared/widgets/status_badge.dart';

class BookingDetailScreen extends ConsumerWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(allBookingsProvider);
    final workers = ref.watch(workersProvider);
    final fmt = DateFormat('EEEE, MMMM d, yyyy • h:mm a');
    final l10n = context.l10n;

    return bookings.when(
      data: (list) {
        final booking =
            list.where((b) => b.id == bookingId).firstOrNull;
        if (booking == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.bookingNotFound)),
            body: Center(child: Text(l10n.bookingNotFound)),
          );
        }

        final lat =
            (booking.location['latitude'] as num?)?.toDouble() ?? 0;
        final lng =
            (booking.location['longitude'] as num?)?.toDouble() ?? 0;
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
              // Map
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
                                urlTemplate: AppConfig.osmTileUrl,
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
                    _Section(
                      title: l10n.customer,
                      icon: Icons.person,
                      children: [
                        _Row(l10n.name, booking.customerName),
                        if (booking.customerPhone.isNotEmpty)
                          _PhoneRow(
                            label: l10n.phone,
                            phone: booking.customerPhone,
                            l10n: l10n,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _Section(
                      title: l10n.car,
                      icon: Icons.directions_car,
                      children: [
                        _Row(l10n.vehicle, booking.carSummary),
                        _Row(l10n.plate,
                            booking.car['plateNumber'] as String? ?? ''),
                        if ((booking.car['color'] as String?)
                                ?.isNotEmpty ==
                            true)
                          _Row(l10n.color,
                              booking.car['color'] as String? ?? ''),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _Section(
                      title: l10n.service,
                      icon: Icons.cleaning_services,
                      children: [
                        _Row(l10n.type,
                            l10n.serviceTypeDetail(booking.serviceType)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _Section(
                      title: l10n.scheduleLabel,
                      icon: Icons.calendar_today,
                      children: [
                        _Row(l10n.dateTime,
                            fmt.format(booking.scheduledAt)),
                        _Row(l10n.slot, booking.timeSlot),
                        if (booking.assignedTo != null)
                          _Row(l10n.assignedTo, booking.assignedTo!),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _CopyMessageButton(
                        booking: booking, lat: lat, lng: lng),
                    const SizedBox(height: 20),

                    if (booking.status == BookingStatus.pending) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(l10n.actions,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                      const SizedBox(height: 12),
                      workers.when(
                        data: (list) => _AssignSection(
                          booking: booking,
                          workers: list,
                          ref: ref,
                        ),
                        loading: () =>
                            const CircularProgressIndicator(),
                        error: (_, __) =>
                            Text(l10n.couldNotLoadWorkers),
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
                        label: Text(l10n.rejectBooking,
                            style: const TextStyle(color: Colors.red)),
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
                        label: Text(l10n.markInProgress),
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
                        label: Text(l10n.markCompleted),
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

class _CopyMessageButton extends StatelessWidget {
  final AdminBooking booking;
  final double lat;
  final double lng;

  const _CopyMessageButton({
    required this.booking,
    required this.lat,
    required this.lng,
  });

  String _buildMessage(AppLocalizations l10n) {
    final fmt = DateFormat('EEEE, MMMM d, yyyy');
    final hasCoords = lat != 0 && lng != 0;
    final mapLink =
        hasCoords ? 'https://maps.google.com/?q=$lat,$lng' : null;
    final service = l10n.serviceTypeDetail(booking.serviceType);

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
    buffer.writeln(
        'Booking ID: #${booking.id.substring(0, 6).toUpperCase()}');
    return buffer.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return OutlinedButton.icon(
      onPressed: () async {
        final msg = _buildMessage(l10n);
        await Clipboard.setData(ClipboardData(text: msg));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(l10n.messageCopied),
                ],
              ),
              backgroundColor: Colors.green[700],
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      icon: const Icon(Icons.copy),
      label: Text(l10n.copyMessageForTeam),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _AssignSection extends StatefulWidget {
  final AdminBooking booking;
  final List<Worker> workers;
  final WidgetRef ref;

  const _AssignSection({
    required this.booking,
    required this.workers,
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
        SnackBar(
            content: Text(context.l10n.bookingConfirmedAssigned),
            backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (widget.workers.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(children: [
              Icon(Icons.warning_amber,
                  color: Colors.orange[700], size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(l10n.noWorkersYet,
                    style: const TextStyle(fontSize: 13)),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
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
            label: Text(l10n.approveWithoutAssigning),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52)),
          ),
        ],
      );
    }

    return Column(
      children: [
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: l10n.assignToWorker,
            prefixIcon: const Icon(Icons.engineering),
            border: const OutlineInputBorder(),
          ),
          value: _selected,
          items: widget.workers
              .map((w) => DropdownMenuItem(
                    value: w.id,
                    child: Row(children: [
                      const Icon(Icons.person, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(w.name),
                      if (w.phone.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text('· ${w.phone}',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 12)),
                      ],
                    ]),
                  ))
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
              : const Icon(Icons.send),
          label: Text(l10n.confirmAndAssign),
          style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52)),
        ),
      ],
    );
  }
}

class _PhoneRow extends StatelessWidget {
  final String label;
  final String phone;
  final AppLocalizations l10n;
  const _PhoneRow(
      {required this.label, required this.phone, required this.l10n});

  Future<void> _call() =>
      launchUrl(Uri.parse('tel:$phone'), mode: LaunchMode.externalApplication);

  Future<void> _whatsapp() {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return launchUrl(Uri.parse('${AppConfig.whatsAppUrl}$digits'),
        mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Expanded(
            child: Text(phone,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.green, size: 20),
            onPressed: _call,
            tooltip: l10n.callCustomer,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          IconButton(
            icon: const Icon(Icons.chat, color: Color(0xFF25D366), size: 20),
            onPressed: _whatsapp,
            tooltip: l10n.whatsappCustomer,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
        ],
      ),
    );
  }
}

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
            width: 100,
            child: Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
