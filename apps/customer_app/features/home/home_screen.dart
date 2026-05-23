import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/booking_provider.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/booking_status_card.dart';
import '../../shared/widgets/primary_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final bookings = ref.watch(userBookingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Washly'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authServiceProvider).signOut(),
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
                      'Hello, ${p?.name.split(' ').first ?? 'there'} 👋',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                    loading: () =>
                        const Text('Hello!',
                            style: TextStyle(color: Colors.white, fontSize: 22)),
                    error: (_, __) => const SizedBox(),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Book a car wash at your doorstep',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/home/book'),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Book a Wash',
                        style: TextStyle(color: Colors.white)),
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
                      title: 'Exterior\nOnly',
                      subtitle: 'Quick & clean',
                      color: Colors.blue,
                      onTap: () => context.go('/home/book'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ServiceCard(
                      icon: Icons.cleaning_services,
                      title: 'Full\nService',
                      subtitle: 'Inside + Outside',
                      color: Colors.purple,
                      onTap: () => context.go('/home/book'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Recent bookings
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text('Recent Bookings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),

          bookings.when(
            data: (list) {
              if (list.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.car_rental, size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No bookings yet',
                            style: TextStyle(color: Colors.grey)),
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
                  child: const Text('View all bookings'),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
