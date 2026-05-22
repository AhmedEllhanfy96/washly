import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/car.dart';
import '../../../core/models/saved_car.dart';
import '../../../core/providers/booking_provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/services/profile_service.dart';
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
  String? _selectedSavedCarId;
  bool _saveCar = false;

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

  void _fillFromSaved(SavedCar car) {
    setState(() {
      _selectedSavedCarId = car.id;
      _selectedColor = car.color;
      _saveCar = false;
    });
    _makeCtrl.text = car.make;
    _modelCtrl.text = car.model;
    _colorCtrl.text = car.color;
    _plateCtrl.text = car.plateNumber;
    _yearCtrl.text = car.year ?? '';
  }

  Future<void> _deleteSavedCar(String id) async {
    await ref.read(profileServiceProvider).deleteCar(id);
    ref.invalidate(savedCarsProvider);
    if (_selectedSavedCarId == id) {
      setState(() => _selectedSavedCarId = null);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final car = Car(
      make: _makeCtrl.text.trim(),
      model: _modelCtrl.text.trim(),
      color: _selectedColor ?? _colorCtrl.text.trim(),
      plateNumber: _plateCtrl.text.trim().toUpperCase(),
      year: _yearCtrl.text.trim().isEmpty ? null : _yearCtrl.text.trim(),
    );
    ref.read(bookingFlowProvider.notifier).setCar(car);

    if (_saveCar && _selectedSavedCarId == null) {
      try {
        await ref.read(profileServiceProvider).saveCar(
              make: car.make,
              model: car.model,
              color: car.color,
              plateNumber: car.plateNumber,
              year: car.year,
            );
        ref.invalidate(savedCarsProvider);
      } catch (_) {}
    }

    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final savedCarsAsync = ref.watch(savedCarsProvider);

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

            // ── Saved cars ─────────────────────────────────────────────────
            savedCarsAsync.when(
              data: (cars) {
                if (cars.isEmpty) return const SizedBox(height: 24);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    const Text('Your saved cars',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 72,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: cars.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) {
                          final car = cars[i];
                          final selected = _selectedSavedCarId == car.id;
                          return GestureDetector(
                            onTap: () => _fillFromSaved(car),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Theme.of(context).colorScheme.primaryContainer
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey[300]!,
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.directions_car,
                                      size: 20,
                                      color: selected
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(car.displayName,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: selected
                                                  ? Theme.of(context).colorScheme.primary
                                                  : null)),
                                      Text(car.plateNumber,
                                          style: TextStyle(
                                              fontSize: 12, color: Colors.grey[600])),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _deleteSavedCar(car.id),
                                    child: Icon(Icons.close,
                                        size: 16, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                  ],
                );
              },
              loading: () => const SizedBox(height: 24),
              error: (_, __) => const SizedBox(height: 24),
            ),

            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _makeCtrl,
                    decoration: const InputDecoration(labelText: 'Make (Brand)'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() => _selectedSavedCarId = null),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _modelCtrl,
                    decoration: const InputDecoration(labelText: 'Model'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() => _selectedSavedCarId = null),
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
                    decoration: const InputDecoration(labelText: 'Year (optional)'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() => _selectedSavedCarId = null),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _plateCtrl,
                    decoration: const InputDecoration(labelText: 'Plate Number'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (_) => setState(() => _selectedSavedCarId = null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Car Color', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _carColors.map((color) {
                final selected = _selectedColor == color;
                return ChoiceChip(
                  label: Text(color),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    _selectedColor = color;
                    _selectedSavedCarId = null;
                  }),
                );
              }).toList(),
            ),
            if (_selectedColor == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextFormField(
                  controller: _colorCtrl,
                  decoration: const InputDecoration(labelText: 'Other color'),
                  validator: (v) =>
                      (_selectedColor == null && (v == null || v.isEmpty))
                          ? 'Select or enter a color'
                          : null,
                ),
              ),

            // ── Save option (only for new cars) ───────────────────────────
            if (_selectedSavedCarId == null) ...[
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _saveCar,
                onChanged: (v) => setState(() => _saveCar = v ?? false),
                title: const Text('Save this car for next time',
                    style: TextStyle(fontSize: 14)),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
            ],

            const SizedBox(height: 32),
            PrimaryButton(label: 'Continue', onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
