import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../theme/app_tokens.dart';
import '../utils/reading_theme_mapper.dart';

/// Okuma teması — renk örneği + kısa etiket.
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
          _Swatch(
            label: readingThemeLabel(theme),
            background: readingThemeBackground(theme),
            foreground: readingThemeForeground(theme),
            selected: value == theme,
            onTap: () => onChanged(theme),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.label,
    required this.background,
    required this.foreground,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radius),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: scheme.outline),
                ),
                child: Text(
                  'A',
                  style: TextStyle(
                    color: foreground,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(label, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}
