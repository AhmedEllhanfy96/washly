import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/booking_provider.dart';
import '../../../shared/widgets/primary_button.dart';

class TimeSlotStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const TimeSlotStep({super.key, required this.onNext});

  @override
  ConsumerState<TimeSlotStep> createState() => _TimeSlotStepState();
}

class _TimeSlotStepState extends ConsumerState<TimeSlotStep> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedSlot;

  void _submit() {
    if (_selectedSlot == null) return;
    ref
        .read(bookingFlowProvider.notifier)
        .setSchedule(_selectedDate, _selectedSlot!);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final slots = ref.watch(availableSlotsProvider(_selectedDate));
    final dateFmt = DateFormat('EEE\nMMM d');
    final theme = Theme.of(context);

    return Column(
      children: [
        // ── Scrollable content ────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pick a Date & Time',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Each slot is a 2-hour service window.',
                    style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 24),

                // Date row
                SizedBox(
                  height: 72,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 14,
                    itemBuilder: (_, i) {
                      final day =
                          DateTime.now().add(Duration(days: i + 1));
                      final isSelected = _isSameDay(day, _selectedDate);
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedDate = day;
                          _selectedSlot = null;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 56,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.grey[100],
                          ),
                          child: Center(
                            child: Text(
                              dateFmt.format(day),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),
                const Text('Available Time Windows',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 12),

                // Slot cards
                slots.when(
                  data: (timeSlots) {
                    final bookable =
                        timeSlots.where((s) => s.isBookable).toList();
                    if (bookable.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(Icons.event_busy,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              const Text('No available slots for this day.',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: bookable.map((slot) {
                        final isSelected =
                            _selectedSlot == slot.startTime;
                        final spotsLeft =
                            slot.maxBookings - slot.currentBookings;
                        return GestureDetector(
                          onTap: () => setState(
                              () => _selectedSlot = slot.startTime),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : Colors.grey[300]!,
                                width: isSelected ? 2.5 : 1,
                              ),
                              color: isSelected
                                  ? theme.colorScheme.primaryContainer
                                      .withOpacity(0.3)
                                  : Colors.white,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : Colors.grey[100],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.access_time,
                                    size: 20,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        slot.displayLabel,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$spotsLeft spot${spotsLeft == 1 ? '' : 's'} left',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: spotsLeft <= 1
                                              ? Colors.orange
                                              : Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_circle,
                                      color: theme.colorScheme.primary),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(
                      child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  )),
                  error: (_, __) => const Text(
                      'Failed to load slots. Please try again.'),
                ),
              ],
            ),
          ),
        ),

        // ── Fixed bottom button ───────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: PrimaryButton(
            label: 'Continue',
            onPressed: _selectedSlot != null ? _submit : null,
          ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
