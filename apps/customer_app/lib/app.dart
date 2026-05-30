import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_colors.dart';
import 'core/l10n/app_localizations.dart';
import 'core/providers/locale_provider.dart';
import 'core/services/ws_service.dart';
import 'shared/router/app_router.dart';

class WashlyApp extends ConsumerWidget {
  const WashlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: 'Washly',
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          elevation: 8,
          shadowColor: Colors.black26,
          indicatorColor: AppColors.primary.withOpacity(0.12),
          iconTheme: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const IconThemeData(color: AppColors.primary, size: 24);
            }
            return IconThemeData(color: Colors.grey[600], size: 24);
          }),
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              );
            }
            return TextStyle(color: Colors.grey[600], fontSize: 12);
          }),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    if (type != 'booking_updated') return;

    final booking = event['booking'] as Map<String, dynamic>?;
    final status = booking?['status'] as String? ?? '';
    final serviceType = (booking?['service_type'] as String? ?? '').replaceAll('_', ' ');

    _show(
      icon: Icons.local_car_wash,
      title: 'Booking Updated',
      message: '$serviceType booking is now ${_label(status)}',
      color: _color(status),
    );
  }

  String _label(String s) => switch (s) {
        'confirmed' => 'Confirmed ✓',
        'in_progress' => 'In Progress',
        'completed' => 'Completed ✓',
        'cancelled' => 'Cancelled',
        _ => s,
      };

  Color _color(String s) => switch (s) {
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
        duration: const Duration(seconds: 4),
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
