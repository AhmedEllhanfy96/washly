import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/api_client.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class AdminSlide {
  final String id;
  final String imageUrl;
  final String title;
  final String caption;
  final int sortOrder;
  final bool isActive;

  const AdminSlide({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.caption,
    required this.sortOrder,
    required this.isActive,
  });

  factory AdminSlide.fromJson(Map<String, dynamic> json) => AdminSlide(
        id: json['id'] as String,
        imageUrl: json['imageUrl'] as String? ?? '',
        title: json['title'] as String? ?? '',
        caption: json['caption'] as String? ?? '',
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
        isActive: json['isActive'] as bool? ?? true,
      );
}

// ── Provider ──────────────────────────────────────────────────────────────────

final _slidesServiceProvider = Provider<_SlidesService>((ref) => _SlidesService());

final adminSlidesProvider = FutureProvider<List<AdminSlide>>((ref) {
  return ref.read(_slidesServiceProvider).fetchAll();
});

class _SlidesService {
  final Dio _dio = createDio();

  Future<List<AdminSlide>> fetchAll() async {
    final res = await _dio.get('/slides/all');
    return (res.data as List)
        .map((j) => AdminSlide.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<AdminSlide> create(String imageUrl, String title, String caption, int sortOrder) async {
    final res = await _dio.post('/slides', data: {
      'imageUrl': imageUrl,
      'title': title,
      'caption': caption,
      'sortOrder': sortOrder,
    });
    return AdminSlide.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> update(String id, Map<String, dynamic> fields) async {
    await _dio.patch('/slides/$id', data: fields);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/slides/$id');
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class SlidesScreen extends ConsumerWidget {
  const SlidesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slidesAsync = ref.watch(adminSlidesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketing Slides'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Slide',
            onPressed: () => _showAddDialog(context, ref),
          ),
        ],
      ),
      body: slidesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Error: $e'),
            TextButton(
              onPressed: () => ref.invalidate(adminSlidesProvider),
              child: const Text('Retry'),
            ),
          ]),
        ),
        data: (slides) => slides.isEmpty
            ? const Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.slideshow_outlined, size: 56, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No slides yet. Tap + to add marketing images.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey)),
                ]),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      'Slides appear as an auto-scrolling carousel on the customer home screen.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async => ref.invalidate(adminSlidesProvider),
                      child: ReorderableListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: slides.length,
                        onReorder: (oldIdx, newIdx) async {
                          if (newIdx > oldIdx) newIdx--;
                          final svc = ref.read(_slidesServiceProvider);
                          // Update sort_order based on new position
                          for (int i = 0; i < slides.length; i++) {
                            final targetIdx = i == oldIdx
                                ? newIdx
                                : (i == newIdx && oldIdx < newIdx)
                                    ? i - 1
                                    : (i == newIdx && oldIdx > newIdx)
                                        ? i + 1
                                        : i;
                            await svc.update(slides[i].id, {'sortOrder': targetIdx});
                          }
                          ref.invalidate(adminSlidesProvider);
                        },
                        itemBuilder: (_, i) => _SlideTile(
                          key: ValueKey(slides[i].id),
                          slide: slides[i],
                          onEdit: () => _showEditDialog(context, ref, slides[i]),
                          onToggle: () async {
                            await ref.read(_slidesServiceProvider)
                                .update(slides[i].id, {'isActive': !slides[i].isActive});
                            ref.invalidate(adminSlidesProvider);
                          },
                          onDelete: () => _confirmDelete(context, ref, slides[i]),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _SlideDialog(
        onSave: (url, title, caption, sort) async {
          await ref.read(_slidesServiceProvider).create(url, title, caption, sort);
          ref.invalidate(adminSlidesProvider);
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, AdminSlide slide) {
    showDialog(
      context: context,
      builder: (_) => _SlideDialog(
        initialSlide: slide,
        onSave: (url, title, caption, sort) async {
          await ref.read(_slidesServiceProvider).update(slide.id, {
            'imageUrl': url,
            'title': title,
            'caption': caption,
            'sortOrder': sort,
          });
          ref.invalidate(adminSlidesProvider);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, AdminSlide slide) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Slide'),
        content: Text('Delete slide "${slide.title.isNotEmpty ? slide.title : slide.imageUrl}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(_slidesServiceProvider).delete(slide.id);
              ref.invalidate(adminSlidesProvider);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Slide tile ─────────────────────────────────────────────────────────────────

class _SlideTile extends StatelessWidget {
  final AdminSlide slide;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _SlideTile({
    super.key,
    required this.slide,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: slide.isActive
              ? AppColors.primary.withOpacity(0.2)
              : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
            child: SizedBox(
              width: 100,
              height: 80,
              child: slide.imageUrl.isNotEmpty
                  ? Image.network(
                      slide.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    if (!slide.isActive)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(6)),
                        child: const Text('Hidden',
                            style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ),
                    Expanded(
                      child: Text(
                        slide.title.isNotEmpty ? slide.title : '(no title)',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: slide.isActive ? null : Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                  if (slide.caption.isNotEmpty)
                    Text(slide.caption,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis),
                  Text(slide.imageUrl,
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
          // Actions
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: onEdit,
                tooltip: 'Edit',
              ),
              IconButton(
                icon: Icon(
                  slide.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                  color: slide.isActive ? Colors.orange : Colors.green,
                ),
                onPressed: onToggle,
                tooltip: slide.isActive ? 'Hide' : 'Show',
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
            ],
          ),
          const SizedBox(width: 4),
          // Drag handle
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.drag_handle, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image_outlined, color: Colors.grey, size: 32),
      );
}

// ── Dialog ────────────────────────────────────────────────────────────────────

class _SlideDialog extends StatefulWidget {
  final AdminSlide? initialSlide;
  final Future<void> Function(String url, String title, String caption, int sort) onSave;

  const _SlideDialog({this.initialSlide, required this.onSave});

  @override
  State<_SlideDialog> createState() => _SlideDialogState();
}

class _SlideDialogState extends State<_SlideDialog> {
  final _urlCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _captionCtrl = TextEditingController();
  final _sortCtrl = TextEditingController();
  bool _saving = false;
  String _previewUrl = '';

  @override
  void initState() {
    super.initState();
    final s = widget.initialSlide;
    if (s != null) {
      _urlCtrl.text = s.imageUrl;
      _titleCtrl.text = s.title;
      _captionCtrl.text = s.caption;
      _sortCtrl.text = s.sortOrder.toString();
      _previewUrl = s.imageUrl;
    } else {
      _sortCtrl.text = '0';
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _titleCtrl.dispose();
    _captionCtrl.dispose();
    _sortCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialSlide != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Slide' : 'New Slide'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Preview
            if (_previewUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: Image.network(
                    _previewUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlCtrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Image URL *',
                hintText: 'https://example.com/image.jpg',
                prefixIcon: Icon(Icons.image_outlined),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _previewUrl = v.trim()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title (optional)',
                hintText: 'e.g. Full Service — Special Offer!',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _captionCtrl,
              decoration: const InputDecoration(
                labelText: 'Caption (optional)',
                hintText: 'e.g. Book today and save 20%',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sortCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Order (0 = first)',
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
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Image URL is required')));
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave(
        url,
        _titleCtrl.text.trim(),
        _captionCtrl.text.trim(),
        int.tryParse(_sortCtrl.text.trim()) ?? 0,
      );
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
