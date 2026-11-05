import 'dart:io';

import 'package:epub_kutuphanesi/models/book.dart';
import 'package:epub_kutuphanesi/models/bookmark.dart';
import 'package:epub_kutuphanesi/models/reading_progress.dart';
import 'package:epub_kutuphanesi/services/bookmark_service.dart';
import 'package:epub_kutuphanesi/services/hive_boxes.dart';
import 'package:epub_kutuphanesi/services/library_service.dart';
import 'package:epub_kutuphanesi/services/reading_progress_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('epub_lib_test_');
    Hive.init(tempDir.path);
    await HiveBoxes.openAll();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('addBook ve getBooks sıralı çalışır', () async {
    final service = LibraryService();
    final older = Book(
      id: '1',
      title: 'Eski',
      author: 'A',
      filePath: '${tempDir.path}/a.epub',
      addedAt: DateTime(2024, 1, 1),
    );
    final newer = Book(
      id: '2',
      title: 'Yeni',
      author: 'B',
      filePath: '${tempDir.path}/b.epub',
      addedAt: DateTime(2024, 6, 1),
    );

    await service.addBook(older);
    await service.addBook(newer);

    final books = await service.getBooks();
    expect(books.map((b) => b.id), ['2', '1']);
  });

  test('deleteBook dosya, progress ve işaretleri temizler', () async {
    final epub = File('${tempDir.path}/book.epub')..writeAsStringSync('x');
    final cover = File('${tempDir.path}/cover.jpg')..writeAsStringSync('y');

    final library = LibraryService();
    final progress = ReadingProgressService();
    final bookmarks = BookmarkService();

    const id = 'book-1';
    await library.addBook(
      Book(
        id: id,
        title: 'Test',
        author: 'Yazar',
        filePath: epub.path,
        coverImagePath: cover.path,
        addedAt: DateTime.now(),
      ),
    );
    await progress.saveProgress(
      ReadingProgress(
        bookId: id,
        cfi: 'epubcfi(/6/2)',
        percent: 0.2,
        updatedAt: DateTime.now(),
      ),
    );
    await bookmarks.add(
      Bookmark(
        id: 'bm-1',
        bookId: id,
        cfi: 'epubcfi(/6/2)',
        createdAt: DateTime.now(),
      ),
    );

    await library.deleteBook(id);

    expect(await library.getBook(id), isNull);
    expect(await progress.getProgress(id), isNull);
    expect(await bookmarks.getByBookId(id), isEmpty);
    expect(epub.existsSync(), isFalse);
    expect(cover.existsSync(), isFalse);
  });
}
