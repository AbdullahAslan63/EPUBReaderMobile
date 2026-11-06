import 'dart:async';

import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';

import '../../models/app_settings.dart';
import '../../models/book.dart';
import '../../models/reading_progress.dart';
import '../../services/library_service.dart';
import '../../services/reading_progress_service.dart';
import '../../utils/chapter_locator.dart';
import '../../utils/font_size_limits.dart';
import '../../utils/reading_theme_mapper.dart';

/// Okuma iş mantığı — widget dışında (AGENTS.md).
///
/// CFI doğruluk kaynağı: [ReadingProgressService] (progress Hive box).
/// [Book.lastCfi] / [Book.progressPercent] kitaplık listesi için denormalize ayna.
class ReaderController {
  ReaderController({
    required Book book,
    required LibraryService libraryService,
    required ReadingProgressService progressService,
    required AppSettings initialSettings,
    this.onBookUpdated,
    double? initialProgressPercent,
  })  : book = book,
        _library = libraryService,
        _progress = progressService,
        readingTheme = initialSettings.readingTheme,
        fontSize = initialSettings.fontSize,
        paginated = initialSettings.paginated,
        currentCfi = book.lastCfi,
        progressPercent = initialProgressPercent ?? book.progressPercent;

  Book book;
  final LibraryService _library;
  final ReadingProgressService _progress;
  final void Function(Book book)? onBookUpdated;

  final EpubController epubController = EpubController();

  ReadingTheme readingTheme;
  double fontSize;
  bool paginated;

  String? currentCfi;
  double progressPercent;
  List<EpubChapter> chapters = const [];

  Timer? _debounce;
  ReadingProgress? _pending;

  EpubDisplaySettings get displaySettings => EpubDisplaySettings(
        flow: paginated ? EpubFlow.paginated : EpubFlow.scrolled,
        snap: true,
        useSnapAnimationAndroid: false,
        allowScriptedContent: false,
        fontSize: fontSize.round(),
        theme: epubThemeFromReading(readingTheme),
      );

  /// Fihrist vurgusu — CFI/href eşlemesi.
  String? get activeChapterHref =>
      ChapterLocator.findForLocation(chapters, currentCfi)?.href;

  /// Alt durum etiketi — CFI eşlemesi; yoksa progress sezgiseli.
  String? get currentChapterTitle {
    final matched = ChapterLocator.findForLocation(chapters, currentCfi);
    if (matched != null) {
      final title = matched.title.trim();
      return title.isEmpty ? null : title;
    }
    if (chapters.isEmpty) return null;
    final flat = ChapterLocator.flatten(chapters);
    if (flat.isEmpty) return null;
    final idx =
        (progressPercent.clamp(0.0, 0.999) * flat.length).floor().clamp(
              0,
              flat.length - 1,
            );
    final title = flat[idx].title.trim();
    return title.isEmpty ? null : title;
  }

  void onRelocated(EpubLocation location) {
    currentCfi = location.startCfi;
    progressPercent = location.progress;
    _pending = ReadingProgress(
      bookId: book.id,
      cfi: location.startCfi,
      percent: location.progress,
      updatedAt: DateTime.now(),
    );
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _flush);
  }

  Future<void> onLocationsGenerated(String locationsJson) async {
    await _progress.saveLocations(book.id, locationsJson);
  }

  Future<void> setFontSize(double size) async {
    fontSize = FontSizeLimits.clamp(size);
    await epubController.setFontSize(fontSize: fontSize);
  }

  Future<void> setReadingTheme(ReadingTheme theme) async {
    readingTheme = theme;
    await epubController.updateTheme(theme: epubThemeFromReading(theme));
  }

  Future<void> setPaginated(bool value) async {
    paginated = value;
    await epubController.setFlow(
      flow: value ? EpubFlow.paginated : EpubFlow.scrolled,
    );
  }

  void goToChapter(EpubChapter chapter) {
    if (chapter.href.isEmpty) return;
    currentCfi = chapter.href;
    epubController.display(cfi: chapter.href);
  }

  Future<void> _flush() async {
    final pending = _pending;
    if (pending == null) return;
    _pending = null;
    // SoT: progress box
    await _progress.saveProgress(pending);
    // Ayna: kitaplık % / Devam et kartı
    book = book.copyWith(
      lastCfi: pending.cfi,
      progressPercent: pending.percent,
      lastOpenedAt: DateTime.now(),
    );
    await _library.updateBook(book);
    onBookUpdated?.call(book);
  }

  Future<void> dispose() async {
    _debounce?.cancel();
    await _flush();
  }
}
