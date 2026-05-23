import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/locale_provider.dart';

class LanguageToggleButton extends ConsumerWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final iconColor = IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;
    return TextButton(
      onPressed: () => ref.read(localeProvider.notifier).toggle(),
      style: TextButton.styleFrom(foregroundColor: iconColor),
      child: Text(
        isAr ? 'EN' : 'عربي',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }
}
