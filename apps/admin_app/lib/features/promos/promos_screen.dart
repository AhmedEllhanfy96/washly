import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/promos_provider.dart';
import '../../core/services/promos_service.dart';

class PromosScreen extends ConsumerWidget {
  const PromosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promosAsync = ref.watch(adminPromosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Promo Codes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Promo',
            onPressed: () => _showAddDialog(context, ref),
          ),
        ],
      ),
      body: promosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error: $e'),
              TextButton(
                onPressed: () => ref.invalidate(adminPromosProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (promos) => promos.isEmpty
            ? const Center(child: Text('No promo codes yet. Tap + to create one.'))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(adminPromosProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: promos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _PromoTile(promo: promos[i]),
                ),
              ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _PromoDialog(
        onSave: (data) async {
          await ref.read(adminPromosServiceProvider).create(
                code: data['code'] as String,
                discountPercent: data['discountPercent'] as int,
                validUntil: data['validUntil'] as DateTime,
                maxUses: data['maxUses'] as int?,
                maxUsesPerUser: data['maxUsesPerUser'] as int?,
              );
          ref.invalidate(adminPromosProvider);
        },
      ),
    );
  }
}

class _PromoTile extends ConsumerWidget {
  final AdminPromo promo;
  const _PromoTile({required this.promo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('MMM d, yyyy');
    final now = DateTime.now();
    final isExpired = promo.validUntil.isBefore(now);
    final isExhausted =
        promo.maxUses != null && promo.usedCount >= promo.maxUses!;
    final isEffectivelyActive =
        promo.isActive && !isExpired && !isExhausted;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isEffectivelyActive
              ? Colors.green.withOpacity(0.3)
              : Colors.grey[300]!,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isEffectivelyActive
                        ? Colors.green[50]
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isEffectivelyActive
                            ? Colors.green[200]!
                            : Colors.grey[300]!),
                  ),
                  child: Text(
                    promo.code,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.5,
                      color: isEffectivelyActive
                          ? Colors.green[800]
                          : Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${promo.discountPercent}% off',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isEffectivelyActive
                        ? AppColors.primary
                        : Colors.grey[500],
                  ),
                ),
                const Spacer(),
                _StatusBadge(
                    isActive: promo.isActive,
                    isExpired: isExpired,
                    isExhausted: isExhausted),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 13, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${fmt.format(promo.validFrom)} – ${fmt.format(promo.validUntil)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.people_outline, size: 13, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  promo.maxUses != null
                      ? 'Total: ${promo.usedCount}/${promo.maxUses}'
                      : 'Total: ${promo.usedCount} (unlimited)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (promo.maxUsesPerUser != null) ...[
                  const SizedBox(width: 10),
                  Icon(Icons.person_outline, size: 13, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${promo.maxUsesPerUser}x per client',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (promo.isActive && !isExpired)
                  TextButton.icon(
                    icon: const Icon(Icons.pause_circle_outline, size: 16),
                    label: const Text('Deactivate'),
                    style: TextButton.styleFrom(foregroundColor: Colors.orange),
                    onPressed: () async {
                      await ref
                          .read(adminPromosServiceProvider)
                          .update(promo.id, isActive: false);
                      ref.invalidate(adminPromosProvider);
                    },
                  )
                else if (!promo.isActive)
                  TextButton.icon(
                    icon: const Icon(Icons.play_circle_outline, size: 16),
                    label: const Text('Activate'),
                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                    onPressed: () async {
                      await ref
                          .read(adminPromosServiceProvider)
                          .update(promo.id, isActive: true);
                      ref.invalidate(adminPromosProvider);
                    },
                  ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Delete'),
                  style:
                      TextButton.styleFrom(foregroundColor: AppColors.error),
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Promo'),
        content: Text('Delete promo code "${promo.code}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(adminPromosServiceProvider).delete(promo.id);
              ref.invalidate(adminPromosProvider);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  final bool isExpired;
  final bool isExhausted;
  const _StatusBadge(
      {required this.isActive,
      required this.isExpired,
      required this.isExhausted});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    if (!isActive) {
      label = 'Inactive';
      color = Colors.grey;
    } else if (isExpired) {
      label = 'Expired';
      color = Colors.red;
    } else if (isExhausted) {
      label = 'Exhausted';
      color = Colors.orange;
    } else {
      label = 'Active';
      color = Colors.green;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color)),
    );
  }
}

class _PromoDialog extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onSave;
  const _PromoDialog({required this.onSave});

  @override
  State<_PromoDialog> createState() => _PromoDialogState();
}

class _PromoDialogState extends State<_PromoDialog> {
  final _codeCtrl = TextEditingController();
  final _pctCtrl = TextEditingController();
  final _maxUsesCtrl = TextEditingController();
  final _maxUsesPerUserCtrl = TextEditingController();
  DateTime _validUntil = DateTime.now().add(const Duration(days: 7));
  bool _saving = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _pctCtrl.dispose();
    _maxUsesCtrl.dispose();
    _maxUsesPerUserCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    return AlertDialog(
      title: const Text('New Promo Code'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Code',
                hintText: 'WASHLY50',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pctCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Discount %',
                hintText: '50',
                suffixText: '%',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Valid Until', style: TextStyle(fontSize: 13)),
              subtitle: Text(fmt.format(_validUntil)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _validUntil,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _validUntil = picked);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _maxUsesCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Max total uses (empty = unlimited)',
                hintText: 'e.g. 100',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _maxUsesPerUserCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Max uses per client (empty = unlimited)',
                hintText: 'e.g. 1',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final code = _codeCtrl.text.trim();
    final pct = int.tryParse(_pctCtrl.text.trim());
    if (code.isEmpty || pct == null || pct <= 0 || pct > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Valid code and discount % required')));
      return;
    }
    final maxUsesText = _maxUsesCtrl.text.trim();
    final maxUses = maxUsesText.isEmpty ? null : int.tryParse(maxUsesText);
    final maxUsesPerUserText = _maxUsesPerUserCtrl.text.trim();
    final maxUsesPerUser = maxUsesPerUserText.isEmpty ? null : int.tryParse(maxUsesPerUserText);

    setState(() => _saving = true);
    try {
      await widget.onSave({
        'code': code,
        'discountPercent': pct,
        'validUntil': _validUntil,
        'maxUses': maxUses,
        'maxUsesPerUser': maxUsesPerUser,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
        setState(() => _saving = false);
      }
    }
  }
}
