import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_settings.dart';
import '../../models/book.dart';
import '../../providers/bookmarks_provider.dart';
import '../../providers/services_provider.dart';
import '../../providers/settings_provider.dart';
import 'reader_controller.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    super.key,
    required this.bookId,
    this.initialCfiOverride,
  });

  final String bookId;
  final String? initialCfiOverride;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  ReaderController? _controller;
  Book? _book;
  String? _locationsJson;
  var _loading = true;
  String? _error;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final book =
          await ref.read(libraryServiceProvider).getBook(widget.bookId);
      if (book == null) {
        setState(() {
          _loading = false;
          _error = 'Kitap bulunamadı.';
        });
        return;
      }
      if (!File(book.filePath).existsSync()) {
        setState(() {
          _loading = false;
          _error = 'EPUB dosyası bulunamadı.';
        });
        return;
      }

      final settings =
          await ref.read(settingsServiceProvider).getSettings();
      final locations =
          await ref.read(readingProgressServiceProvider).getLocations(book.id);

      final opened = book.copyWith(lastOpenedAt: DateTime.now());
      await ref.read(libraryServiceProvider).updateBook(opened);

      final controller = ReaderController(
        book: opened,
        libraryService: ref.read(libraryServiceProvider),
        progressService: ref.read(readingProgressServiceProvider),
        initialSettings: settings,
        onBookUpdated: (updated) {
          _book = updated;
        },
      );

      setState(() {
        _book = opened;
        _controller = controller;
        _locationsJson = locations;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Kitap açılamadı: $e';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _addBookmark() async {
    final cfi = _controller?.currentCfi ?? _book?.lastCfi;
    if (cfi == null || cfi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konum henüz hazır değil.')),
      );
      return;
    }

    final noteController = TextEditingController();
    final note = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İşaret ekle'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            labelText: 'Not (isteğe bağlı)',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, noteController.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (note == null) return;

    await ref.read(bookmarksProvider.notifier).addBookmark(
          bookId: widget.bookId,
          cfi: cfi,
          note: note.isEmpty ? null : note,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İşaret eklendi')),
      );
    }
  }

  Future<void> _persistReaderSettings() async {
    final c = _controller;
    if (c == null) return;
    final settings = ref.read(appSettingsProvider).valueOrNull;
    if (settings == null) return;
    await ref.read(appSettingsProvider.notifier).setReadingTheme(c.readingTheme);
    await ref.read(appSettingsProvider.notifier).setFontSize(c.fontSize);
    await ref.read(appSettingsProvider.notifier).setPaginated(c.paginated);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _book == null || _controller == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Okuma')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error ?? 'Bilinmeyen hata', textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final book = _book!;
    final controller = _controller!;
    final initialCfi = widget.initialCfiOverride ?? book.lastCfi;

    return Scaffold(
      key: _scaffoldKey,
      drawerEnableOpenDragGesture: true,
      drawerEdgeDragWidth: 28,
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Fihrist',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: controller.chapters.isEmpty
                    ? const Center(child: Text('Bölümler yükleniyor…'))
                    : ListView(
                        children: _buildChapterTiles(controller.chapters),
                      ),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: Text(
          '${(controller.progressPercent * 100).clamp(0, 100).round()}%',
        ),
        actions: [
          IconButton(
            tooltip: 'İşaret ekle',
            icon: const Icon(Icons.bookmark_add_outlined),
            onPressed: _addBookmark,
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'font_up':
                  await controller.setFontSize(controller.fontSize + 2);
                  break;
                case 'font_down':
                  await controller.setFontSize(controller.fontSize - 2);
                  break;
                case 'theme_light':
                  await controller.setReadingTheme(ReadingTheme.light);
                  break;
                case 'theme_dark':
                  await controller.setReadingTheme(ReadingTheme.dark);
                  break;
                case 'theme_sepia':
                  await controller.setReadingTheme(ReadingTheme.sepia);
                  break;
                case 'flow_paginated':
                  await controller.setPaginated(true);
                  break;
                case 'flow_scrolled':
                  await controller.setPaginated(false);
                  break;
              }
              setState(() {});
              await _persistReaderSettings();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'font_up', child: Text('Yazı boyutu +')),
              PopupMenuItem(value: 'font_down', child: Text('Yazı boyutu −')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'theme_light', child: Text('Tema: Açık')),
              PopupMenuItem(value: 'theme_dark', child: Text('Tema: Koyu')),
              PopupMenuItem(value: 'theme_sepia', child: Text('Tema: Sepya')),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'flow_paginated',
                child: Text('Sayfalı mod'),
              ),
              PopupMenuItem(
                value: 'flow_scrolled',
                child: Text('Kaydırmalı mod'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            EpubViewer(
              epubController: controller.epubController,
              epubSource: EpubSource.fromFile(File(book.filePath)),
              initialCfi: initialCfi,
              initialLocations: _locationsJson,
              displaySettings: controller.displaySettings,
              onRelocated: (location) {
                controller.onRelocated(location);
                setState(() {});
              },
              onChaptersLoaded: (chapters) {
                setState(() => controller.chapters = chapters);
              },
              onLocationsGenerated: (locations) {
                controller.onLocationsGenerated(locations);
              },
              onLoadError: (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Kitap açılamadı: ${error.message}'),
                  ),
                );
                Navigator.of(context).maybePop();
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildChapterTiles(List<EpubChapter> chapters, [int depth = 0]) {
    final tiles = <Widget>[];
    for (final chapter in chapters) {
      tiles.add(
        ListTile(
          contentPadding: EdgeInsets.only(left: 16.0 + depth * 12, right: 16),
          title: Text(chapter.title.isEmpty ? 'Bölüm' : chapter.title),
          onTap: () {
            Navigator.of(context).pop();
            _controller?.goToChapter(chapter);
          },
        ),
      );
      if (chapter.subitems.isNotEmpty) {
        tiles.addAll(_buildChapterTiles(chapter.subitems, depth + 1));
      }
    }
    return tiles;
  }
}
