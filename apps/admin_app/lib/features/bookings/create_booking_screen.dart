import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/models/booking.dart';
import '../../core/providers/bookings_provider.dart';
import '../../core/services/booking_service.dart';
import '../../shared/widgets/map_location_picker.dart';

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
  double _pickedLat = 0;
  double _pickedLng = 0;

  static const _colors = [
    'White', 'Black', 'Silver', 'Gray', 'Red',
    'Blue', 'Green', 'Yellow', 'Orange', 'Brown',
  ];

  static const _slots = ['08:00', '10:00', '12:00', '14:00', '16:00'];

  static const _sourceKeys = ['whatsapp', 'phone', 'walkin', 'other'];
  static const _sourceIcons = [Icons.chat, Icons.phone, Icons.directions_walk, Icons.more_horiz];
  static const _sourceColors = [Colors.green, Colors.blue, Colors.orange, Colors.grey];

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

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<LocationPickResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPickerScreen(
          initialAddress: _addressCtrl.text,
          initialLat: _pickedLat,
          initialLng: _pickedLng,
        ),
        fullscreenDialog: true,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _pickedLat = result.latitude;
        _pickedLng = result.longitude;
      });
      _addressCtrl.text = result.address;
    }
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
        SnackBar(content: Text(context.l10n.selectCarColor)),
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
            latitude: _pickedLat,
            longitude: _pickedLng,
            scheduledAt: _selectedDate,
            timeSlot: _selectedSlot,
            notes: _notesCtrl.text.trim(),
          );
      if (mounted) {
        ref.invalidate(allBookingsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.bookingCreated),
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
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final dateFmt = DateFormat('EEEE, MMM d, yyyy');

    final sourceLabels = ['WhatsApp', l10n.sourcePhone, l10n.sourceWalkIn, l10n.sourceOther];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newManualBooking)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(icon: Icons.source, label: l10n.bookingSource),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: List.generate(_sourceKeys.length, (i) {
                  final key = _sourceKeys[i];
                  final label = sourceLabels[i];
                  final icon = _sourceIcons[i];
                  final color = _sourceColors[i];
                  final selected = _source == key;
                  return ChoiceChip(
                    avatar: Icon(icon, size: 16,
                        color: selected ? Colors.white : color),
                    label: Text(label),
                    selected: selected,
                    selectedColor: color,
                    labelStyle: TextStyle(
                        color: selected ? Colors.white : null,
                        fontWeight: selected ? FontWeight.w600 : null),
                    onSelected: (_) => setState(() => _source = key),
                  );
                }),
              ),

              const SizedBox(height: 20),

              _SectionHeader(icon: Icons.person_outline, label: l10n.customer),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: l10n.customerName,
                  prefixIcon: const Icon(Icons.person_outlined),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty) ? l10n.required : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                decoration: InputDecoration(
                  labelText: l10n.phoneNumber,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.isEmpty) ? l10n.required : null,
              ),

              const SizedBox(height: 20),

              _SectionHeader(icon: Icons.directions_car_outlined, label: l10n.carDetails),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _makeCtrl,
                    decoration: InputDecoration(
                        labelText: l10n.make, border: const OutlineInputBorder()),
                    validator: (v) => (v == null || v.isEmpty) ? l10n.required : null,
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _modelCtrl,
                    decoration: InputDecoration(
                        labelText: l10n.model, border: const OutlineInputBorder()),
                    validator: (v) => (v == null || v.isEmpty) ? l10n.required : null,
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _plateCtrl,
                    decoration: InputDecoration(
                        labelText: l10n.plateNumber, border: const OutlineInputBorder()),
                    validator: (v) => (v == null || v.isEmpty) ? l10n.required : null,
                    textCapitalization: TextCapitalization.none,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _yearCtrl,
                    decoration: InputDecoration(
                        labelText: l10n.yearOpt, border: const OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Text(l10n.colorLabel, style: const TextStyle(fontWeight: FontWeight.w500)),
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

              _SectionHeader(icon: Icons.cleaning_services_outlined, label: l10n.service),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: _ServiceCard(
                    title: l10n.serviceTypeName(ServiceType.exteriorOnly),
                    price: '195 EGP',
                    selected: _serviceType == 'exteriorOnly',
                    onTap: () => setState(() => _serviceType = 'exteriorOnly'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ServiceCard(
                    title: l10n.serviceTypeName(ServiceType.interiorOnly),
                    price: '220 EGP',
                    selected: _serviceType == 'interiorOnly',
                    onTap: () => setState(() => _serviceType = 'interiorOnly'),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              _ServiceCard(
                title: l10n.serviceTypeName(ServiceType.fullService),
                price: '250 EGP',
                selected: _serviceType == 'fullService',
                onTap: () => setState(() => _serviceType = 'fullService'),
              ),

              const SizedBox(height: 20),

              _SectionHeader(icon: Icons.calendar_today_outlined, label: l10n.scheduleLabel),
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
              Text(l10n.timeSlot, style: const TextStyle(fontWeight: FontWeight.w500)),
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

              _SectionHeader(icon: Icons.location_on_outlined, label: l10n.location),
              const SizedBox(height: 10),
              TextFormField(
                controller: _addressCtrl,
                decoration: InputDecoration(
                  labelText: l10n.address,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: const OutlineInputBorder(),
                  hintText: 'e.g. 15 شارع التحرير، المعادي، القاهرة',
                  suffixIcon: _pickedLat != 0
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                ),
                maxLines: 2,
                validator: (v) => (v == null || v.isEmpty) ? l10n.required : null,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: _openMapPicker,
                  icon: const Icon(Icons.map_outlined),
                  label: Text(l10n.pickFromMap),
                ),
              ),
              if (_pickedLat != 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${_pickedLat.toStringAsFixed(5)}, ${_pickedLng.toStringAsFixed(5)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ),

              const SizedBox(height: 20),

              _SectionHeader(icon: Icons.note_alt_outlined, label: l10n.notesOptional),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notesCtrl,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: l10n.notesHint,
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
                  label: Text(l10n.createBookingBtn, style: const TextStyle(fontSize: 16)),
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
