import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/booking_provider.dart';
import '../../shared/widgets/booking_status_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authProvider);
    final bookings = ref.watch(userBookingsProvider);
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Hero section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  profile.when(
                    data: (p) => Text(
                      l10n.helloName(p?.name.split(' ').first ?? ''),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                    loading: () => Text(l10n.helloThere,
                        style: const TextStyle(color: Colors.white, fontSize: 22)),
                    error: (_, __) => const SizedBox(),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.bookCarWashDoorstep,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/home/book'),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: Text(l10n.bookAWash,
                        style: const TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      side: const BorderSide(color: Colors.white54),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Service cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _ServiceCard(
                      icon: Icons.car_crash_outlined,
                      title: l10n.exteriorOnlyShort,
                      subtitle: l10n.quickAndClean,
                      color: Colors.blue,
                      onTap: () => context.go('/home/book'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ServiceCard(
                      icon: Icons.airline_seat_recline_extra_outlined,
                      title: l10n.interiorOnlyShort,
                      subtitle: l10n.deepClean,
                      color: Colors.teal,
                      onTap: () => context.go('/home/book'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ServiceCard(
                      icon: Icons.cleaning_services,
                      title: l10n.fullServiceShort,
                      subtitle: l10n.insideOutside,
                      color: Colors.purple,
                      onTap: () => context.go('/home/book'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Recent bookings header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(l10n.recentBookings,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),

          bookings.when(
            data: (list) {
              if (list.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(Icons.car_rental, size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(l10n.noBookingsYet,
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }
              final recent = list.take(3).toList();
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => BookingStatusCard(booking: recent[i]),
                  childCount: recent.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(child: Text('Error: $e')),
            ),
          ),

          if (bookings.valueOrNull?.isNotEmpty == true)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () => context.go('/history'),
                  child: Text(l10n.viewAllBookings),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
