import 'package:flutter/material.dart';

import '../../models/app_settings.dart';
import '../../utils/font_size_limits.dart';
import '../../widgets/reading_theme_chips.dart';

/// Okuma stil paneli — font, tema, kaydırma modu, işaret.
Future<void> showReaderStylePanel({
  required BuildContext context,
  required double fontSize,
  required ReadingTheme readingTheme,
  required bool paginated,
  required ValueChanged<double> onFontSizeChanged,
  required ValueChanged<ReadingTheme> onReadingThemeChanged,
  required ValueChanged<bool> onPaginatedChanged,
  required VoidCallback onAddBookmark,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return _ReaderStylePanelBody(
        fontSize: fontSize,
        readingTheme: readingTheme,
        paginated: paginated,
        onFontSizeChanged: onFontSizeChanged,
        onReadingThemeChanged: onReadingThemeChanged,
        onPaginatedChanged: onPaginatedChanged,
        onAddBookmark: onAddBookmark,
      );
    },
  );
}

class _ReaderStylePanelBody extends StatefulWidget {
  const _ReaderStylePanelBody({
    required this.fontSize,
    required this.readingTheme,
    required this.paginated,
    required this.onFontSizeChanged,
    required this.onReadingThemeChanged,
    required this.onPaginatedChanged,
    required this.onAddBookmark,
  });

  final double fontSize;
  final ReadingTheme readingTheme;
  final bool paginated;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<ReadingTheme> onReadingThemeChanged;
  final ValueChanged<bool> onPaginatedChanged;
  final VoidCallback onAddBookmark;

  @override
  State<_ReaderStylePanelBody> createState() => _ReaderStylePanelBodyState();
}

class _ReaderStylePanelBodyState extends State<_ReaderStylePanelBody> {
  late double _fontSize = widget.fontSize;
  late ReadingTheme _theme = widget.readingTheme;
  late bool _paginated = widget.paginated;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final size = FontSizeLimits.clamp(_fontSize);
    final preview = size.clamp(FontSizeLimits.min, 40.0);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Okuma stili',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text('Yazı boyutu', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: size <= FontSizeLimits.min
                    ? null
                    : () {
                        final next = FontSizeLimits.clamp(size - 2);
                        setState(() => _fontSize = next);
                        widget.onFontSizeChanged(next);
                      },
                icon: const Text('A', style: TextStyle(fontSize: 14)),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Aa',
                      style: TextStyle(fontSize: preview + 4),
                    ),
                    Text('${size.round()}'),
                    Slider(
                      min: FontSizeLimits.min,
                      max: FontSizeLimits.max,
                      divisions: FontSizeLimits.divisions,
                      value: size,
                      onChanged: (value) {
                        setState(() => _fontSize = value);
                        widget.onFontSizeChanged(value);
                      },
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: size >= FontSizeLimits.max
                    ? null
                    : () {
                        final next = FontSizeLimits.clamp(size + 2);
                        setState(() => _fontSize = next);
                        widget.onFontSizeChanged(next);
                      },
                icon: const Text('A', style: TextStyle(fontSize: 22)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Okuma teması', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ReadingThemeChips(
            value: _theme,
            onChanged: (theme) {
              setState(() => _theme = theme);
              widget.onReadingThemeChanged(theme);
            },
          ),
          const SizedBox(height: 16),
          Text('Kaydırma', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                label: Text('Sayfalı'),
                icon: Icon(Icons.swipe_outlined, size: 18),
              ),
              ButtonSegment(
                value: false,
                label: Text('Dikey kaydır'),
                icon: Icon(Icons.swap_vert, size: 18),
              ),
            ],
            selected: {_paginated},
            onSelectionChanged: (selected) {
              setState(() => _paginated = selected.first);
              widget.onPaginatedChanged(selected.first);
            },
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () {
              Navigator.pop(context);
              widget.onAddBookmark();
            },
            icon: const Icon(Icons.bookmark_add_outlined),
            label: const Text('İşaret ekle'),
          ),
        ],
      ),
    );
  }
}
