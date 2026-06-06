import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/config/app_config.dart';
import '../../../core/models/service.dart';
import '../../../core/providers/booking_provider.dart';
import '../../../core/providers/services_provider.dart';
import '../../../shared/widgets/primary_button.dart';

// Colour themes cycle for services (index % themes.length)
const _kThemes = [
  [Color(0xFF1565C0), Color(0xFF00ACC1)],
  [Color(0xFF00695C), Color(0xFF4CAF50)],
  [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
  [Color(0xFFB71C1C), Color(0xFFE57373)],
  [Color(0xFFE65100), Color(0xFFFFB300)],
];

class ServiceSelectionStep extends ConsumerWidget {
  final VoidCallback onNext;
  const ServiceSelectionStep({super.key, required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(bookingFlowProvider).service;
    final servicesAsync = ref.watch(servicesProvider);

    return Column(
      children: [
        Expanded(
          child: servicesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 40, color: Colors.red),
                  const SizedBox(height: 8),
                  Text('Could not load services: $e'),
                  TextButton(
                    onPressed: () => ref.invalidate(servicesProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (services) => SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Choose Your Service',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Select the wash type that suits you',
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 20),
                  ...services.asMap().entries.map((entry) {
                    final i = entry.key;
                    final svc = entry.value;
                    final theme = _kThemes[i % _kThemes.length];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _ServiceCard(
                        service: svc,
                        gradientColors: theme,
                        isSelected: selected?.id == svc.id,
                        onTap: () => ref
                            .read(bookingFlowProvider.notifier)
                            .setService(svc),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: PrimaryButton(
            label: 'Continue',
            onPressed: selected != null ? onNext : null,
          ),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final WashService service;
  final List<Color> gradientColors;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.service,
    required this.gradientColors,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = gradientColors.first;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? color : Colors.grey[300]!,
          width: isSelected ? 2.5 : 1,
        ),
        boxShadow: isSelected
            ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 110,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    service.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: service.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Shimmer.fromColors(
                              baseColor: gradientColors.first,
                              highlightColor: gradientColors.last,
                              child: Container(color: gradientColors.first),
                            ),
                            errorWidget: (_, __, ___) => _GradientBox(gradientColors),
                          )
                        : _GradientBox(gradientColors),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            gradientColors.last.withOpacity(0.6),
                            gradientColors.first.withOpacity(0.9),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.2, 0.65, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 12,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              service.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.5)),
                            ),
                            child: Text(
                              '${service.price} ${AppConfig.currency}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (service.badge.isNotEmpty)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            service.badge,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    if (isSelected)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: color.withOpacity(0.3), blurRadius: 6),
                            ],
                          ),
                          child: Icon(Icons.check, color: color, size: 18),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (service.description.isNotEmpty)
                      Text(
                        service.description,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    if (service.features.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: service.features
                            .map((f) => Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, size: 14, color: color),
                                    const SizedBox(width: 4),
                                    Text(f,
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey[700])),
                                  ],
                                ))
                            .toList(),
                      ),
                    ],
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

class _GradientBox extends StatelessWidget {
  final List<Color> colors;
  const _GradientBox(this.colors);

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
