import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_settings.dart';
import '../../models/book.dart';
import '../../providers/bookmarks_provider.dart';
import '../../providers/services_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_tokens.dart';
import '../../utils/font_size_limits.dart';
import '../../utils/resume_cfi.dart';
import '../../widgets/app_page_header.dart';
import '../../widgets/confirm_sheet.dart';
import 'fihrist_drawer.dart';
import 'reader_bottom_dock.dart';
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

  var _chromeVisible = true;
  var _dockPanel = ReaderDockPanel.none;
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
      final book = await ref
          .read(libraryServiceProvider)
          .getBook(widget.bookId);
      if (book == null) {
        setState(() {
          _loading = false;
          _error = 'Kitap bulunamadı.';
        });
        return;
      }
      if (book.isConverting) {
        setState(() {
          _loading = false;
          _error = 'Dönüşüm bitmeden kitap açılamaz.';
        });
        return;
      }
      if (book.conversionStatus == ConversionStatus.failed) {
        setState(() {
          _loading = false;
          _error = 'Bu PDF EPUB’a dönüştürülemedi.';
        });
        return;
      }
      if (book.filePath.isEmpty || !File(book.filePath).existsSync()) {
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
    setState(() {
      _chromeVisible = !_chromeVisible;
      if (!_chromeVisible) _dockPanel = ReaderDockPanel.none;
    });
  }

  void _toggleDock(ReaderDockPanel panel) {
    setState(() {
      _dockPanel = _dockPanel == panel ? ReaderDockPanel.none : panel;
    });
  }

  Future<void> _addBookmark() async {
    final cfi = _controller?.currentCfi ?? _book?.lastCfi;
    if (cfi == null || cfi.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Konum henüz hazır değil.')));
      return;
    }

    final note = await showNoteSheet(context);
    if (note == null) return;

    await ref
        .read(bookmarksProvider.notifier)
        .addBookmark(
          bookId: widget.bookId,
          cfi: cfi,
          note: note.isEmpty ? null : note,
        );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('İşaret eklendi')));
    }
  }

  Future<void> _persistReaderSettings() async {
    final c = _controller;
    if (c == null) return;
    final settings = ref.read(appSettingsProvider).valueOrNull;
    if (settings == null) return;
    await ref
        .read(appSettingsProvider.notifier)
        .setReadingTheme(c.readingTheme);
    await ref.read(appSettingsProvider.notifier).setFontSize(c.fontSize);
    await ref.read(appSettingsProvider.notifier).setPaginated(c.paginated);
  }

  Future<void> _setFontSize(double size) async {
    final c = _controller;
    if (c == null) return;
    await c.setFontSize(size);
    if (mounted) setState(() {});
  }

  Future<void> _setReadingTheme(ReadingTheme theme) async {
    final c = _controller;
    if (c == null) return;
    await c.setReadingTheme(theme);
    if (mounted) setState(() {});
    await _persistReaderSettings();
  }

  Future<void> _togglePaginated() async {
    final c = _controller;
    if (c == null) return;
    await c.setPaginated(!c.paginated);
    if (mounted) setState(() {});
    await _persistReaderSettings();
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _book == null || _controller == null) {
      return Scaffold(
        body: Column(
          children: [
            AppPageHeader(
              title: 'Okuma',
              leading: IconButton(
                tooltip: 'Geri',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _error ?? 'Bilinmeyen hata',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final book = _book!;
    final controller = _controller!;
    // İşaret override > progress/Book ayna (bootstrap’ta hizalanmış).
    final initialCfi = widget.initialCfiOverride ?? book.lastCfi;
    final progress = controller.progressPercent.clamp(0.0, 1.0);
    final progressPct = (progress * 100).round();
    final chapterLabel = controller.currentChapterTitle;
    final scheme = Theme.of(context).colorScheme;
    final overlay = Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

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
        value: overlay.copyWith(statusBarColor: Colors.transparent),
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
                  final elapsed = DateTime.now()
                      .difference(down)
                      .inMilliseconds;
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
                    borderRadius: BorderRadius.circular(AppTokens.radius),
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
              AnimatedSlide(
                duration: AppTokens.chromeAnim,
                offset: _chromeVisible ? Offset.zero : const Offset(0, -1.2),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: _chromeVisible ? 1 : 0,
                  child: IgnorePointer(
                    ignoring: !_chromeVisible,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                scheme.surface.withValues(alpha: 0.94),
                                scheme.surface.withValues(alpha: 0),
                              ],
                            ),
                          ),
                          child: SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(4, 0, 16, 10),
                              child: Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Geri',
                                    onPressed: () =>
                                        Navigator.of(context).maybePop(),
                                    icon: const Icon(Icons.arrow_back),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '%$progressPct',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 2,
                          backgroundColor: scheme.outlineVariant,
                          color: scheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedSlide(
                duration: AppTokens.chromeAnim,
                offset: _chromeVisible ? Offset.zero : const Offset(0, 1.2),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: _chromeVisible ? 1 : 0,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: IgnorePointer(
                      ignoring: !_chromeVisible,
                      child: SafeArea(
                        top: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ColoredBox(
                              color: scheme.surface.withValues(alpha: 0.94),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  8,
                                  20,
                                  8,
                                ),
                                child: Text(
                                  [book.title, ?chapterLabel].join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelMedium,
                                ),
                              ),
                            ),
                            ReaderBottomDock(
                              fontSize: controller.fontSize,
                              readingTheme: controller.readingTheme,
                              paginated: controller.paginated,
                              expanded: _dockPanel,
                              onFihrist: () =>
                                  _scaffoldKey.currentState?.openDrawer(),
                              onToggleFont: () =>
                                  _toggleDock(ReaderDockPanel.font),
                              onToggleTheme: () =>
                                  _toggleDock(ReaderDockPanel.theme),
                              onTogglePaginated: () {
                                _togglePaginated();
                              },
                              onBookmark: () {
                                _addBookmark();
                              },
                              onFontSizeChanged: (size) {
                                _setFontSize(size);
                              },
                              onFontSizeChangeEnd: () {
                                _persistReaderSettings();
                              },
                              onReadingThemeChanged: (theme) {
                                _setReadingTheme(theme);
                              },
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
