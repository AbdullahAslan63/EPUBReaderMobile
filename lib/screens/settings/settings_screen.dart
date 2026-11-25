import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../providers/settings_provider.dart';
import '../../utils/font_size_limits.dart';
import '../../widgets/app_page_header.dart';
import '../../widgets/reading_theme_chips.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return Column(
      children: [
        const AppPageHeader(title: 'Ayarlar'),
        Expanded(
          child: settingsAsync.when(
            data: (settings) {
              final scheme = Theme.of(context).colorScheme;
              return ListView(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 28),
                children: [
                  const _SectionLabel('Uygulama'),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    title: const Text('Koyu tema'),
                    subtitle: Text(settings.isDarkTheme ? 'Koyu' : 'Açık'),
                    value: settings.isDarkTheme,
                    onChanged: (value) {
                      ref
                          .read(appSettingsProvider.notifier)
                          .setDarkTheme(value);
                    },
                  ),
                  Divider(color: scheme.outlineVariant),
                  const _SectionLabel('Okuma varsayılanları'),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Text(
                      'Yeni oturumlarda kullanılır. Açık kitapta alt çubuk geçerlidir.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Text(
                      'Tema',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ReadingThemeChips(
                      value: settings.readingTheme,
                      onChanged: (theme) {
                        ref
                            .read(appSettingsProvider.notifier)
                            .setReadingTheme(theme);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  _FontSizeControl(
                    fontSize: settings.fontSize,
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).setFontSize(value);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    title: const Text('Sayfalı okuma'),
                    subtitle: const Text('Kapalıysa kaydırmalı mod'),
                    value: settings.paginated,
                    onChanged: (value) {
                      ref
                          .read(appSettingsProvider.notifier)
                          .setPaginated(value);
                    },
                  ),
                  Divider(color: scheme.outlineVariant),
                  const _SectionLabel('Hakkında'),
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      final version = snapshot.data?.version ?? '1.0.0';
                      final build = snapshot.data?.buildNumber ?? '1';
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EPUB Kütüphanesi',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'v$version+$build — EPUB çevrimdışı; PDF sunucuda dönüşür',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Ayarlar yüklenemedi: $e')),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(letterSpacing: 0.6),
      ),
    );
  }
}

class _FontSizeControl extends StatelessWidget {
  const _FontSizeControl({required this.fontSize, required this.onChanged});

  final double fontSize;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final size = FontSizeLimits.clamp(fontSize);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Text(
            'Yazı boyutu  ${size.round()}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
