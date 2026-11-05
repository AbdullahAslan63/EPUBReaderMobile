import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import 'services_provider.dart';

final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);

class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() {
    return ref.read(settingsServiceProvider).getSettings();
  }

  Future<void> _persist(AppSettings settings) async {
    state = AsyncData(settings);
    await ref.read(settingsServiceProvider).saveSettings(settings);
  }

  Future<void> setDarkTheme(bool enabled) async {
    final current = state.valueOrNull ?? const AppSettings();
    final mode = enabled ? ThemeMode.dark : ThemeMode.light;
    var next = current.copyWith(themeMode: mode);
    // Uygulama teması ile okuma teması senkron (sepya koru).
    if (current.readingTheme != ReadingTheme.sepia) {
      next = next.copyWith(
        readingTheme: enabled ? ReadingTheme.dark : ReadingTheme.light,
      );
    }
    await _persist(next);
  }

  Future<void> setReadingTheme(ReadingTheme theme) async {
    final current = state.valueOrNull ?? const AppSettings();
    await _persist(current.copyWith(readingTheme: theme));
  }

  Future<void> setFontSize(double size) async {
    final current = state.valueOrNull ?? const AppSettings();
    final clamped = size.clamp(12.0, 32.0).toDouble();
    await _persist(current.copyWith(fontSize: clamped));
  }

  Future<void> setPaginated(bool paginated) async {
    final current = state.valueOrNull ?? const AppSettings();
    await _persist(current.copyWith(paginated: paginated));
  }
}
