import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/providers/booking_provider.dart';
import 'steps/car_details_step.dart';
import 'steps/confirmation_step.dart';
import 'steps/location_step.dart';
import 'steps/service_selection_step.dart';
import 'steps/time_slot_step.dart';

class BookingFlowScreen extends ConsumerStatefulWidget {
  const BookingFlowScreen({super.key});

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  List<String> _steps(AppLocalizations l10n) => [
    l10n.stepCarDetails,
    l10n.stepServiceType,
    l10n.stepLocation,
    l10n.stepTimeSlot,
    l10n.stepConfirm,
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _back() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final steps = _steps(l10n);
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _back),
          title: Text(steps[_currentStep]),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(6),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / steps.length,
              backgroundColor: Colors.grey[200],
            ),
          ),
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            CarDetailsStep(onNext: _next),
            ServiceSelectionStep(onNext: _next),
            LocationStep(onNext: _next),
            TimeSlotStep(onNext: _next),
            ConfirmationStep(
              onConfirmed: () {
                ref.read(bookingFlowProvider.notifier).reset();
                context.go('/home');
              },
            ),
          ],
        ),
      ),
    );
  }
}
