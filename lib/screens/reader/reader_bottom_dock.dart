import 'package:flutter/material.dart';

import '../../models/app_settings.dart';
import '../../theme/app_tokens.dart';
import '../../utils/font_size_limits.dart';
import '../../widgets/reading_theme_chips.dart';

enum ReaderDockPanel { none, font, theme }

class ReaderBottomDock extends StatelessWidget {
  const ReaderBottomDock({
    super.key,
    required this.fontSize,
    required this.readingTheme,
    required this.paginated,
    required this.expanded,
    required this.onFihrist,
    required this.onToggleFont,
    required this.onToggleTheme,
    required this.onTogglePaginated,
    required this.onBookmark,
    required this.onFontSizeChanged,
    this.onFontSizeChangeEnd,
    required this.onReadingThemeChanged,
  });

  final double fontSize;
  final ReadingTheme readingTheme;
  final bool paginated;
  final ReaderDockPanel expanded;
  final VoidCallback onFihrist;
  final VoidCallback onToggleFont;
  final VoidCallback onToggleTheme;
  final VoidCallback onTogglePaginated;
  final VoidCallback onBookmark;
  final ValueChanged<double> onFontSizeChanged;
  final VoidCallback? onFontSizeChangeEnd;
  final ValueChanged<ReadingTheme> onReadingThemeChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = FontSizeLimits.clamp(fontSize);

    return Material(
      color: scheme.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: AppTokens.chromeAnim,
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: switch (expanded) {
                ReaderDockPanel.none => const SizedBox(width: double.infinity),
                ReaderDockPanel.font => _FontPanel(
                  size: size,
                  onChanged: onFontSizeChanged,
                  onChangeEnd: onFontSizeChangeEnd,
                ),
                ReaderDockPanel.theme => _ThemePanel(
                  value: readingTheme,
                  onChanged: onReadingThemeChanged,
                ),
              },
            ),
            SizedBox(
              height: AppTokens.dockHeight,
              child: Row(
                children: [
                  _DockButton(
                    tooltip: 'Fihrist',
                    label: 'Fihrist',
                    selected: false,
                    onPressed: onFihrist,
                    icon: Icons.list_alt,
                  ),
                  _DockButton(
                    tooltip: 'Yazı boyutu',
                    label: 'Yazı',
                    selected: expanded == ReaderDockPanel.font,
                    onPressed: onToggleFont,
                    child: Text(
                      'Aa',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: expanded == ReaderDockPanel.font
                            ? scheme.primary
                            : scheme.onSurface,
                      ),
                    ),
                  ),
                  _DockButton(
                    tooltip: 'Tema',
                    label: 'Tema',
                    selected: expanded == ReaderDockPanel.theme,
                    onPressed: onToggleTheme,
                    icon: Icons.contrast,
                  ),
                  _DockButton(
                    tooltip: paginated ? 'Sayfalı' : 'Kaydırmalı',
                    label: paginated ? 'Sayfa' : 'Kaydır',
                    selected: false,
                    onPressed: onTogglePaginated,
                    icon: paginated
                        ? Icons.chrome_reader_mode_outlined
                        : Icons.swap_vert,
                  ),
                  _DockButton(
                    tooltip: 'İşaret',
                    label: 'İşaret',
                    selected: false,
                    onPressed: onBookmark,
                    icon: Icons.bookmark_add_outlined,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FontPanel extends StatelessWidget {
  const _FontPanel({
    required this.size,
    required this.onChanged,
    this.onChangeEnd,
  });

  final double size;
  final ValueChanged<double> onChanged;
  final VoidCallback? onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              'Yazı boyutu',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'Küçült',
                onPressed: size <= FontSizeLimits.min
                    ? null
                    : () {
                        onChanged(FontSizeLimits.clamp(size - 2));
                        onChangeEnd?.call();
                      },
                icon: Text(
                  'A',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Expanded(
                child: Slider(
                  min: FontSizeLimits.min,
                  max: FontSizeLimits.max,
                  divisions: FontSizeLimits.divisions,
                  value: size,
                  label: '${size.round()}',
                  onChanged: onChanged,
                  onChangeEnd: (_) => onChangeEnd?.call(),
                ),
              ),
              SizedBox(
                width: 28,
                child: Text(
                  '${size.round()}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              IconButton(
                tooltip: 'Büyüt',
                onPressed: size >= FontSizeLimits.max
                    ? null
                    : () {
                        onChanged(FontSizeLimits.clamp(size + 2));
                        onChangeEnd?.call();
                      },
                icon: Text(
                  'A',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemePanel extends StatelessWidget {
  const _ThemePanel({required this.value, required this.onChanged});

  final ReadingTheme value;
  final ValueChanged<ReadingTheme> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tema', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          ReadingThemeChips(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.tooltip,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.icon,
    this.child,
  });

  final String tooltip;
  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final IconData? icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurface;
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              child ?? Icon(icon, size: 20, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
