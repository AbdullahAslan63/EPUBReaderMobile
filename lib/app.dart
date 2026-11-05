import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/navigation_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/bookmarks/bookmarks_screen.dart';
import 'screens/library/library_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'theme/app_theme.dart';

class EpubKutuphanesiApp extends ConsumerWidget {
  const EpubKutuphanesiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final themeMode =
        settingsAsync.valueOrNull?.themeMode ?? ThemeMode.dark;

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

  static const _titles = <String>['Kitaplık', 'İşaretler', 'Ayarlar'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(navigationIndexProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_titles[index])),
      body: IndexedStack(
        index: index,
        children: const [
          LibraryScreen(),
          BookmarksScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          ref.read(navigationIndexProvider.notifier).state = value;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Kitaplık',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border),
            selectedIcon: Icon(Icons.bookmark),
            label: 'İşaretler',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}
