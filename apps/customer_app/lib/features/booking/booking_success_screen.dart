import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';

class BookingSuccessScreen extends StatefulWidget {
  const BookingSuccessScreen({super.key});

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim =
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim =
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.4, 1.0));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated success circle
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.statusCompleted.withOpacity(0.12),
                    border: Border.all(
                        color: AppColors.statusCompleted, width: 3),
                  ),
                  child: Icon(Icons.check_rounded,
                      color: AppColors.statusCompleted, size: 64),
                ),
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    Text(
                      l10n.bookingConfirmedTitle,
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.bookingConfirmedBody,
                      style: TextStyle(
                          fontSize: 15, color: Colors.grey[600], height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    FilledButton.icon(
                      onPressed: () => context.go('/history'),
                      icon: const Icon(Icons.receipt_long),
                      label: Text(l10n.viewMyBookings),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/home'),
                      icon: const Icon(Icons.home_outlined),
                      label: Text(l10n.backToHome),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
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
