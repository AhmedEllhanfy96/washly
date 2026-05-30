import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/config/app_config.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/models/booking.dart';
import '../../../core/providers/booking_provider.dart';
import '../../../shared/widgets/primary_button.dart';

class ServiceSelectionStep extends ConsumerWidget {
  final VoidCallback onNext;
  const ServiceSelectionStep({super.key, required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(bookingFlowProvider).serviceType;
    final l10n = context.l10n;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.chooseYourService,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(l10n.selectWashType,
                    style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 20),
                _ServiceCard(
                  imageUrl: AppConfig.imgExterior,
                  title: l10n.exteriorOnly,
                  description: l10n.exteriorOnlyDesc,
                  price: '${AppConfig.priceExteriorOnly} ${AppConfig.currency}',
                  features: [
                    l10n.featExteriorWash,
                    l10n.featWheelCleaning,
                    l10n.featTowelDry,
                    l10n.featWindowCleaning,
                  ],
                  gradientColors: const [Color(0xFF1565C0), Color(0xFF00ACC1)],
                  isSelected: selected == ServiceType.exteriorOnly,
                  onTap: () => ref
                      .read(bookingFlowProvider.notifier)
                      .setServiceType(ServiceType.exteriorOnly),
                ),
                const SizedBox(height: 16),
                _ServiceCard(
                  imageUrl: AppConfig.imgInterior,
                  title: l10n.interiorOnly,
                  description: l10n.interiorOnlyDesc,
                  price: '${AppConfig.priceInteriorOnly} ${AppConfig.currency}',
                  features: [
                    l10n.featVacuum,
                    l10n.featDashboardWipe,
                    l10n.featWindowInterior,
                    l10n.featAirFreshener,
                  ],
                  gradientColors: const [Color(0xFF00695C), Color(0xFF4CAF50)],
                  isSelected: selected == ServiceType.interiorOnly,
                  onTap: () => ref
                      .read(bookingFlowProvider.notifier)
                      .setServiceType(ServiceType.interiorOnly),
                ),
                const SizedBox(height: 16),
                _ServiceCard(
                  imageUrl: AppConfig.imgFullService,
                  title: l10n.fullService,
                  description: l10n.fullServiceDesc,
                  price: '${AppConfig.priceFullService} ${AppConfig.currency}',
                  features: [
                    l10n.featEverythingExterior,
                    l10n.featVacuum,
                    l10n.featDashboardWipe,
                    l10n.featWindowInterior,
                    l10n.featAirFreshener,
                  ],
                  gradientColors: const [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
                  isSelected: selected == ServiceType.fullService,
                  badge: 'BEST VALUE',
                  onTap: () => ref
                      .read(bookingFlowProvider.notifier)
                      .setServiceType(ServiceType.fullService),
                ),
              ],
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
            label: l10n.continueBtn,
            onPressed: selected != null ? onNext : null,
          ),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String description;
  final String price;
  final List<String> features;
  final List<Color> gradientColors;
  final bool isSelected;
  final String? badge;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.price,
    required this.features,
    required this.gradientColors,
    required this.isSelected,
    required this.onTap,
    this.badge,
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
              // Image header
              SizedBox(
                height: 110,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Shimmer.fromColors(
                        baseColor: gradientColors.first,
                        highlightColor: gradientColors.last,
                        child: Container(color: gradientColors.first),
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
                    // Gradient overlay
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
                    // Price + title overlay
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 12,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.5)),
                            ),
                            child: Text(
                              price,
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
                    // Badge
                    if (badge != null)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    // Selected check
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
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Icon(Icons.check, color: color, size: 18),
                        ),
                      ),
                  ],
                ),
              ),
              // Features list
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: features
                          .map((f) => Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle,
                                      size: 14, color: color),
                                  const SizedBox(width: 4),
                                  Text(f,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700])),
                                ],
                              ))
                          .toList(),
                    ),
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
