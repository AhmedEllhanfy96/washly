import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/car.dart';
import '../../../core/providers/booking_provider.dart';
import '../../../shared/widgets/primary_button.dart';

class CarDetailsStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const CarDetailsStep({super.key, required this.onNext});

  @override
  ConsumerState<CarDetailsStep> createState() => _CarDetailsStepState();
}

class _CarDetailsStepState extends ConsumerState<CarDetailsStep> {
  final _formKey = GlobalKey<FormState>();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();

  static const _carColors = [
    'White', 'Black', 'Silver', 'Gray', 'Red',
    'Blue', 'Green', 'Yellow', 'Orange', 'Brown',
  ];
  String? _selectedColor;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(bookingFlowProvider).car;
    if (existing != null) {
      _makeCtrl.text = existing.make;
      _modelCtrl.text = existing.model;
      _colorCtrl.text = existing.color;
      _plateCtrl.text = existing.plateNumber;
      _yearCtrl.text = existing.year ?? '';
      _selectedColor = existing.color;
    }
  }

  @override
  void dispose() {
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _colorCtrl.dispose();
    _plateCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final car = Car(
      make: _makeCtrl.text.trim(),
      model: _modelCtrl.text.trim(),
      color: _selectedColor ?? _colorCtrl.text.trim(),
      plateNumber: _plateCtrl.text.trim().toUpperCase(),
      year: _yearCtrl.text.trim().isEmpty ? null : _yearCtrl.text.trim(),
    );
    ref.read(bookingFlowProvider.notifier).setCar(car);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tell us about your car',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('We need these details to give your car the right treatment.',
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _makeCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Make (Brand)'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _modelCtrl,
                    decoration: const InputDecoration(labelText: 'Model'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _yearCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Year (optional)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _plateCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Plate Number'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Car Color',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _carColors.map((color) {
                final selected = _selectedColor == color;
                return ChoiceChip(
                  label: Text(color),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedColor = color),
                );
              }).toList(),
            ),
            if (_selectedColor == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextFormField(
                  controller: _colorCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Other color'),
                  validator: (v) => (_selectedColor == null &&
                          (v == null || v.isEmpty))
                      ? 'Select or enter a color'
                      : null,
                ),
              ),
            const SizedBox(height: 40),
            PrimaryButton(label: 'Continue', onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
