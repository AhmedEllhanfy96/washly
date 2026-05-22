import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/worker.dart';
import '../../core/providers/bookings_provider.dart';
import '../../core/services/booking_service.dart';

class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workers = ref.watch(workersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Workers')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddWorkerDialog(context, ref),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Worker'),
      ),
      body: workers.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.engineering_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('No workers yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Add workers so you can assign bookings to them',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddWorkerDialog(context, ref),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add First Worker'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(workersProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              itemCount: list.length,
              itemBuilder: (_, i) => _WorkerCard(worker: list[i], ref: ref),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _showAddWorkerDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool loading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.engineering, size: 22),
            SizedBox(width: 8),
            Text('Add Worker Account'),
          ]),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Full Name', prefixIcon: Icon(Icons.person_outlined)),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                        labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                        labelText: 'Email (login)', prefixIcon: Icon(Icons.email_outlined)),
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? 'Enter valid email' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Password', prefixIcon: Icon(Icons.lock_outlined)),
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Worker will use email + password to login to the Worker app.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: loading ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => loading = true);
                      try {
                        await ref.read(adminBookingServiceProvider).createWorker(
                              name: nameCtrl.text.trim(),
                              email: emailCtrl.text.trim(),
                              password: passCtrl.text,
                              phone: phoneCtrl.text.trim(),
                            );
                        ref.invalidate(workersProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                      } on DioException catch (e) {
                        setDialogState(() => loading = false);
                        if (ctx.mounted) {
                          final msg = (e.response?.data as Map?)?['error'] as String?;
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                              content: Text(msg ?? 'Failed to create worker'),
                              backgroundColor: Colors.red));
                        }
                      } on Exception catch (_) {
                        setDialogState(() => loading = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                              content: Text('Failed to create worker. Try again.'),
                              backgroundColor: Colors.red));
                        }
                      }
                    },
              child: loading
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  final Worker worker;
  final WidgetRef ref;
  const _WorkerCard({required this.worker, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green[100],
          child: Text(
            worker.name.isNotEmpty ? worker.name[0].toUpperCase() : '?',
            style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(worker.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (worker.phone.isNotEmpty)
              Text(worker.phone, style: const TextStyle(fontSize: 13)),
            if (worker.email != null)
              Text(worker.email!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _confirmDelete(context),
        ),
        isThreeLine: worker.phone.isNotEmpty && worker.email != null,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Worker'),
        content: Text('Remove ${worker.name}? They will no longer be able to login.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(adminBookingServiceProvider).deleteWorker(worker.id);
      ref.invalidate(workersProvider);
    }
  }
}
