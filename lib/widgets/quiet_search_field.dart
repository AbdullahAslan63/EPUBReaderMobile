import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

class QuietSearchField extends StatelessWidget {
  const QuietSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.showClear = false,
    this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final bool showClear;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: SizedBox(
        height: 42,
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(Icons.search, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: text.bodyMedium,
                cursorColor: scheme.primary,
                decoration: InputDecoration(
                  isCollapsed: true,
                  filled: false,
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            if (showClear)
              IconButton(
                tooltip: 'Temizle',
                onPressed: onClear,
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              )
            else
              const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
