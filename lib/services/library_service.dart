import 'dart:io';

import 'package:hive/hive.dart';

import '../models/book.dart';
import 'hive_boxes.dart';

/// Kitaplık CRUD — Hive `books` box.
class LibraryService {
  LibraryService({
    Box<Map>? booksBox,
    Box<Map>? bookmarksBox,
    Box<Map>? progressBox,
  })  : _books = booksBox ?? HiveBoxes.booksBox,
        _bookmarks = bookmarksBox ?? HiveBoxes.bookmarksBox,
        _progress = progressBox ?? HiveBoxes.progressBox;

  final Box<Map> _books;
  final Box<Map> _bookmarks;
  final Box<Map> _progress;

  Future<List<Book>> getBooks() async {
    final books = _books.values
        .map((raw) => Book.fromMap(Map<dynamic, dynamic>.from(raw)))
        .toList();
    books.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return books;
  }

  Future<Book?> getBook(String id) async {
    final raw = _books.get(id);
    if (raw == null) return null;
    return Book.fromMap(Map<dynamic, dynamic>.from(raw));
  }

  Future<void> addBook(Book book) async {
    await _books.put(book.id, book.toMap());
  }

  Future<void> updateBook(Book book) async {
    await _books.put(book.id, book.toMap());
  }

  /// EPUB + kapak dosyaları, progress ve işaretleri birlikte siler.
  Future<void> deleteBook(String id) async {
    final book = await getBook(id);
    await _books.delete(id);
    await _progress.delete(id);

    final bookmarkIds = _bookmarks.keys
        .whereType<String>()
        .where((key) {
          final raw = _bookmarks.get(key);
          return raw != null && raw['bookId'] == id;
        })
        .toList();
    for (final key in bookmarkIds) {
      await _bookmarks.delete(key);
    }

    if (book != null) {
      await _deleteIfExists(book.filePath);
      final cover = book.coverImagePath;
      if (cover != null) await _deleteIfExists(cover);
    }
  }

  Future<void> _deleteIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
