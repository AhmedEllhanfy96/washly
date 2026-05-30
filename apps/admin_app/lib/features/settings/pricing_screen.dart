import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/booking.dart';
import '../../core/providers/pricing_provider.dart';

class PricingScreen extends ConsumerStatefulWidget {
  const PricingScreen({super.key});

  @override
  ConsumerState<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends ConsumerState<PricingScreen> {
  // Price fields
  final _exteriorCtrl = TextEditingController();
  final _interiorCtrl = TextEditingController();
  final _fullCtrl = TextEditingController();
  bool _priceDirty = false;

  // Contact / InstaPay fields
  final _instapayNumberCtrl = TextEditingController();
  final _instapayLinkCtrl = TextEditingController();
  final _supportPhoneCtrl = TextEditingController();
  bool _contactDirty = false;

  bool _populated = false;

  @override
  void dispose() {
    _exteriorCtrl.dispose();
    _interiorCtrl.dispose();
    _fullCtrl.dispose();
    _instapayNumberCtrl.dispose();
    _instapayLinkCtrl.dispose();
    _supportPhoneCtrl.dispose();
    super.dispose();
  }

  void _populate(prices) {
    if (_populated) return;
    _populated = true;
    _exteriorCtrl.text = prices.exteriorOnly.toString();
    _interiorCtrl.text = prices.interiorOnly.toString();
    _fullCtrl.text = prices.fullService.toString();
    _instapayNumberCtrl.text = prices.instapayNumber;
    _instapayLinkCtrl.text = prices.instapayLink;
    _supportPhoneCtrl.text = prices.supportPhone;
  }

  Future<void> _savePrices() async {
    final ext = int.tryParse(_exteriorCtrl.text.trim());
    final int_ = int.tryParse(_interiorCtrl.text.trim());
    final full = int.tryParse(_fullCtrl.text.trim());
    if (ext == null || int_ == null || full == null || ext <= 0 || int_ <= 0 || full <= 0) {
      _snack('Enter valid prices (whole numbers > 0)', isError: true);
      return;
    }
    try {
      await ref.read(pricingProvider.notifier).savePrices(
            exteriorOnly: ext, interiorOnly: int_, fullService: full);
      if (mounted) {
        setState(() => _priceDirty = false);
        _snack('Prices updated');
      }
    } catch (e) {
      if (mounted) _snack('Failed: $e', isError: true);
    }
  }

  Future<void> _saveContact() async {
    try {
      await ref.read(pricingProvider.notifier).saveContact(
            instapayNumber: _instapayNumberCtrl.text.trim(),
            instapayLink: _instapayLinkCtrl.text.trim(),
            supportPhone: _supportPhoneCtrl.text.trim(),
          );
      if (mounted) {
        setState(() => _contactDirty = false);
        _snack('Settings saved');
      }
    } catch (e) {
      if (mounted) _snack('Failed: $e', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final pricingAsync = ref.watch(pricingProvider);
    pricingAsync.whenData(_populate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
      ),
      body: pricingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (_) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Service Pricing ─────────────────────────────────────────
            _SectionHeader(
              icon: Icons.attach_money,
              title: 'Service Pricing',
              color: AppColors.primary,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.15)),
              ),
              child: Text(
                'Price changes take effect immediately for all new bookings.',
                style: TextStyle(color: AppColors.primary, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            _PriceField(
              controller: _exteriorCtrl,
              serviceType: ServiceType.exteriorOnly,
              color: AppColors.primary,
              icon: Icons.water_drop_outlined,
              label: 'Exterior Only',
              onChanged: () => setState(() => _priceDirty = true),
            ),
            const SizedBox(height: 12),
            _PriceField(
              controller: _interiorCtrl,
              serviceType: ServiceType.interiorOnly,
              color: const Color(0xFF00695C),
              icon: Icons.airline_seat_recline_extra_outlined,
              label: 'Interior Only',
              onChanged: () => setState(() => _priceDirty = true),
            ),
            const SizedBox(height: 12),
            _PriceField(
              controller: _fullCtrl,
              serviceType: ServiceType.fullService,
              color: const Color(0xFF6A1B9A),
              icon: Icons.cleaning_services,
              label: 'Full Service',
              onChanged: () => setState(() => _priceDirty = true),
            ),
            if (_priceDirty) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _savePrices,
                icon: const Icon(Icons.save),
                label: const Text('Save Prices'),
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
              ),
            ],

            const SizedBox(height: 32),

            // ── InstaPay & Support ──────────────────────────────────────
            _SectionHeader(
              icon: Icons.mobile_friendly,
              title: 'InstaPay & Support',
              color: Colors.blue[700]!,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(
                'These details appear in the customer app when a customer selects InstaPay as payment method.',
                style: TextStyle(color: Colors.blue[800], fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),

            _TextField(
              controller: _instapayNumberCtrl,
              label: 'InstaPay Number',
              hint: 'e.g. 01XXXXXXXXX',
              icon: Icons.numbers,
              keyboardType: TextInputType.phone,
              onChanged: () => setState(() => _contactDirty = true),
            ),
            const SizedBox(height: 12),
            _TextField(
              controller: _instapayLinkCtrl,
              label: 'InstaPay Deep Link (optional)',
              hint: 'e.g. instapay://...',
              icon: Icons.link,
              onChanged: () => setState(() => _contactDirty = true),
            ),
            const SizedBox(height: 12),
            _TextField(
              controller: _supportPhoneCtrl,
              label: 'Support WhatsApp Number',
              hint: 'e.g. 01XXXXXXXXX',
              icon: Icons.support_agent,
              keyboardType: TextInputType.phone,
              onChanged: () => setState(() => _contactDirty = true),
            ),
            if (_contactDirty) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saveContact,
                icon: const Icon(Icons.save),
                label: const Text('Save InstaPay & Support'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: Colors.blue[700],
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _SectionHeader({required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final VoidCallback onChanged;

  const _TextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
        padding: const EdgeInsets.all(14),
        child: Row(
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
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)),
            ),
            SizedBox(
              width: 110,
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                onChanged: (_) => onChanged(),
                decoration: InputDecoration(
                  suffixText: AppConfig.currency,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
