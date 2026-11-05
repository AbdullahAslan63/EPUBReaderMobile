import 'dart:async';

import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';

import '../../models/app_settings.dart';
import '../../models/book.dart';
import '../../models/reading_progress.dart';
import '../../services/library_service.dart';
import '../../services/reading_progress_service.dart';
import '../../utils/reading_theme_mapper.dart';

/// Okuma iş mantığı — widget dışında (AGENTS.md).
class ReaderController {
  ReaderController({
    required this.book,
    required LibraryService libraryService,
    required ReadingProgressService progressService,
    required AppSettings initialSettings,
    this.onBookUpdated,
  })  : _library = libraryService,
        _progress = progressService,
        readingTheme = initialSettings.readingTheme,
        fontSize = initialSettings.fontSize,
        paginated = initialSettings.paginated;

  final Book book;
  final LibraryService _library;
  final ReadingProgressService _progress;
  final void Function(Book book)? onBookUpdated;

  final EpubController epubController = EpubController();

  ReadingTheme readingTheme;
  double fontSize;
  bool paginated;

  String? currentCfi;
  double progressPercent = 0;
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
    fontSize = size.clamp(12.0, 32.0).toDouble();
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
    epubController.display(cfi: chapter.href);
  }

  Future<void> _flush() async {
    final pending = _pending;
    if (pending == null) return;
    _pending = null;
    await _progress.saveProgress(pending);
    final updated = book.copyWith(
      lastCfi: pending.cfi,
      progressPercent: pending.percent,
      lastOpenedAt: DateTime.now(),
    );
    await _library.updateBook(updated);
    onBookUpdated?.call(updated);
  }

  Future<void> dispose() async {
    _debounce?.cancel();
    await _flush();
  }
}
