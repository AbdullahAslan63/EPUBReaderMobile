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

IconData readingThemeIcon(ReadingTheme theme) {
  switch (theme) {
    case ReadingTheme.light:
      return Icons.light_mode_outlined;
    case ReadingTheme.dark:
      return Icons.dark_mode_outlined;
    case ReadingTheme.sepia:
      return Icons.auto_stories_outlined;
    case ReadingTheme.softDark:
      return Icons.nightlight_round;
  }
}
