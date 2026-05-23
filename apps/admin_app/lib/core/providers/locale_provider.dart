import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _load();
  }

  Future<void> _load() async {
    final saved = await readPref('app_locale');
    if (saved == 'ar') state = const Locale('ar');
  }

  Future<void> toggle() async {
    final next = state.languageCode == 'ar'
        ? const Locale('en')
        : const Locale('ar');
    state = next;
    await writePref('app_locale', next.languageCode);
  }
}

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) => LocaleNotifier());
