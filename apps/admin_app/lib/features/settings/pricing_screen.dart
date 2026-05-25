import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/booking.dart';
import '../../core/providers/pricing_provider.dart';

class PricingScreen extends ConsumerStatefulWidget {
  const PricingScreen({super.key});

  @override
  ConsumerState<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends ConsumerState<PricingScreen> {
  final _exteriorCtrl = TextEditingController();
  final _interiorCtrl = TextEditingController();
  final _fullCtrl = TextEditingController();
  bool _dirty = false;

  @override
  void dispose() {
    _exteriorCtrl.dispose();
    _interiorCtrl.dispose();
    _fullCtrl.dispose();
    super.dispose();
  }

  void _populate(prices) {
    if (!_dirty) {
      _exteriorCtrl.text = prices.exteriorOnly.toString();
      _interiorCtrl.text = prices.interiorOnly.toString();
      _fullCtrl.text = prices.fullService.toString();
    }
  }

  Future<void> _save() async {
    final ext = int.tryParse(_exteriorCtrl.text.trim());
    final int_ = int.tryParse(_interiorCtrl.text.trim());
    final full = int.tryParse(_fullCtrl.text.trim());
    if (ext == null || int_ == null || full == null || ext <= 0 || int_ <= 0 || full <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid prices (whole numbers > 0)')),
      );
      return;
    }
    try {
      await ref.read(pricingProvider.notifier).update(
            exteriorOnly: ext,
            interiorOnly: int_,
            fullService: full,
          );
      if (mounted) {
        setState(() => _dirty = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Prices updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pricingAsync = ref.watch(pricingProvider);

    pricingAsync.whenData(_populate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Pricing'),
        actions: [
          if (_dirty)
            TextButton.icon(
              onPressed: pricingAsync.isLoading ? null : _save,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: pricingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (_) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _InfoCard(),
            const SizedBox(height: 24),
            _PriceField(
              controller: _exteriorCtrl,
              serviceType: ServiceType.exteriorOnly,
              color: AppColors.primary,
              icon: Icons.water_drop_outlined,
              label: 'Exterior Only',
              onChanged: () => setState(() => _dirty = true),
            ),
            const SizedBox(height: 16),
            _PriceField(
              controller: _interiorCtrl,
              serviceType: ServiceType.interiorOnly,
              color: const Color(0xFF00695C),
              icon: Icons.airline_seat_recline_extra_outlined,
              label: 'Interior Only',
              onChanged: () => setState(() => _dirty = true),
            ),
            const SizedBox(height: 16),
            _PriceField(
              controller: _fullCtrl,
              serviceType: ServiceType.fullService,
              color: const Color(0xFF6A1B9A),
              icon: Icons.cleaning_services,
              label: 'Full Service',
              onChanged: () => setState(() => _dirty = true),
            ),
            const SizedBox(height: 32),
            if (_dirty)
              FilledButton.icon(
                onPressed: pricingAsync.isLoading ? null : _save,
                icon: const Icon(Icons.save),
                label: const Text('Save Changes'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Price changes take effect immediately for all new bookings. '
              'Existing bookings are not affected.',
              style: TextStyle(color: AppColors.primary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceField extends StatelessWidget {
  final TextEditingController controller;
  final ServiceType serviceType;
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onChanged;

  const _PriceField({
    required this.controller,
    required this.serviceType,
    required this.color,
    required this.icon,
    required this.label,
    required this.onChanged,
  });

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
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => onChanged(),
              decoration: InputDecoration(
                labelText: 'Price',
                suffixText: AppConfig.currency,
                prefixIcon: Icon(Icons.attach_money, color: color),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: color, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
