import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/navigation_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/bookmarks/bookmarks_screen.dart';
import 'screens/library/library_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/quiet_bottom_nav.dart';

class EpubKutuphanesiApp extends ConsumerWidget {
  const EpubKutuphanesiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final themeMode = settingsAsync.valueOrNull?.themeMode ?? ThemeMode.dark;

    return MaterialApp(
      title: 'EPUB Kütüphanesi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const _HomeShell(),
    );
  }
}

class _HomeShell extends ConsumerWidget {
  const _HomeShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(navigationIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [LibraryScreen(), BookmarksScreen(), SettingsScreen()],
      ),
      bottomNavigationBar: QuietBottomNav(
        index: index,
        onSelected: (value) {
          ref.read(navigationIndexProvider.notifier).state = value;
        },
      ),
    );
  }
}
