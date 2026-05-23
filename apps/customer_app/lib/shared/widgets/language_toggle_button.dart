import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/locale_provider.dart';

class LanguageToggleButton extends ConsumerWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final fgColor = Theme.of(context).appBarTheme.foregroundColor ??
        Theme.of(context).colorScheme.onPrimary;
    return TextButton(
      onPressed: () => ref.read(localeProvider.notifier).toggle(),
      child: Text(
        isAr ? 'EN' : 'عربي',
        style: TextStyle(
            color: fgColor, fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }
}
