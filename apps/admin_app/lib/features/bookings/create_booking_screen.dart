import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/bookings_provider.dart';
import '../../core/services/booking_service.dart';

class CreateBookingScreen extends ConsumerStatefulWidget {
  const CreateBookingScreen({super.key});

  @override
  ConsumerState<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends ConsumerState<CreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _source = 'whatsapp';
  String _serviceType = 'exteriorOnly';
  String? _selectedColor;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedSlot = '08:00';
  bool _loading = false;

  static const _colors = [
    'White', 'Black', 'Silver', 'Gray', 'Red',
    'Blue', 'Green', 'Yellow', 'Orange', 'Brown',
  ];

  static const _slots = [
    '08:00', '10:00', '12:00', '14:00', '16:00',
  ];

  static const _sources = {
    'whatsapp': ('WhatsApp', Icons.chat, Colors.green),
    'phone': ('Phone Call', Icons.phone, Colors.blue),
    'walkin': ('Walk-in', Icons.directions_walk, Colors.orange),
    'other': ('Other', Icons.more_horiz, Colors.grey),
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _plateCtrl.dispose();
    _yearCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a car color')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(adminBookingServiceProvider).createManualBooking(
            customerName: _nameCtrl.text.trim(),
            customerPhone: _phoneCtrl.text.trim(),
            source: _source,
            car: {
              'make': _makeCtrl.text.trim(),
              'model': _modelCtrl.text.trim(),
              'color': _selectedColor!,
              'plateNumber': _plateCtrl.text.trim().toUpperCase(),
              'year': _yearCtrl.text.trim().isEmpty ? null : _yearCtrl.text.trim(),
            },
            serviceType: _serviceType,
            address: _addressCtrl.text.trim(),
            latitude: 0,
            longitude: 0,
            scheduledAt: _selectedDate,
            timeSlot: _selectedSlot,
            notes: _notesCtrl.text.trim(),
          );
      if (mounted) {
        ref.invalidate(allBookingsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('EEEE, MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('New Manual Booking')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Source ─────────────────────────────────────────────────
              _SectionHeader(icon: Icons.source, label: 'Booking Source'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _sources.entries.map((e) {
                  final (label, icon, color) = e.value;
                  final selected = _source == e.key;
                  return ChoiceChip(
                    avatar: Icon(icon, size: 16,
                        color: selected ? Colors.white : color),
                    label: Text(label),
                    selected: selected,
                    selectedColor: color,
                    labelStyle: TextStyle(
                        color: selected ? Colors.white : null,
                        fontWeight: selected ? FontWeight.w600 : null),
                    onSelected: (_) => setState(() => _source = e.key),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // ── Customer ───────────────────────────────────────────────
              _SectionHeader(icon: Icons.person_outline, label: 'Customer'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Customer Name',
                  prefixIcon: Icon(Icons.person_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),

              const SizedBox(height: 20),

              // ── Car ────────────────────────────────────────────────────
              _SectionHeader(icon: Icons.directions_car_outlined, label: 'Car Details'),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _makeCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Make', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _modelCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Model', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _plateCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Plate Number', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _yearCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Year (opt.)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              const Text('Color', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _colors.map((c) => ChoiceChip(
                  label: Text(c),
                  selected: _selectedColor == c,
                  onSelected: (_) => setState(() => _selectedColor = c),
                )).toList(),
              ),

              const SizedBox(height: 20),

              // ── Service ────────────────────────────────────────────────
              _SectionHeader(icon: Icons.cleaning_services_outlined, label: 'Service'),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: _ServiceCard(
                    title: 'Exterior Only',
                    price: '195 EGP',
                    selected: _serviceType == 'exteriorOnly',
                    onTap: () => setState(() => _serviceType = 'exteriorOnly'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ServiceCard(
                    title: 'Full Service',
                    price: '250 EGP',
                    selected: _serviceType == 'fullService',
                    onTap: () => setState(() => _serviceType = 'fullService'),
                  ),
                ),
              ]),

              const SizedBox(height: 20),

              // ── Schedule ───────────────────────────────────────────────
              _SectionHeader(icon: Icons.calendar_today_outlined, label: 'Schedule'),
              const SizedBox(height: 10),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    Icon(Icons.calendar_month, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(dateFmt.format(_selectedDate),
                        style: const TextStyle(fontSize: 15)),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Time Slot', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _slots.map((s) => ChoiceChip(
                  label: Text(s),
                  selected: _selectedSlot == s,
                  onSelected: (_) => setState(() => _selectedSlot = s),
                )).toList(),
              ),

              const SizedBox(height: 20),

              // ── Location ───────────────────────────────────────────────
              _SectionHeader(icon: Icons.location_on_outlined, label: 'Location'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                  hintText: 'e.g. 15 شارع التحرير، المعادي، القاهرة',
                ),
                maxLines: 2,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),

              const SizedBox(height: 20),

              // ── Notes ──────────────────────────────────────────────────
              _SectionHeader(icon: Icons.note_alt_outlined, label: 'Notes (optional)'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Any special instructions…',
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add_circle_outline),
                  label: const Text('Create Booking', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      Text(label,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary)),
      const Expanded(child: Divider(indent: 8)),
    ]);
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final String price;
  final bool selected;
  final VoidCallback onTap;
  const _ServiceCard(
      {required this.title,
      required this.price,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primaryContainer : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : Colors.grey[300]!,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? theme.colorScheme.primary : null)),
            Text(price,
                style: TextStyle(
                    fontSize: 13,
                    color: selected ? theme.colorScheme.primary : Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
