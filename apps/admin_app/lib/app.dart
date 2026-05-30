import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_colors.dart';
import 'core/l10n/app_localizations.dart';
import 'core/providers/locale_provider.dart';
import 'core/services/ws_service.dart';
import 'shared/router/app_router.dart';

class WashlyAdminApp extends ConsumerWidget {
  const WashlyAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(adminRouterProvider);
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: 'Washly Admin',
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.backgroundLight,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: AppColors.backgroundLight,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      builder: (ctx, child) => _WsNotificationLayer(child: child!),
      routerConfig: router,
    );
  }
}

// ── WS notification layer ────────────────────────────────────────────────────

class _WsNotificationLayer extends ConsumerStatefulWidget {
  final Widget child;
  const _WsNotificationLayer({required this.child});

  @override
  ConsumerState<_WsNotificationLayer> createState() =>
      _WsNotificationLayerState();
}

class _WsNotificationLayerState extends ConsumerState<_WsNotificationLayer> {
  StreamSubscription<Map<String, dynamic>>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = ref.read(wsServiceProvider).events.listen(_onEvent);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onEvent(Map<String, dynamic> event) {
    if (!mounted) return;
    final type = event['type'] as String?;

    switch (type) {
      case 'booking_created':
        final booking = event['booking'] as Map<String, dynamic>?;
        final serviceType = (booking?['service_type'] as String? ?? '')
            .replaceAll('_', ' ');
        final customer = _customerName(booking);
        _show(
          icon: Icons.notifications_active_outlined,
          title: 'New Booking Request!',
          message: '$serviceType — $customer',
          color: AppColors.statusPending,
        );
      case 'booking_updated':
        final booking = event['booking'] as Map<String, dynamic>?;
        final status = booking?['status'] as String? ?? '';
        final serviceType = (booking?['service_type'] as String? ?? '')
            .replaceAll('_', ' ');
        _show(
          icon: Icons.update_outlined,
          title: 'Booking Updated',
          message: '$serviceType → ${_label(status)}',
          color: _color(status),
        );
    }
  }

  String _customerName(Map<String, dynamic>? booking) {
    final user = booking?['user'] as Map<String, dynamic>?;
    return user?['name'] as String? ?? 'Customer';
  }

  String _label(String s) => switch (s) {
        'pending' => 'Pending',
        'confirmed' => 'Confirmed',
        'in_progress' => 'In Progress',
        'completed' => 'Completed',
        'cancelled' => 'Cancelled',
        _ => s,
      };

  Color _color(String s) => switch (s) {
        'pending' => AppColors.statusPending,
        'confirmed' => AppColors.statusConfirmed,
        'in_progress' => AppColors.statusInProgress,
        'completed' => AppColors.statusCompleted,
        'cancelled' => AppColors.statusCancelled,
        _ => AppColors.primary,
      };

  void _show({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        elevation: 6,
        content: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  Text(message,
                      style:
                          TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
