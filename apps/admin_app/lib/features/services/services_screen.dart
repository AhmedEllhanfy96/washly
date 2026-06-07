import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/service.dart';
import '../../core/providers/services_provider.dart';
import '../../core/services/services_service.dart';

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(adminServicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Service',
            onPressed: () => _showAddDialog(context, ref),
          ),
        ],
      ),
      body: servicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error: $e'),
              TextButton(
                onPressed: () => ref.invalidate(adminServicesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (services) => services.isEmpty
            ? const Center(child: Text('No services yet. Tap + to add one.'))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(adminServicesProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: services.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _ServiceTile(service: services[i]),
                ),
              ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _ServiceDialog(
        onSave: (data) async {
          await ref.read(adminServicesServiceProvider).create(
                key: data['key'] as String,
                name: data['name'] as String,
                description: data['description'] as String,
                price: data['price'] as int,
                features: data['features'] as List<String>,
                badge: data['badge'] as String,
                sortOrder: data['sortOrder'] as int,
              );
          ref.invalidate(adminServicesProvider);
        },
      ),
    );
  }
}

class _ServiceTile extends ConsumerWidget {
  final AdminService service;
  const _ServiceTile({required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: service.isActive
              ? AppColors.primary.withOpacity(0.2)
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(service.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: service.isActive
                                      ? null
                                      : Colors.grey[500])),
                          if (service.badge.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(service.badge,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87)),
                            ),
                          ],
                          if (!service.isActive) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('INACTIVE',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('key: ${service.key}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ),
                Text(
                  '${service.price} ${AppConfig.currency}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: service.isActive
                          ? AppColors.primary
                          : Colors.grey[500]),
                ),
              ],
            ),
            if (service.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(service.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
            if (service.features.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: service.features
                    .map((f) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(f,
                              style: const TextStyle(fontSize: 11)),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  onPressed: () => _showEditDialog(context, ref),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: Icon(
                    service.isActive
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 16,
                  ),
                  label: Text(service.isActive ? 'Deactivate' : 'Activate'),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        service.isActive ? Colors.orange : Colors.green,
                  ),
                  onPressed: () async {
                    await ref.read(adminServicesServiceProvider).update(
                        service.id, {'isActive': !service.isActive});
                    ref.invalidate(adminServicesProvider);
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

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _ServiceDialog(
        initialService: service,
        onSave: (data) async {
          await ref.read(adminServicesServiceProvider).update(service.id, {
            'name': data['name'],
            'description': data['description'],
            'price': data['price'],
            'features': data['features'],
            'badge': data['badge'],
            'sortOrder': data['sortOrder'],
            'imageUrl': data['imageUrl'],
          });
          ref.invalidate(adminServicesProvider);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Service'),
        content: Text(
            'Delete "${service.name}"? If it has existing bookings, it will be deactivated instead.'),
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
              try {
                await ref
                    .read(adminServicesServiceProvider)
                    .delete(service.id);
              } catch (_) {}
              ref.invalidate(adminServicesProvider);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ServiceDialog extends StatefulWidget {
  final AdminService? initialService;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _ServiceDialog({this.initialService, required this.onSave});

  @override
  State<_ServiceDialog> createState() => _ServiceDialogState();
}

class _ServiceDialogState extends State<_ServiceDialog> {
  final _keyCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _badgeCtrl = TextEditingController();
  final _featuresCtrl = TextEditingController();
  final _sortCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.initialService;
    if (s != null) {
      _keyCtrl.text = s.key;
      _nameCtrl.text = s.name;
      _descCtrl.text = s.description;
      _priceCtrl.text = s.price.toString();
      _badgeCtrl.text = s.badge;
      _featuresCtrl.text = s.features.join('\n');
      _sortCtrl.text = s.sortOrder.toString();
      _imageUrlCtrl.text = s.imageUrl;
    } else {
      _sortCtrl.text = '0';
    }
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _badgeCtrl.dispose();
    _featuresCtrl.dispose();
    _sortCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialService != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Service' : 'New Service'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isEdit)
              TextField(
                controller: _keyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Key (unique, snake_case)',
                  hintText: 'e.g. premium_wash',
                  border: OutlineInputBorder(),
                ),
              ),
            if (!isEdit) const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _imageUrlCtrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Image URL (optional)',
                hintText: 'https://example.com/image.jpg',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.image_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Price',
                suffixText: AppConfig.currency,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _featuresCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Features (one per line)',
                hintText: 'Exterior Wash\nWheel Cleaning',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _badgeCtrl,
              decoration: const InputDecoration(
                labelText: 'Badge (optional)',
                hintText: 'BEST VALUE',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sortCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Sort Order',
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
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final price = int.tryParse(_priceCtrl.text.trim());
    if (name.isEmpty || price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name and valid price are required')));
      return;
    }
    final key = widget.initialService?.key ?? _keyCtrl.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Key is required')));
      return;
    }
    final features = _featuresCtrl.text
        .split('\n')
        .map((f) => f.trim())
        .where((f) => f.isNotEmpty)
        .toList();

    setState(() => _saving = true);
    try {
      await widget.onSave({
        'key': key,
        'name': name,
        'description': _descCtrl.text.trim(),
        'price': price,
        'features': features,
        'badge': _badgeCtrl.text.trim(),
        'sortOrder': int.tryParse(_sortCtrl.text.trim()) ?? 0,
        'imageUrl': _imageUrlCtrl.text.trim(),
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
