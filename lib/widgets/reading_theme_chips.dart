import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../utils/reading_theme_mapper.dart';

/// Okuma teması seçici — 4 seçenek (açık/koyu/sepya/yumuşak koyu).
class ReadingThemeChips extends StatelessWidget {
  const ReadingThemeChips({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ReadingTheme value;
  final ValueChanged<ReadingTheme> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final theme in ReadingTheme.values)
          ChoiceChip(
            avatar: Icon(readingThemeIcon(theme), size: 18),
            label: Text(readingThemeLabel(theme)),
            selected: value == theme,
            onSelected: (_) => onChanged(theme),
          ),
      ],
    );
  }
}
