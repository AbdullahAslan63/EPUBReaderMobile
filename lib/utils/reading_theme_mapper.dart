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
  }
}
