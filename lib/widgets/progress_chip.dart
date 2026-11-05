import 'package:flutter/material.dart';

class ProgressChip extends StatelessWidget {
  const ProgressChip({super.key, required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    final value = (percent * 100).clamp(0, 100).round();
    return Text(
      '%$value',
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
