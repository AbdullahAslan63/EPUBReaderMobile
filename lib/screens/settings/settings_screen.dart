import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../providers/settings_provider.dart';
import '../../utils/font_size_limits.dart';
import '../../widgets/reading_theme_chips.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        final scheme = Theme.of(context).colorScheme;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _SettingsCard(
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                secondary: Icon(
                  settings.isDarkTheme
                      ? Icons.dark_mode
                      : Icons.dark_mode_outlined,
                  color: scheme.primary,
                ),
                title: const Text('Koyu tema'),
                subtitle: Text(
                  settings.isDarkTheme ? 'Açık' : 'Kapalı',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                value: settings.isDarkTheme,
                onChanged: (value) {
                  ref.read(appSettingsProvider.notifier).setDarkTheme(value);
                },
              ),
            ),
            const SizedBox(height: 12),
            _SettingsCard(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Okuma teması',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ReadingThemeChips(
                      value: settings.readingTheme,
                      onChanged: (theme) {
                        ref
                            .read(appSettingsProvider.notifier)
                            .setReadingTheme(theme);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SettingsCard(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                child: _FontSizeControl(
                  fontSize: settings.fontSize,
                  onChanged: (value) {
                    ref.read(appSettingsProvider.notifier).setFontSize(value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SettingsCard(
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: const Text('Sayfalı okuma'),
                subtitle: const Text('Kapalıysa kaydırmalı mod'),
                value: settings.paginated,
                onChanged: (value) {
                  ref.read(appSettingsProvider.notifier).setPaginated(value);
                },
              ),
            ),
            const SizedBox(height: 24),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.data?.version ?? '1.0.0';
                final build = snapshot.data?.buildNumber ?? '1';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('EPUB Kütüphanesi'),
                  subtitle: Text(
                    'v$version+$build — çevrimdışı EPUB okuyucu',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Ayarlar yüklenemedi: $e')),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.45,
          ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _FontSizeControl extends StatelessWidget {
  const _FontSizeControl({
    required this.fontSize,
    required this.onChanged,
  });

  final double fontSize;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final size = FontSizeLimits.clamp(fontSize);
    final preview = size.clamp(FontSizeLimits.min, 40.0);
    return Column(
      children: [
        Text(
          'Yazı boyutu',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Aa',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontSize: preview + 4,
                height: 1.1,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          '${size.round()}',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        Row(
          children: [
            IconButton(
              tooltip: 'Küçült',
              onPressed: size <= FontSizeLimits.min
                  ? null
                  : () => onChanged(FontSizeLimits.clamp(size - 2)),
              icon: const Text(
                'A',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
              ),
            ),
            IconButton(
              tooltip: 'Büyüt',
              onPressed: size >= FontSizeLimits.max
                  ? null
                  : () => onChanged(FontSizeLimits.clamp(size + 2)),
              icon: const Text(
                'A',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
