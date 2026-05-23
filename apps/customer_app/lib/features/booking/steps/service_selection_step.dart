import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.chooseYourService,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(l10n.selectWashType,
                    style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 32),
                _ServiceCard(
                  title: l10n.exteriorOnly,
                  description: l10n.exteriorOnlyDesc,
                  price: '195 EGP',
                  icon: Icons.car_crash_outlined,
                  features: [
                    l10n.featExteriorWash,
                    l10n.featWheelCleaning,
                    l10n.featTowelDry,
                    l10n.featWindowCleaning,
                  ],
                  color: Colors.blue,
                  isSelected: selected == ServiceType.exteriorOnly,
                  onTap: () => ref
                      .read(bookingFlowProvider.notifier)
                      .setServiceType(ServiceType.exteriorOnly),
                ),
                const SizedBox(height: 16),
                _ServiceCard(
                  title: l10n.interiorOnly,
                  description: l10n.interiorOnlyDesc,
                  price: '220 EGP',
                  icon: Icons.airline_seat_recline_extra_outlined,
                  features: [
                    l10n.featVacuum,
                    l10n.featDashboardWipe,
                    l10n.featWindowInterior,
                    l10n.featAirFreshener,
                  ],
                  color: Colors.teal,
                  isSelected: selected == ServiceType.interiorOnly,
                  onTap: () => ref
                      .read(bookingFlowProvider.notifier)
                      .setServiceType(ServiceType.interiorOnly),
                ),
                const SizedBox(height: 16),
                _ServiceCard(
                  title: l10n.fullService,
                  description: l10n.fullServiceDesc,
                  price: '250 EGP',
                  icon: Icons.cleaning_services,
                  features: [
                    l10n.featEverythingExterior,
                    l10n.featVacuum,
                    l10n.featDashboardWipe,
                    l10n.featWindowInterior,
                    l10n.featAirFreshener,
                  ],
                  color: Colors.purple,
                  isSelected: selected == ServiceType.fullService,
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
  final String title;
  final String description;
  final String price;
  final IconData icon;
  final List<String> features;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.title,
    required this.description,
    required this.price,
    required this.icon,
    required this.features,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? color : Colors.grey[300]!,
          width: isSelected ? 2.5 : 1,
        ),
        color: isSelected ? color.withOpacity(0.05) : Colors.white,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(description,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(price,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                ],
              ),
              const SizedBox(height: 12),
              ...features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.check, size: 16, color: color),
                        const SizedBox(width: 6),
                        Text(f, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  )),
              if (isSelected)
                Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(Icons.check_circle, color: color),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
