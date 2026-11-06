import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/book.dart';
import '../../providers/bookmarks_provider.dart';
import '../../providers/services_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/font_size_limits.dart';
import '../../utils/resume_cfi.dart';
import 'fihrist_drawer.dart';
import 'reader_controller.dart';
import 'reader_style_panel.dart';

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

  var _chromeVisible = true;
  var _pointerCount = 0;
  var _pinchBaseFont = 18.0;
  var _showFontChip = false;
  Timer? _fontChipTimer;
  DateTime? _lastTouchDown;

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

      final settings = await ref.read(settingsServiceProvider).getSettings();
      final progressService = ref.read(readingProgressServiceProvider);
      // CFI SoT: progress box; Book.lastCfi yalnızca yedek / eski kayıt.
      final progress = await progressService.getProgress(book.id);
      final locations = progress?.locationsJson;
      final resumeCfi = resolveResumeCfi(
        progressCfi: progress?.cfi,
        bookLastCfi: book.lastCfi,
      );
      final resumePercent = progress?.percent ?? book.progressPercent;

      final opened = book.copyWith(
        lastOpenedAt: DateTime.now(),
        lastCfi: resumeCfi,
        progressPercent: resumePercent,
      );
      await ref.read(libraryServiceProvider).updateBook(opened);

      final controller = ReaderController(
        book: opened,
        libraryService: ref.read(libraryServiceProvider),
        progressService: progressService,
        initialSettings: settings,
        initialProgressPercent: resumePercent,
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
    _fontChipTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _toggleChrome() {
    setState(() => _chromeVisible = !_chromeVisible);
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

  Future<void> _openStylePanel() async {
    final c = _controller;
    if (c == null) return;
    await showReaderStylePanel(
      context: context,
      fontSize: c.fontSize,
      readingTheme: c.readingTheme,
      paginated: c.paginated,
      onFontSizeChanged: (size) async {
        await c.setFontSize(size);
        setState(() {});
        await _persistReaderSettings();
      },
      onReadingThemeChanged: (theme) async {
        await c.setReadingTheme(theme);
        setState(() {});
        await _persistReaderSettings();
      },
      onPaginatedChanged: (paginated) async {
        await c.setPaginated(paginated);
        setState(() {});
        await _persistReaderSettings();
      },
      onAddBookmark: _addBookmark,
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    setState(() {
      _pointerCount += 1;
      if (_pointerCount == 2) {
        _pinchBaseFont = _controller?.fontSize ?? 18;
      }
    });
  }

  void _onPointerUp(PointerEvent event) {
    setState(() {
      _pointerCount = (_pointerCount - 1).clamp(0, 10);
    });
  }

  Future<void> _onScaleUpdate(ScaleUpdateDetails details) async {
    final c = _controller;
    if (c == null || details.pointerCount < 2) return;
    final next = FontSizeLimits.clamp(_pinchBaseFont * details.scale);
    if ((next - c.fontSize).abs() < 0.4) return;
    await c.setFontSize(next);
    setState(() {
      _showFontChip = true;
    });
    _fontChipTimer?.cancel();
    _fontChipTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showFontChip = false);
    });
  }

  Future<void> _onScaleEnd(ScaleEndDetails details) async {
    await _persistReaderSettings();
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
    // İşaret override > progress/Book ayna (bootstrap’ta hizalanmış).
    final initialCfi = widget.initialCfiOverride ?? book.lastCfi;
    final progressPct =
        (controller.progressPercent * 100).clamp(0, 100).round();
    final chapterLabel = controller.currentChapterTitle;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: scheme.surface,
      drawerEnableOpenDragGesture: true,
      drawerEdgeDragWidth: 32,
      drawer: FihristDrawer(
        chapters: controller.chapters,
        activeHref: controller.activeChapterHref,
        onChapterSelected: (chapter) {
          Navigator.of(context).maybePop();
          controller.goToChapter(chapter);
          setState(() {});
        },
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: _chromeVisible
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
              ),
        child: Listener(
          onPointerDown: _onPointerDown,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerUp,
          child: Stack(
            fit: StackFit.expand,
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
                onTouchDown: (x, y) {
                  _lastTouchDown = DateTime.now();
                },
                onTouchUp: (x, y) {
                  final down = _lastTouchDown;
                  if (down == null) return;
                  final elapsed =
                      DateTime.now().difference(down).inMilliseconds;
                  // Kısa dokunuş → chrome; kaydırma/uzun basmayı yok say.
                  if (elapsed < 220 && _pointerCount <= 1) {
                    _toggleChrome();
                  }
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
              if (_pointerCount >= 2)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onScaleStart: (_) {
                      _pinchBaseFont = controller.fontSize;
                    },
                    onScaleUpdate: _onScaleUpdate,
                    onScaleEnd: _onScaleEnd,
                  ),
                ),
              if (_showFontChip)
                Align(
                  alignment: Alignment.center,
                  child: Material(
                    color: scheme.inverseSurface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Text(
                        '${controller.fontSize.round()}',
                        style: TextStyle(
                          color: scheme.onInverseSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              // Üst chrome
              AnimatedSlide(
                duration: const Duration(milliseconds: 220),
                offset: _chromeVisible ? Offset.zero : const Offset(0, -1.2),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: _chromeVisible ? 1 : 0,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
                      child: Row(
                        children: [
                          IconButton.filledTonal(
                            tooltip: 'Geri',
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back),
                          ),
                          const Spacer(),
                          Material(
                            color: scheme.surfaceContainerHighest
                                .withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Text(
                                '%$progressPct',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Alt durum + FAB’lar
              AnimatedSlide(
                duration: const Duration(milliseconds: 220),
                offset: _chromeVisible ? Offset.zero : const Offset(0, 1.2),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: _chromeVisible ? 1 : 0,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            FloatingActionButton.small(
                              heroTag: 'fihrist_fab',
                              tooltip: 'Fihrist',
                              onPressed: () =>
                                  _scaffoldKey.currentState?.openDrawer(),
                              child: const Icon(Icons.list_alt),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Material(
                                color: scheme.surfaceContainerHighest
                                    .withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Text(
                                    [
                                      book.title,
                                      ?chapterLabel,
                                    ].join(' · '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.labelMedium,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            FloatingActionButton(
                              heroTag: 'style_fab',
                              tooltip: 'Stil',
                              onPressed: _openStylePanel,
                              child: const Icon(Icons.apps),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
