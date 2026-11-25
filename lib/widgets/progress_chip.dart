import 'package:flutter/material.dart';

/// İnce ilerleme çizgisi + yüzde. [expand] üst sütunun genişliğini doldurur.
class ProgressChip extends StatelessWidget {
  const ProgressChip({super.key, required this.percent, this.expand = true});

  /// 0–1.
  final double percent;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value = percent.clamp(0.0, 1.0);
    final label = '%${(value * 100).round()}';
    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(1),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 2,
        backgroundColor: scheme.outlineVariant,
        color: scheme.primary,
      ),
    );

    return Row(
      children: [
        if (expand) Expanded(child: bar) else SizedBox(width: 56, child: bar),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
