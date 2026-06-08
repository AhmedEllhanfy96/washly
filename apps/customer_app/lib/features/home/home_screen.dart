import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/slide.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/booking_provider.dart';
import '../../core/providers/pricing_provider.dart';
import '../../core/providers/services_provider.dart';
import '../../core/providers/slides_provider.dart';
import '../../shared/widgets/booking_status_card.dart';
import '../../shared/widgets/language_toggle_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authProvider);
    final bookings = ref.watch(userBookingsProvider);
    final pricing = ref.watch(pricingProvider);
    final services = ref.watch(servicesProvider);
    final slides = ref.watch(slidesProvider);
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      floatingActionButton: pricing.whenOrNull(
        data: (p) => p.supportPhone.isEmpty
            ? null
            : FloatingActionButton(
                backgroundColor: const Color(0xFF25D366),
                tooltip: 'Support on WhatsApp',
                onPressed: () => launchUrl(
                  Uri.parse('${AppConfig.whatsAppUrl}${p.supportPhone}'),
                  mode: LaunchMode.externalApplication,
                ),
                child: const Icon(Icons.chat, color: Colors.white),
              ),
      ),
      appBar: AppBar(
        title: Text(l10n.appTitle,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 0,
        actions: [
          IconTheme(
            data: const IconThemeData(color: Colors.white),
            child: const LanguageToggleButton(),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Marketing carousel ───────────────────────────────────────
          SliverToBoxAdapter(
            child: _MarketingCarousel(
              slides: slides.valueOrNull ?? [],
              greeting: profile.valueOrNull?.name.split(' ').first ?? '',
              l10n: l10n,
              onBook: () => context.go('/home/book'),
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
              child: services.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
                data: (svcList) => ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: svcList.asMap().entries.map((entry) {
                    final i = entry.key;
                    final svc = entry.value;
                    const themes = [
                      [Color(0xFF1565C0), Color(0xFF00ACC1)],
                      [Color(0xFF00695C), Color(0xFF4CAF50)],
                      [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
                      [Color(0xFF37474F), Color(0xFF78909C)],
                    ];
                    final colors = themes[i % themes.length];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _ServiceCard(
                        imageUrl: svc.imageUrl,
                        gradientColors: colors,
                        title: svc.name,
                        price: '${svc.price} ${AppConfig.currency}',
                        onTap: () => context.go('/home/book'),
                      ),
                    );
                  }).toList(),
                ),
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
              if (imageUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Shimmer.fromColors(
                    baseColor: gradientColors.first,
                    highlightColor: gradientColors.last,
                    child: Container(color: gradientColors.first),
                  ),
                  errorWidget: (_, __, ___) => _GradientFill(gradientColors),
                )
              else
                _GradientFill(gradientColors),
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

// ── Marketing carousel ────────────────────────────────────────────────────────

class _MarketingCarousel extends StatefulWidget {
  final List<Slide> slides;
  final String greeting;
  final AppLocalizations l10n;
  final VoidCallback onBook;

  const _MarketingCarousel({
    required this.slides,
    required this.greeting,
    required this.l10n,
    required this.onBook,
  });

  @override
  State<_MarketingCarousel> createState() => _MarketingCarouselState();
}

class _MarketingCarouselState extends State<_MarketingCarousel> {
  final _controller = PageController();
  int _current = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(_MarketingCarousel old) {
    super.didUpdateWidget(old);
    if (old.slides.length != widget.slides.length) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.slides.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        final next = (_current + 1) % widget.slides.length;
        _controller.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = widget.slides;
    // Fallback: single slide using the default hero image
    final items = slides.isEmpty
        ? [const Slide(id: '_', imageUrl: AppConfig.imgHero, title: '', caption: '', sortOrder: 0)]
        : slides;

    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: items.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => _SlideItem(
              slide: items[i],
              greeting: i == 0 ? widget.greeting : '',
              l10n: widget.l10n,
              onBook: widget.onBook,
            ),
          ),
          // Dots indicator
          if (items.length > 1)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(items.length, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _current == i ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _current == i
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              ),
            ),
        ],
      ),
    );
  }
}

class _SlideItem extends StatelessWidget {
  final Slide slide;
  final String greeting;
  final AppLocalizations l10n;
  final VoidCallback onBook;

  const _SlideItem({
    required this.slide,
    required this.greeting,
    required this.l10n,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        if (slide.imageUrl.isNotEmpty)
          CachedNetworkImage(
            imageUrl: slide.imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => Shimmer.fromColors(
              baseColor: const Color(0xFF1565C0),
              highlightColor: const Color(0xFF42A5F5),
              child: const ColoredBox(color: Color(0xFF1565C0)),
            ),
            errorWidget: (_, __, ___) => const _DefaultHeroBg(),
          )
        else
          const _DefaultHeroBg(),

        // Dark gradient overlay so text is always readable
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xBB000000), Color(0x44000000), Color(0xCC000000)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),

        // Text content
        Positioned(
          left: 20,
          right: 20,
          bottom: 28,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (greeting.isNotEmpty)
                Text(l10n.helloName(greeting),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
              if (slide.title.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(slide.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
              ],
              if (slide.caption.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(slide.caption,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
              ],
              if (greeting.isNotEmpty || slide.title.isEmpty) ...[
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onBook,
                  icon: const Icon(Icons.water_drop),
                  label: Text(l10n.bookAWash),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0D47A1),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 10),
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DefaultHeroBg extends StatelessWidget {
  const _DefaultHeroBg();

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF00ACC1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
}

class _GradientFill extends StatelessWidget {
  final List<Color> colors;
  const _GradientFill(this.colors);

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
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
