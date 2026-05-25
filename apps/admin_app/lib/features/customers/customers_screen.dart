import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/customer_account.dart';
import '../../core/providers/customers_provider.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(customersProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.customers)),
      body: customers.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(l10n.noCustomers,
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(customersProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (_, i) => _CustomerTile(customer: list[i]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final CustomerAccount customer;
  const _CustomerTile({required this.customer});

  Future<void> _showContactSheet(BuildContext context) async {
    if (customer.phone.isEmpty) return;
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.contactCustomer,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(customer.phone,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _launch('tel:${customer.phone}'),
                      icon: const Icon(Icons.phone, color: Colors.green),
                      label: Text(l10n.callCustomer,
                          style: const TextStyle(color: Colors.green)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.green),
                        minimumSize: const Size(0, 52),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final digits = customer.phone.replaceAll(RegExp(r'\D'), '');
                        _launch('${AppConfig.whatsAppUrl}$digits');
                      },
                      icon: const Icon(Icons.chat, color: Colors.white),
                      label: Text(l10n.whatsappCustomer,
                          style: const TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        minimumSize: const Size(0, 52),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dateFmt = DateFormat('MMM yyyy');
    final initials = customer.name.isNotEmpty
        ? customer.name.trim().split(' ').map((w) => w[0]).take(2).join()
        : '?';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          child: Text(initials.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        title: Text(customer.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.email_outlined, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(customer.email,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
            if (customer.phone.isNotEmpty)
              Row(children: [
                const Icon(Icons.phone_outlined, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(customer.phone,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ]),
            const SizedBox(height: 4),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${customer.bookingCount} ${l10n.totalBookings}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${l10n.memberSince} ${dateFmt.format(customer.createdAt)}',
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            ]),
          ],
        ),
        isThreeLine: true,
        trailing: customer.phone.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.phone_forwarded_outlined),
                color: Theme.of(context).colorScheme.primary,
                onPressed: () => _showContactSheet(context),
                tooltip: l10n.contactCustomer,
              )
            : null,
        onTap: customer.phone.isNotEmpty
            ? () => _showContactSheet(context)
            : null,
      ),
    );
  }
}
