import 'package:flutter/material.dart';

/// Okuma teması — uygulama ThemeMode'dan ayrı.
enum ReadingTheme {
  light,
  dark,
  sepia,
}

/// Kalıcı uygulama + okuma varsayılanları.
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.dark,
    this.readingTheme = ReadingTheme.dark,
    this.fontSize = 18,
    this.paginated = true,
  });

  final ThemeMode themeMode;
  final ReadingTheme readingTheme;
  final double fontSize;
  final bool paginated;

  bool get isDarkTheme => themeMode == ThemeMode.dark;

  AppSettings copyWith({
    ThemeMode? themeMode,
    ReadingTheme? readingTheme,
    double? fontSize,
    bool? paginated,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      readingTheme: readingTheme ?? this.readingTheme,
      fontSize: fontSize ?? this.fontSize,
      paginated: paginated ?? this.paginated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode.name,
      'readingTheme': readingTheme.name,
      'fontSize': fontSize,
      'paginated': paginated,
    };
  }

  factory AppSettings.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return const AppSettings();
    final rawMode = map['themeMode'] as String?;
    // Eski "system" kayıtları ve bilinmeyen değerler → koyu.
    final themeMode = rawMode == ThemeMode.light.name
        ? ThemeMode.light
        : ThemeMode.dark;
    return AppSettings(
      themeMode: themeMode,
      readingTheme: ReadingTheme.values.firstWhere(
        (e) => e.name == map['readingTheme'],
        orElse: () => ReadingTheme.dark,
      ),
      fontSize: (map['fontSize'] as num?)?.toDouble() ?? 18,
      paginated: map['paginated'] as bool? ?? true,
    );
  }
}
