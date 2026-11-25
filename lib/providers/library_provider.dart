import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../config/converter_config.dart';
import '../models/book.dart';
import '../services/epub_import_service.dart';
import 'services_provider.dart';

final booksProvider = AsyncNotifierProvider<BooksNotifier, List<Book>>(
  BooksNotifier.new,
);

/// Arka plan dönüşümünden gelen kısa kullanıcı mesajı.
final conversionNoticeProvider = StateProvider<String?>((ref) => null);

class BooksNotifier extends AsyncNotifier<List<Book>> {
  @override
  Future<List<Book>> build() async {
    final books = await ref.read(libraryServiceProvider).getBooks();
    final pending = books.where((book) => book.isConverting).toList();
    if (pending.isNotEmpty) {
      Future<void>.delayed(Duration.zero, () {
        for (final book in pending) {
          unawaited(_convert(book));
        }
      });
    }
    return books;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(libraryServiceProvider).getBooks(),
    );
  }

  Future<Book> importBook() async {
    final imported = await ref
        .read(epubImportServiceProvider)
        .importFromPicker();
    if (imported == null) {
      throw const ImportCancelled();
    }
    if (!imported.isConverting) {
      await ref.read(libraryServiceProvider).addBook(imported);
      await refresh();
      return imported;
    }

    await ref.read(libraryServiceProvider).addBook(imported);
    _upsert(imported);
    unawaited(_convert(imported));
    return imported;
  }

  Future<void> retryConversion(Book book) async {
    final next = book.copyWith(
      conversionStatus: ConversionStatus.converting,
      conversionJobId: null,
      conversionError: null,
      filePath: '',
    );
    await ref.read(libraryServiceProvider).updateBook(next);
    _upsert(next);
    await _convert(next);
  }

  Future<void> deleteBook(String id) async {
    ref.read(pdfConversionServiceProvider).cancel(id);
    await ref.read(libraryServiceProvider).deleteBook(id);
    await refresh();
  }

  Future<void> updateBook(Book book) async {
    await ref.read(libraryServiceProvider).updateBook(book);
    await refresh();
  }

  /// Eksik dosyayı aynı kitap kaydı altında yeniden ekler.
  Future<Book> reimportMissingFile(Book book) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: EpubImportService.allowedExtensions,
    );
    if (result == null || result.files.isEmpty) {
      throw const ImportCancelled();
    }
    final path = result.files.single.path;
    if (path == null) {
      throw const EpubImportException(
        'Dosya yolu alınamadı. Lütfen başka bir konumdan tekrar deneyin.',
      );
    }

    final importService = ref.read(epubImportServiceProvider);
    final library = ref.read(libraryServiceProvider);
    final name = result.files.single.name;
    final isPdf = p.extension(path).toLowerCase() == '.pdf';

    final Book restored;
    if (isPdf) {
      final staged = await importService.stagePdfCopy(
        path,
        fallbackTitle: name,
        existingId: book.id,
        addedAt: book.addedAt,
      );
      restored = staged.copyWith(
        lastOpenedAt: book.lastOpenedAt,
        lastCfi: book.lastCfi,
        progressPercent: book.progressPercent,
      );
    } else {
      final imported = await importService.importFromPath(
        path,
        fallbackTitle: name,
        existingId: book.id,
      );
      restored = imported.copyWith(
        addedAt: book.addedAt,
        lastOpenedAt: book.lastOpenedAt,
        lastCfi: book.lastCfi,
        progressPercent: book.progressPercent,
        conversionStatus: ConversionStatus.ready,
        conversionJobId: null,
        localSourcePath: null,
        conversionError: null,
      );
      await importService.discardStagedFile(book.localSourcePath);
    }

    await library.updateBook(restored);
    _upsert(restored);
    if (restored.isConverting) {
      unawaited(_convert(restored));
    }
    return restored;
  }

  Future<void> _convert(Book book) async {
    await ref
        .read(pdfConversionServiceProvider)
        .convert(
          book,
          baseUrl: ConverterConfig.baseUrl,
          onUpdated: _upsert,
          onMessage: (message) {
            ref.read(conversionNoticeProvider.notifier).state = message;
          },
        );
  }

  void _upsert(Book book) {
    final current = state.valueOrNull;
    if (current == null) {
      state = AsyncData([book]);
      return;
    }
    final next = [
      for (final item in current)
        if (item.id != book.id) item,
      book,
    ]..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    state = AsyncData(next);
  }
}

class ImportCancelled implements Exception {
  const ImportCancelled();
}

final bookByIdProvider = FutureProvider.family<Book?, String>((ref, id) {
  return ref.watch(libraryServiceProvider).getBook(id);
});

final continueReadingProvider = Provider<Book?>((ref) {
  final books = ref.watch(booksProvider).valueOrNull;
  if (books == null || books.isEmpty) return null;
  final opened = books
      .where((b) => b.isReady && b.lastOpenedAt != null)
      .toList();
  if (opened.isEmpty) return null;
  opened.sort((a, b) => b.lastOpenedAt!.compareTo(a.lastOpenedAt!));
  return opened.first;
});
