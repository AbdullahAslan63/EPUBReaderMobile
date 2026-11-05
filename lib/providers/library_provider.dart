import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book.dart';
import 'services_provider.dart';

final booksProvider =
    AsyncNotifierProvider<BooksNotifier, List<Book>>(BooksNotifier.new);

class BooksNotifier extends AsyncNotifier<List<Book>> {
  @override
  Future<List<Book>> build() {
    return ref.read(libraryServiceProvider).getBooks();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(libraryServiceProvider).getBooks(),
    );
  }

  Future<Book> importBook() async {
    final imported =
        await ref.read(epubImportServiceProvider).importFromPicker();
    if (imported == null) {
      throw const ImportCancelled();
    }
    await ref.read(libraryServiceProvider).addBook(imported);
    await refresh();
    return imported;
  }

  Future<void> deleteBook(String id) async {
    await ref.read(libraryServiceProvider).deleteBook(id);
    await refresh();
  }

  Future<void> updateBook(Book book) async {
    await ref.read(libraryServiceProvider).updateBook(book);
    await refresh();
  }

  /// Eksik EPUB dosyasını aynı kitap kaydı altında yeniden ekler.
  Future<Book> reimportMissingFile(Book book) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['epub'],
    );
    if (result == null || result.files.isEmpty) {
      throw const ImportCancelled();
    }
    final path = result.files.single.path;
    if (path == null) {
      throw Exception('Dosya yolu alınamadı.');
    }

    final imported = await ref.read(epubImportServiceProvider).importFromPath(
          path,
          fallbackTitle: result.files.single.name,
          existingId: book.id,
        );

    final restored = imported.copyWith(
      addedAt: book.addedAt,
      lastOpenedAt: book.lastOpenedAt,
      lastCfi: book.lastCfi,
      progressPercent: book.progressPercent,
    );
    await ref.read(libraryServiceProvider).updateBook(restored);
    await refresh();
    return restored;
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
  final opened = books.where((b) => b.lastOpenedAt != null).toList();
  if (opened.isEmpty) return null;
  opened.sort((a, b) => b.lastOpenedAt!.compareTo(a.lastOpenedAt!));
  return opened.first;
});
