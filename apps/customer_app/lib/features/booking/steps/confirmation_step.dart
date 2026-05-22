import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/booking.dart';
import '../../../core/models/time_slot.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/booking_provider.dart';
import '../../../core/services/booking_service.dart';
import '../../../shared/widgets/primary_button.dart';

class ConfirmationStep extends ConsumerStatefulWidget {
  final VoidCallback onConfirmed;
  const ConfirmationStep({super.key, required this.onConfirmed});

  @override
  ConsumerState<ConfirmationStep> createState() => _ConfirmationStepState();
}

class _ConfirmationStepState extends ConsumerState<ConfirmationStep> {
  bool _loading = false;

  Future<void> _confirm() async {
    final flow = ref.read(bookingFlowProvider);
    if (!flow.isComplete) return;

    setState(() => _loading = true);
    try {
      final user = ref.read(authProvider).valueOrNull;
      final booking = Booking(
        id: '',
        userId: user?.id ?? '',
        car: flow.car!,
        serviceType: flow.serviceType!,
        location: flow.location!,
        scheduledAt: flow.selectedDate!,
        timeSlot: flow.selectedTimeSlot!,
        status: BookingStatus.pending,
        createdAt: DateTime.now(),
      );
      await ref.read(bookingServiceProvider).createBooking(
            booking: booking,
            customerName: user?.name ?? '',
            customerPhone: user?.phone ?? '',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking submitted! We\'ll confirm shortly.'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onConfirmed();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to submit: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(bookingFlowProvider);
    final fmt = DateFormat('EEEE, MMMM d, yyyy');
    final timeFmt = DateFormat('h:mm a');

    return Column(
      children: [
        // Scrollable summary
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Confirm Booking',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Review your booking before submitting.',
                    style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 24),

                _Section(title: 'Car Details', children: [
                  _Row('Make & Model',
                      '${flow.car?.make ?? ''} ${flow.car?.model ?? ''}'),
                  _Row('Color', flow.car?.color ?? ''),
                  _Row('Plate', flow.car?.plateNumber ?? ''),
                  if (flow.car?.year != null) _Row('Year', flow.car!.year!),
                ]),

                const SizedBox(height: 16),
                _Section(title: 'Service', children: [
                  _Row(
                    'Type',
                    flow.serviceType == ServiceType.fullService
                        ? 'Full Interior + Exterior'
                        : 'Exterior Only',
                  ),
                  _Row(
                    'Price',
                    flow.serviceType == ServiceType.fullService
                        ? '250 EGP'
                        : '195 EGP',
                  ),
                ]),

                const SizedBox(height: 16),
                _Section(title: 'Location', children: [
                  _Row('Address', flow.location?.address ?? ''),
                ]),

                const SizedBox(height: 16),
                _Section(title: 'Schedule', children: [
                  if (flow.selectedDate != null)
                    _Row('Date', fmt.format(flow.selectedDate!)),
                  if (flow.selectedTimeSlot != null)
                    _Row(
                      'Window',
                      TimeSlot(
                        startTime: flow.selectedTimeSlot!,
                        endTime:
                            TimeSlot.addTwoHours(flow.selectedTimeSlot!),
                        available: true,
                        maxBookings: 3,
                        currentBookings: 0,
                      ).displayLabel,
                    ),
                ]),
              ],
            ),
          ),
        ),

        // Fixed submit button
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: PrimaryButton(
            label: 'Submit Booking',
            onPressed: _confirm,
            isLoading: _loading,
            icon: Icons.check,
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 8),
          ...children,
        ],
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
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
