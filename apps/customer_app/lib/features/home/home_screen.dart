import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/booking_provider.dart';
import '../../core/providers/pricing_provider.dart';
import '../../shared/widgets/booking_status_card.dart';
import '../../shared/widgets/language_toggle_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authProvider);
    final bookings = ref.watch(userBookingsProvider);
    final pricing = ref.watch(pricingProvider);
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // ── Collapsible hero app bar ─────────────────────────────────
          SliverAppBar(
            expandedHeight: AppConfig.heroExpandedHeight,
            pinned: true,
            actions: [
              IconTheme(
                data: const IconThemeData(color: Colors.white),
                child: const LanguageToggleButton(),
              ),
            ],
            title: Text(l10n.appTitle,
                style: const TextStyle(color: Colors.white)),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Hero photo
                  CachedNetworkImage(
                    imageUrl: AppConfig.imgHero,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        const ColoredBox(color: Color(0xFF0D47A1)),
                    errorWidget: (_, __, ___) =>
                        const ColoredBox(color: Color(0xFF0D47A1)),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xCC0D47A1),
                          Color(0x991565C0),
                          Color(0x6600ACC1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  // Greeting + CTA
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 28,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        profile.when(
                          data: (p) => Text(
                            l10n.helloName(
                                p?.name.split(' ').first ?? ''),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          loading: () => const SizedBox(),
                          error: (_, __) => const SizedBox(),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.bookCarWashDoorstep,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => context.go('/home/book'),
                          icon: const Icon(Icons.water_drop),
                          label: Text(l10n.bookAWash),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0D47A1),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Our Services ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(l10n.ourServices,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 170,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _ServiceCard(
                    imageUrl: AppConfig.imgExterior,
                    gradientColors: const [Color(0xFF1565C0), Color(0xFF00ACC1)],
                    title: l10n.exteriorOnlyShort,
                    price: pricing.whenOrNull(data: (p) => p.exteriorLabel) ??
                        '${AppConfig.priceExteriorOnly} ${AppConfig.currency}',
                    onTap: () => context.go('/home/book'),
                  ),
                  const SizedBox(width: 12),
                  _ServiceCard(
                    imageUrl: AppConfig.imgInterior,
                    gradientColors: const [Color(0xFF00695C), Color(0xFF4CAF50)],
                    title: l10n.interiorOnlyShort,
                    price: pricing.whenOrNull(data: (p) => p.interiorLabel) ??
                        '${AppConfig.priceInteriorOnly} ${AppConfig.currency}',
                    onTap: () => context.go('/home/book'),
                  ),
                  const SizedBox(width: 12),
                  _ServiceCard(
                    imageUrl: AppConfig.imgFullService,
                    gradientColors: const [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
                    title: l10n.fullServiceShort,
                    price: pricing.whenOrNull(data: (p) => p.fullServiceLabel) ??
                        '${AppConfig.priceFullService} ${AppConfig.currency}',
                    onTap: () => context.go('/home/book'),
                  ),
                ],
              ),
            ),
          ),

          // ── Why Washly ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(l10n.whyWashly,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _FeatureTile(
                    icon: Icons.verified_outlined,
                    label: l10n.featureProfessional,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 10),
                  _FeatureTile(
                    icon: Icons.bolt_outlined,
                    label: l10n.featureFast,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 10),
                  _FeatureTile(
                    icon: Icons.eco_outlined,
                    label: l10n.featureEco,
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          ),

          // ── Recent Bookings ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 8),
              child: Text(l10n.recentBookings,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),

          bookings.when(
            data: (list) {
              if (list.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.water_drop_outlined,
                                size: 56, color: Colors.blue[200]),
                            const SizedBox(height: 12),
                            Text(l10n.noBookingsYet,
                                style:
                                    const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () => context.go('/home/book'),
                              child: Text(l10n.bookAWash),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
              final recent = list.take(AppConfig.homeRecentBookingsLimit).toList();
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: BookingStatusCard(booking: recent[i]),
                  ),
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
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextButton.icon(
                    onPressed: () => context.go('/history'),
                    icon: const Icon(Icons.receipt_long_outlined, size: 16),
                    label: Text(l10n.viewAllBookings),
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ── Service card (horizontal scroll) ────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final String imageUrl;
  final List<Color> gradientColors;
  final String title;
  final String price;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.imageUrl,
    required this.gradientColors,
    required this.title,
    required this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 160,
          height: 170,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              // Gradient overlay from bottom
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      gradientColors.last.withOpacity(0.75),
                      gradientColors.first.withOpacity(0.95),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.3, 0.7, 1.0],
                  ),
                ),
              ),
              // Text
              Positioned(
                left: 12,
                right: 12,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(price,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Feature tile ─────────────────────────────────────────────────────────────

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeatureTile({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700])),
            ],
          ),
        ),
      ),
    );
  }
}
