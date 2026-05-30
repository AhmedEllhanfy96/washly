import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/models/booking.dart';
import '../../../core/models/time_slot.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/booking_provider.dart';
import '../../../core/providers/pricing_provider.dart';
import '../../../core/services/booking_service.dart';
import '../../../shared/widgets/primary_button.dart';

class ConfirmationStep extends ConsumerStatefulWidget {
  final VoidCallback onConfirmed;
  const ConfirmationStep({super.key, required this.onConfirmed});

  @override
  ConsumerState<ConfirmationStep> createState() => _ConfirmationStepState();
}

class _ConfirmationStepState extends ConsumerState<ConfirmationStep> {
  bool _loading = false;

  Future<void> _confirm() async {
    final flow = ref.read(bookingFlowProvider);
    if (!flow.isComplete) return;

    setState(() => _loading = true);
    try {
      final user = ref.read(authProvider).valueOrNull;
      final booking = Booking(
        id: '',
        userId: user?.id ?? '',
        car: flow.car!,
        serviceType: flow.serviceType!,
        location: flow.location!,
        scheduledAt: flow.selectedDate!,
        timeSlot: flow.selectedTimeSlot!,
        status: BookingStatus.pending,
        paymentMethod: flow.paymentMethod,
        createdAt: DateTime.now(),
      );
      await ref.read(bookingServiceProvider).createBooking(
            booking: booking,
            customerName: user?.name ?? '',
            customerPhone: user?.phone ?? '',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.bookingSubmitted),
            backgroundColor: Colors.green,
          ),
        );
        widget.onConfirmed();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(context.l10n.failedToSubmit(e.toString())),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _price(ServiceType? t, ServicePrices prices) => switch (t) {
        ServiceType.fullService => '${prices.fullService} ${AppConfig.currency}',
        ServiceType.interiorOnly => '${prices.interiorOnly} ${AppConfig.currency}',
        _ => '${prices.exteriorOnly} ${AppConfig.currency}',
      };

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(bookingFlowProvider);
    final prices = ref.watch(pricingProvider).valueOrNull ?? const ServicePrices(
      exteriorOnly: AppConfig.priceExteriorOnly,
      interiorOnly: AppConfig.priceInteriorOnly,
      fullService:  AppConfig.priceFullService,
    );
    final fmt = DateFormat('EEEE, MMMM d, yyyy');
    final l10n = context.l10n;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.confirmBooking,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(l10n.reviewBooking,
                    style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 24),

                _Section(title: l10n.stepCarDetails, children: [
                  _Row(l10n.makeAndModel,
                      '${flow.car?.make ?? ''} ${flow.car?.model ?? ''}'),
                  _Row(l10n.color, flow.car?.color ?? ''),
                  _Row(l10n.plate, flow.car?.plateNumber ?? ''),
                  if (flow.car?.year != null)
                    _Row(l10n.year, flow.car!.year!),
                ]),

                const SizedBox(height: 16),
                _Section(title: l10n.serviceLabel, children: [
                  _Row(l10n.serviceType,
                      flow.serviceType != null
                          ? l10n.serviceTypeName(flow.serviceType!)
                          : ''),
                  _Row(l10n.price, _price(flow.serviceType, prices)),
                ]),

                const SizedBox(height: 16),
                _Section(title: l10n.stepLocation, children: [
                  _Row(l10n.address, flow.location?.address ?? ''),
                ]),

                const SizedBox(height: 16),
                _Section(title: l10n.schedule, children: [
                  if (flow.selectedDate != null)
                    _Row(l10n.date, fmt.format(flow.selectedDate!)),
                  if (flow.selectedTimeSlot != null)
                    _Row(
                      l10n.window,
                      TimeSlot(
                        startTime: flow.selectedTimeSlot!,
                        endTime: TimeSlot.addTwoHours(flow.selectedTimeSlot!),
                        available: true,
                        maxBookings: 3,
                        currentBookings: 0,
                      ).displayLabel,
                    ),
                ]),

                const SizedBox(height: 20),

                // ── Payment method selection ──────────────────────────────
                Text('Payment Method',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _PaymentMethodSelector(
                  selected: flow.paymentMethod,
                  onChanged: (m) =>
                      ref.read(bookingFlowProvider.notifier).setPaymentMethod(m),
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
          child: Column(
            children: [
              if (flow.paymentMethod == PaymentMethod.instapay)
                _InstapayPanel(price: _price(flow.serviceType, prices))
              else if (flow.paymentMethod == PaymentMethod.credit_card)
                _CreditCardPanel(price: _price(flow.serviceType, prices)),
              const SizedBox(height: 12),
              PrimaryButton(
                label: l10n.submitBooking,
                onPressed: _confirm,
                isLoading: _loading,
                icon: Icons.check,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── InstaPay info panel ──────────────────────────────────────────────────────

class _InstapayPanel extends ConsumerWidget {
  final String price;
  const _InstapayPanel({required this.price});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(pricingProvider);

    return settings.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (s) {
        final hasNumber = s.instapayNumber.isNotEmpty;
        final hasLink = s.instapayLink.isNotEmpty;
        final hasSupport = s.supportPhone.isNotEmpty;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.mobile_friendly, color: Colors.blue[700], size: 18),
                const SizedBox(width: 8),
                Text('InstaPay Instructions',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                        fontSize: 13)),
              ]),
              const SizedBox(height: 10),

              if (hasNumber) ...[
                Text('Send $price to:',
                    style: TextStyle(color: Colors.blue[700], fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(s.instapayNumber,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                              letterSpacing: 1.2)),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy, size: 18, color: Colors.blue[600]),
                      tooltip: 'Copy number',
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: s.instapayNumber));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('InstaPay number copied'),
                          duration: Duration(seconds: 2),
                        ));
                      },
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  'Send payment via InstaPay. The number will be provided after booking is confirmed.',
                  style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                ),
              ],

              if (hasLink) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => launchUrl(
                        Uri.parse(s.instapayLink),
                        mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Open InstaPay'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue[700],
                      side: BorderSide(color: Colors.blue[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],

              if (hasSupport) ...[
                const Divider(height: 20),
                Row(
                  children: [
                    Icon(Icons.support_agent, size: 16, color: Colors.green[700]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'After sending, share screenshot with support:',
                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(s.supportPhone,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        final digits = s.supportPhone.replaceAll(RegExp(r'\D'), '');
                        launchUrl(
                            Uri.parse('${AppConfig.whatsAppUrl}$digits'),
                            mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.chat, size: 16, color: Color(0xFF25D366)),
                      label: const Text('WhatsApp',
                          style: TextStyle(color: Color(0xFF25D366), fontSize: 12)),
                      style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ── Credit card info panel ───────────────────────────────────────────────────

class _CreditCardPanel extends StatelessWidget {
  final String price;
  const _CreditCardPanel({required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.credit_card, color: Colors.purple[700], size: 18),
            const SizedBox(width: 8),
            Text('Credit Card Payment',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[800],
                    fontSize: 13)),
          ]),
          const SizedBox(height: 10),
          Text(
            'Amount to pay: $price',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.purple[900]),
          ),
          const SizedBox(height: 6),
          Text(
            'A payment link will be sent to you after the booking is confirmed.',
            style: TextStyle(fontSize: 12, color: Colors.purple[700]),
          ),
        ],
      ),
    );
  }
}

// ── Payment method selector ──────────────────────────────────────────────────

class _PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  const _PaymentMethodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MethodCard(
          method: PaymentMethod.cash,
          icon: Icons.payments_outlined,
          selected: selected == PaymentMethod.cash,
          color: AppColors.statusCompleted,
          onTap: () => onChanged(PaymentMethod.cash),
        ),
        const SizedBox(width: 12),
        _MethodCard(
          method: PaymentMethod.instapay,
          icon: Icons.mobile_friendly,
          selected: selected == PaymentMethod.instapay,
          color: AppColors.primary,
          onTap: () => onChanged(PaymentMethod.instapay),
        ),
        const SizedBox(width: 12),
        _MethodCard(
          method: PaymentMethod.credit_card,
          icon: Icons.credit_card,
          selected: selected == PaymentMethod.credit_card,
          color: Colors.purple,
          onTap: () => onChanged(PaymentMethod.credit_card),
        ),
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  final PaymentMethod method;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _MethodCard({
    required this.method,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.08) : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : Colors.grey[300]!,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? color : Colors.grey[500], size: 28),
              const SizedBox(height: 6),
              Text(
                method.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? color : Colors.grey[700],
                ),
              ),
              Text(
                switch (method) {
                  PaymentMethod.cash => 'Pay the worker',
                  PaymentMethod.instapay => 'Pay via app',
                  PaymentMethod.credit_card => 'Visa / Mastercard',
                },
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
