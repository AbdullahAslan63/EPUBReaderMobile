import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/navigation_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return ListView(
      children: [
        const ListTile(
          title: Text('Görünüm'),
          subtitle: Text('Uygulama teması'),
        ),
        RadioGroup<ThemeMode>(
          groupValue: themeMode,
          onChanged: (value) {
            if (value != null) {
              ref.read(themeModeProvider.notifier).state = value;
            }
          },
          child: const Column(
            children: [
              RadioListTile<ThemeMode>(
                title: Text('Sistem'),
                value: ThemeMode.system,
              ),
              RadioListTile<ThemeMode>(
                title: Text('Açık'),
                value: ThemeMode.light,
              ),
              RadioListTile<ThemeMode>(
                title: Text('Koyu'),
                value: ThemeMode.dark,
              ),
            ],
          ),
        ),
        const Divider(),
        ListTile(
          title: const Text('EPUB Kütüphanesi'),
          subtitle: Text(
            'v1 iskelet — çevrimdışı EPUB okuyucu',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
