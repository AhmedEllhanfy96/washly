import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

        return Scaffold(
          appBar: AppBar(
            title: const Text('Booking Detail'),
            actions: [
              StatusBadge(status: booking.status),
              const SizedBox(width: 12),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Customer info
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

              _Section(
                title: 'Car',
                icon: Icons.directions_car,
                children: [
                  _Row('Vehicle', booking.carSummary),
                  _Row('Plate', booking.car['plateNumber'] ?? ''),
                ],
              ),
              const SizedBox(height: 12),

              _Section(
                title: 'Service',
                icon: Icons.cleaning_services,
                children: [
                  _Row(
                    'Type',
                    booking.serviceType == ServiceType.fullService
                        ? 'Full Interior + Exterior'
                        : 'Exterior Only',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _Section(
                title: 'Location',
                icon: Icons.location_on,
                children: [_Row('Address', booking.address)],
              ),
              const SizedBox(height: 12),

              _Section(
                title: 'Schedule',
                icon: Icons.calendar_today,
                children: [
                  _Row('Date & Time', fmt.format(booking.scheduledAt)),
                  _Row('Slot', booking.timeSlot),
                ],
              ),
              const SizedBox(height: 24),

              // Action buttons
              if (booking.status == BookingStatus.pending) ...[
                const Text('Actions',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),

                // Assign & confirm
                team.when(
                  data: (members) {
                    final available =
                        members.where((m) => m.isAvailable).toList();
                    return _AssignSection(
                        booking: booking, teamMembers: available, ref: ref);
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Could not load team'),
                ),
                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: () async {
                    await ref
                        .read(adminBookingServiceProvider)
                        .updateStatus(booking.id, BookingStatus.cancelled);
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
                        .updateStatus(booking.id, BookingStatus.inProgress);
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
                        .updateStatus(booking.id, BookingStatus.completed);
                    if (context.mounted) context.pop();
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Mark as Completed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 52),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Assign to Team Member',
            prefixIcon: Icon(Icons.person_pin),
          ),
          value: _selected,
          items: widget.teamMembers
              .map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))
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
                    size: 18, color: Theme.of(context).colorScheme.primary),
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
              child:
                  Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
