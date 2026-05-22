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

  List<DateTime> _next14Days() {
    final today = DateTime.now();
    return List.generate(14, (i) => today.add(Duration(days: i + 1)));
  }

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
    final fmt = DateFormat('EEE\nMMMd');
    final timeFmt = DateFormat('h:mm a');

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pick a Date & Time',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Choose when you\'d like us to come.',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),

          // Date picker row
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 14,
              itemBuilder: (_, i) {
                final day = _next14Days()[i];
                final isSelected = _isSameDay(day, _selectedDate);
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedDate = day;
                    _selectedSlot = null;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 58,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[100],
                    ),
                    child: Center(
                      child: Text(
                        fmt.format(day),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),
          const Text('Available Time Slots',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 12),

          slots.when(
            data: (timeSlots) {
              final bookable = timeSlots.where((s) => s.isBookable).toList();
              if (bookable.isEmpty) {
                return const Center(
                  child: Text('No available slots for this day.',
                      style: TextStyle(color: Colors.grey)),
                );
              }
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: bookable.map((slot) {
                  final parsed = DateFormat('HH:mm').parse(slot.time);
                  final label = timeFmt.format(parsed);
                  final isSel = _selectedSlot == slot.time;
                  return ChoiceChip(
                    label: Text(label),
                    selected: isSel,
                    onSelected: (_) =>
                        setState(() => _selectedSlot = slot.time),
                    selectedColor:
                        Theme.of(context).colorScheme.primaryContainer,
                  );
                }).toList(),
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                const Text('Failed to load slots. Please try again.'),
          ),

          const Spacer(),
          PrimaryButton(
            label: 'Continue',
            onPressed: _selectedSlot != null ? _submit : null,
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
