import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/team_member.dart';
import '../../core/providers/bookings_provider.dart';
import '../../core/services/booking_service.dart';

class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(teamMembersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Team Members')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMemberDialog(context, ref),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Member'),
      ),
      body: members.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No team members yet', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (_, i) => _MemberCard(member: list[i], ref: ref),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _showAddMemberDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Team Member'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final member = TeamMember(
                id: '',
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                isAvailable: true,
              );
              await ref.read(adminBookingServiceProvider).addTeamMember(member);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final TeamMember member;
  final WidgetRef ref;

  const _MemberCard({required this.member, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: member.isAvailable ? Colors.green[100] : Colors.grey[200],
          child: Text(
            member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
            style: TextStyle(
                color: member.isAvailable ? Colors.green[800] : Colors.grey),
          ),
        ),
        title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: member.phone.isNotEmpty ? Text(member.phone) : null,
        trailing: Switch(
          value: member.isAvailable,
          onChanged: (v) =>
              ref.read(adminBookingServiceProvider).updateAvailability(member.id, v),
        ),
      ),
    );
  }
}
