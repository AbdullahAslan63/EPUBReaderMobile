import 'package:flutter/material.dart';

import 'app_tokens.dart';

abstract final class AppTheme {
  static ThemeData get light => _theme(_lightScheme);

  static ThemeData get dark => _theme(_darkScheme);

  static ThemeData _theme(ColorScheme scheme) {
    final text = _textTheme(scheme);
    final radius = BorderRadius.circular(AppTokens.radius);
    final outline = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: scheme.outlineVariant),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTokens.radius),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.outlineVariant,
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 2,
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.outlineVariant,
        thumbColor: scheme.primary,
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: outline,
        enabledBorder: outline,
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.primary),
        ),
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.onSurface,
          textStyle: text.labelLarge,
        ),
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    const ink = TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.4);
    return TextTheme(
      headlineMedium: ink.copyWith(
        fontSize: 28,
        height: 1.15,
        color: scheme.onSurface,
      ),
      titleLarge: ink.copyWith(
        fontSize: 20,
        height: 1.2,
        color: scheme.onSurface,
      ),
      titleMedium: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.25,
      ).copyWith(color: scheme.onSurface),
      titleSmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: scheme.onSurfaceVariant,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.4, color: scheme.onSurface),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: scheme.onSurface),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.35,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ).copyWith(color: scheme.onSurface),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: scheme.onSurfaceVariant,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: scheme.onSurfaceVariant,
      ),
    );
  }

  static ColorScheme get _lightScheme => ColorScheme.fromSeed(
    seedColor: AppTokens.accent,
    brightness: Brightness.light,
    dynamicSchemeVariant: DynamicSchemeVariant.neutral,
    primary: AppTokens.accent,
    onPrimary: AppTokens.paper,
    primaryContainer: const Color(0xFFE4E1DA),
    onPrimaryContainer: AppTokens.ink,
    secondary: const Color(0xFF5C564E),
    onSecondary: AppTokens.paper,
    secondaryContainer: const Color(0xFFE6E1D8),
    onSecondaryContainer: const Color(0xFF241F1A),
    error: const Color(0xFF8C3A32),
    onError: const Color(0xFFFFF8F6),
    errorContainer: const Color(0xFFF3DDD9),
    onErrorContainer: const Color(0xFF3F1612),
    surface: AppTokens.paper,
    onSurface: AppTokens.ink,
    onSurfaceVariant: AppTokens.inkMuted,
    outline: AppTokens.hairline,
    outlineVariant: const Color(0xFFE3DED6),
    surfaceDim: const Color(0xFFE7E3DC),
    surfaceBright: const Color(0xFFFBF9F6),
    surfaceContainerLowest: const Color(0xFFFFFDFB),
    surfaceContainerLow: const Color(0xFFF7F5F1),
    surfaceContainer: AppTokens.paperRaised,
    surfaceContainerHigh: const Color(0xFFE4E0D8),
    surfaceContainerHighest: const Color(0xFFDAD6CE),
    inverseSurface: AppTokens.ink,
    onInverseSurface: AppTokens.paper,
    inversePrimary: AppTokens.accentOnDark,
    surfaceTint: Colors.transparent,
  );

  static ColorScheme get _darkScheme => ColorScheme.fromSeed(
    seedColor: AppTokens.accentOnDark,
    brightness: Brightness.dark,
    dynamicSchemeVariant: DynamicSchemeVariant.neutral,
    primary: AppTokens.accentOnDark,
    onPrimary: const Color(0xFF1A1916),
    primaryContainer: const Color(0xFF2A2926),
    onPrimaryContainer: AppTokens.inkSoft,
    secondary: const Color(0xFFB7B1A6),
    onSecondary: const Color(0xFF1A1916),
    secondaryContainer: const Color(0xFF2A2824),
    onSecondaryContainer: const Color(0xFFE4DDD2),
    error: const Color(0xFFE7B2AA),
    onError: const Color(0xFF3F1612),
    errorContainer: const Color(0xFF5C2A24),
    onErrorContainer: const Color(0xFFF8E4E0),
    surface: AppTokens.surfaceInk,
    onSurface: AppTokens.inkSoft,
    onSurfaceVariant: AppTokens.inkSoftMuted,
    outline: AppTokens.hairlineDark,
    outlineVariant: const Color(0xFF262624),
    surfaceDim: const Color(0xFF0C0C0B),
    surfaceBright: const Color(0xFF2A2A27),
    surfaceContainerLowest: const Color(0xFF0B0B0A),
    surfaceContainerLow: const Color(0xFF181816),
    surfaceContainer: AppTokens.surfaceInkRaised,
    surfaceContainerHigh: const Color(0xFF242422),
    surfaceContainerHighest: const Color(0xFF2E2E2B),
    inverseSurface: AppTokens.paper,
    onInverseSurface: AppTokens.ink,
    inversePrimary: AppTokens.accent,
    surfaceTint: Colors.transparent,
  );
}
