import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';

import '../models/app_settings.dart';

EpubTheme epubThemeFromReading(ReadingTheme theme) {
  switch (theme) {
    case ReadingTheme.dark:
      return EpubTheme.dark();
    case ReadingTheme.light:
      return EpubTheme.light();
    case ReadingTheme.sepia:
      return EpubTheme.custom(
        backgroundDecoration: const BoxDecoration(color: Color(0xFFFBF0D9)),
        foregroundColor: const Color(0xFF3B2F2F),
      );
    case ReadingTheme.softDark:
      return EpubTheme.custom(
        backgroundDecoration: const BoxDecoration(color: Color(0xFF1C1814)),
        foregroundColor: const Color(0xFFE8D5B5),
      );
  }
}

String readingThemeLabel(ReadingTheme theme) {
  switch (theme) {
    case ReadingTheme.light:
      return 'Açık';
    case ReadingTheme.dark:
      return 'Koyu';
    case ReadingTheme.sepia:
      return 'Sepya';
    case ReadingTheme.softDark:
      return 'Yumuşak koyu';
  }
}

Color readingThemeBackground(ReadingTheme theme) {
  switch (theme) {
    case ReadingTheme.light:
      return const Color(0xFFF7F4EF);
    case ReadingTheme.dark:
      return const Color(0xFF121311);
    case ReadingTheme.sepia:
      return const Color(0xFFFBF0D9);
    case ReadingTheme.softDark:
      return const Color(0xFF1C1814);
  }
}

Color readingThemeForeground(ReadingTheme theme) {
  switch (theme) {
    case ReadingTheme.light:
      return const Color(0xFF1A1916);
    case ReadingTheme.dark:
      return const Color(0xFFE8E4DC);
    case ReadingTheme.sepia:
      return const Color(0xFF3B2F2F);
    case ReadingTheme.softDark:
      return const Color(0xFFE8D5B5);
  }
}
