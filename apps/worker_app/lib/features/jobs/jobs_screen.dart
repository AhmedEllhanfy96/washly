import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/app_localizations.dart';
import '../../shared/widgets/language_toggle_button.dart';
import '../../core/models/job.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/job_service.dart';
import 'job_detail_screen.dart';

final myJobsProvider = StreamProvider<List<Job>>((ref) {
  return ref.watch(jobServiceProvider).watchMyJobs();
});

class JobsScreen extends ConsumerWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(myJobsProvider);
    final profile = ref.watch(workerAuthStateProvider).valueOrNull;
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.myJobs,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (profile != null)
              Text(profile.name,
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.55))),
          ],
        ),
        actions: [
          const LanguageToggleButton(),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Sign out',
            onPressed: () => ref.read(workerAuthProvider.notifier).signOut(),
          ),
        ],
      ),
      body: jobs.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 72, color: Colors.green),
                  const SizedBox(height: 16),
                  Text(l10n.noPendingJobs,
                      style: const TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(l10n.checkBackSoon, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final today = list.where((j) => j.isToday).toList();
          final upcoming = list.where((j) => !j.isToday).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myJobsProvider),
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (today.isNotEmpty) ...[
                  _SectionHeader(label: l10n.todayCount(today.length)),
                  ...today.map((j) => _JobCard(job: j)),
                ],
                if (upcoming.isNotEmpty) ...[
                  _SectionHeader(label: l10n.upcoming),
                  ...upcoming.map((j) => _JobCard(job: j)),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
      child: Text(label,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Theme.of(context).colorScheme.primary)),
    );
  }
}

class _JobCard extends StatelessWidget {
  final Job job;
  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = DateFormat('EEE, MMM d • h:mm a');
    final statusColor = switch (job.status) {
      JobStatus.confirmed => Colors.blue,
      JobStatus.inProgress => Colors.orange,
      _ => Colors.grey,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(job.customerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(l10n.jobStatusLabel(job.status.name),
                        style: TextStyle(
                            color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.directions_car, size: 15, color: Colors.grey),
                const SizedBox(width: 4),
                Text(job.carSummary, style: const TextStyle(fontSize: 13)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on, size: 15, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(job.address,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.access_time, size: 15, color: Colors.grey),
                const SizedBox(width: 4),
                Text(fmt.format(job.scheduledAt), style: const TextStyle(fontSize: 13)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
