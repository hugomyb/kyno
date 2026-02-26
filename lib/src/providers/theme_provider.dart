import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'service_providers.dart';

class ThemeNotifier extends Notifier<ThemeMode> {
  static const String _storageKey = 'theme_mode';

  @override
  ThemeMode build() {
    final storage = ref.read(storageProvider);
    final savedMode = storage.getString(_storageKey);
    if (savedMode != null) {
      return ThemeMode.values.firstWhere(
        (mode) => mode.name == savedMode,
        orElse: () => ThemeMode.dark,
      );
    }
    return ThemeMode.dark; // Default
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final storage = ref.read(storageProvider);
    await storage.setString(_storageKey, mode.name);
  }

  void toggleTheme() {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(newMode);
  }

  bool get isDarkMode => state == ThemeMode.dark;
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);
