import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
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
  bool _showNewCarForm = false;

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
      _showNewCarForm = false;
    });
    _makeCtrl.text = car.make;
    _modelCtrl.text = car.model;
    _colorCtrl.text = car.color;
    _plateCtrl.text = car.plateNumber;
    _yearCtrl.text = car.year ?? '';
  }

  void _clearForm() {
    _makeCtrl.clear();
    _modelCtrl.clear();
    _colorCtrl.clear();
    _plateCtrl.clear();
    _yearCtrl.clear();
    setState(() {
      _selectedColor = null;
      _selectedSavedCarId = null;
      _saveCar = false;
    });
  }

  Future<void> _deleteSavedCar(String id) async {
    await ref.read(profileServiceProvider).deleteCar(id);
    ref.invalidate(savedCarsProvider);
    if (_selectedSavedCarId == id) {
      setState(() => _selectedSavedCarId = null);
    }
  }

  Future<void> _submit() async {
    if (_selectedSavedCarId != null) {
      // Use saved car — controllers already filled from _fillFromSaved
    } else if (!_formKey.currentState!.validate()) {
      return;
    }
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
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.tellUsAboutCar,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(l10n.carDetailsSubtitle,
              style: TextStyle(color: Colors.grey[600])),

          savedCarsAsync.when(
            data: (cars) {
              if (cars.isEmpty) {
                return _NewCarForm(
                  formKey: _formKey,
                  makeCtrl: _makeCtrl,
                  modelCtrl: _modelCtrl,
                  colorCtrl: _colorCtrl,
                  plateCtrl: _plateCtrl,
                  yearCtrl: _yearCtrl,
                  carColors: _carColors,
                  selectedColor: _selectedColor,
                  saveCar: _saveCar,
                  showSaveCheckbox: true,
                  onColorSelected: (c) => setState(() {
                    _selectedColor = c;
                    _selectedSavedCarId = null;
                  }),
                  onSaveChanged: (v) => setState(() => _saveCar = v),
                  l10n: l10n,
                );
              }

              // Has saved cars
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(l10n.yourSavedCars,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 12),

                  // Saved car cards
                  ...cars.map((car) {
                    final selected = _selectedSavedCarId == car.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () => _fillFromSaved(car),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: selected
                                ? theme.colorScheme.primaryContainer
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? theme.colorScheme.primary
                                  : Colors.grey[300]!,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? theme.colorScheme.primary.withOpacity(0.15)
                                      : Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.directions_car,
                                    size: 22,
                                    color: selected
                                        ? theme.colorScheme.primary
                                        : Colors.grey[600]),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(car.displayName,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: selected
                                                ? theme.colorScheme.primary
                                                : null)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${car.color}  •  ${car.plateNumber}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                              if (selected)
                                Icon(Icons.check_circle,
                                    color: theme.colorScheme.primary, size: 22)
                              else
                                IconButton(
                                  icon: Icon(Icons.close,
                                      size: 18, color: Colors.grey[400]),
                                  onPressed: () => _deleteSavedCar(car.id),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  // Add new car button / form toggle
                  if (!_showNewCarForm)
                    OutlinedButton.icon(
                      onPressed: () {
                        _clearForm();
                        setState(() => _showNewCarForm = true);
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l10n.addNewCar),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        Text(l10n.addNewCar,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        const Spacer(),
                        TextButton(
                          onPressed: () => setState(() {
                            _showNewCarForm = false;
                            _clearForm();
                          }),
                          child: Text(l10n.cancel),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _NewCarForm(
                      formKey: _formKey,
                      makeCtrl: _makeCtrl,
                      modelCtrl: _modelCtrl,
                      colorCtrl: _colorCtrl,
                      plateCtrl: _plateCtrl,
                      yearCtrl: _yearCtrl,
                      carColors: _carColors,
                      selectedColor: _selectedColor,
                      saveCar: _saveCar,
                      showSaveCheckbox: true,
                      onColorSelected: (c) => setState(() {
                        _selectedColor = c;
                        _selectedSavedCarId = null;
                      }),
                      onSaveChanged: (v) => setState(() => _saveCar = v),
                      l10n: l10n,
                    ),
                  ],
                ],
              );
            },
            loading: () =>
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
            error: (_, __) => _NewCarForm(
              formKey: _formKey,
              makeCtrl: _makeCtrl,
              modelCtrl: _modelCtrl,
              colorCtrl: _colorCtrl,
              plateCtrl: _plateCtrl,
              yearCtrl: _yearCtrl,
              carColors: _carColors,
              selectedColor: _selectedColor,
              saveCar: _saveCar,
              showSaveCheckbox: false,
              onColorSelected: (c) => setState(() => _selectedColor = c),
              onSaveChanged: (v) => setState(() => _saveCar = v),
              l10n: l10n,
            ),
          ),

          const SizedBox(height: 32),
          PrimaryButton(
            label: l10n.continueBtn,
            onPressed: (_selectedSavedCarId != null || _showNewCarForm || savedCarsAsync.valueOrNull?.isEmpty == true)
                ? _submit
                : null,
          ),
        ],
      ),
    );
  }
}

class _NewCarForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController makeCtrl;
  final TextEditingController modelCtrl;
  final TextEditingController colorCtrl;
  final TextEditingController plateCtrl;
  final TextEditingController yearCtrl;
  final List<String> carColors;
  final String? selectedColor;
  final bool saveCar;
  final bool showSaveCheckbox;
  final void Function(String) onColorSelected;
  final void Function(bool) onSaveChanged;
  final AppLocalizations l10n;

  const _NewCarForm({
    required this.formKey,
    required this.makeCtrl,
    required this.modelCtrl,
    required this.colorCtrl,
    required this.plateCtrl,
    required this.yearCtrl,
    required this.carColors,
    required this.selectedColor,
    required this.saveCar,
    required this.showSaveCheckbox,
    required this.onColorSelected,
    required this.onSaveChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: makeCtrl,
                  decoration: InputDecoration(labelText: l10n.make),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? l10n.required : null,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: modelCtrl,
                  decoration: InputDecoration(labelText: l10n.model),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? l10n.required : null,
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
                  controller: yearCtrl,
                  decoration: InputDecoration(labelText: l10n.yearOptional),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: plateCtrl,
                  decoration: InputDecoration(labelText: l10n.plateNumber),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? l10n.required : null,
                  textCapitalization: TextCapitalization.none,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l10n.carColor,
              style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: carColors.map((color) {
              final sel = selectedColor == color;
              return ChoiceChip(
                label: Text(color),
                selected: sel,
                onSelected: (_) => onColorSelected(color),
              );
            }).toList(),
          ),
          if (selectedColor == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextFormField(
                controller: colorCtrl,
                decoration: InputDecoration(labelText: l10n.otherColor),
                validator: (v) =>
                    (selectedColor == null && (v == null || v.isEmpty))
                        ? l10n.selectOrEnterColor
                        : null,
              ),
            ),
          if (showSaveCheckbox) ...[
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: saveCar,
              onChanged: (v) => onSaveChanged(v ?? false),
              title: Text(l10n.saveCarForNextTime,
                  style: const TextStyle(fontSize: 14)),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),
          ],
        ],
      ),
    );
  }
}
