import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/pricing_provider.dart';

class PricingScreen extends ConsumerStatefulWidget {
  const PricingScreen({super.key});

  @override
  ConsumerState<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends ConsumerState<PricingScreen> {
  // Contact / InstaPay fields
  final _instapayNumberCtrl = TextEditingController();
  final _instapayLinkCtrl = TextEditingController();
  final _supportPhoneCtrl = TextEditingController();
  bool _contactDirty = false;

  bool _populated = false;

  @override
  void dispose() {
    _instapayNumberCtrl.dispose();
    _instapayLinkCtrl.dispose();
    _supportPhoneCtrl.dispose();
    super.dispose();
  }

  void _populate(prices) {
    if (_populated) return;
    _populated = true;
    _instapayNumberCtrl.text = prices.instapayNumber;
    _instapayLinkCtrl.text = prices.instapayLink;
    _supportPhoneCtrl.text = prices.supportPhone;
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
              icon: Icons.cleaning_services_outlined,
              title: 'Service Pricing',
              color: AppColors.primary,
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: AppColors.primary.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: ListTile(
                leading: Icon(Icons.cleaning_services_outlined,
                    color: AppColors.primary),
                title: const Text('Manage Services & Prices',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text(
                    'Add, edit, or remove wash services and set their prices.',
                    style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/dashboard/services'),
              ),
            ),

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

