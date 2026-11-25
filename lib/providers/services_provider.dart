import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/bookmark_service.dart';
import '../services/epub_import_service.dart';
import '../services/library_service.dart';
import '../services/pdf_conversion_service.dart';
import '../services/reading_progress_service.dart';
import '../services/settings_service.dart';

final libraryServiceProvider = Provider<LibraryService>((ref) {
  return LibraryService();
});

final epubImportServiceProvider = Provider<EpubImportService>((ref) {
  return EpubImportService();
});

final pdfConversionServiceProvider = Provider<PdfConversionService>((ref) {
  final api = HttpConversionApi();
  ref.onDispose(api.close);
  return PdfConversionService(
    library: ref.watch(libraryServiceProvider),
    epubImport: ref.watch(epubImportServiceProvider),
    api: api,
  );
});

final readingProgressServiceProvider = Provider<ReadingProgressService>((ref) {
  return ReadingProgressService();
});

final bookmarkServiceProvider = Provider<BookmarkService>((ref) {
  return BookmarkService();
});

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});
