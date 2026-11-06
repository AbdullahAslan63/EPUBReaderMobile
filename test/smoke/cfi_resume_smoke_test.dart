import 'dart:io';

import 'package:epub_kutuphanesi/models/reading_progress.dart';
import 'package:epub_kutuphanesi/services/epub_import_service.dart';
import 'package:epub_kutuphanesi/services/hive_boxes.dart';
import 'package:epub_kutuphanesi/services/library_service.dart';
import 'package:epub_kutuphanesi/services/reading_progress_service.dart';
import 'package:epub_kutuphanesi/utils/resume_cfi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// KUTUPHANE.md §9 — ekle → CFI kaydet → “kill” (Hive kapat) → aynı CFI.
class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.root);
  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;

  @override
  Future<String?> getTemporaryPath() async => root;

  @override
  Future<String?> getApplicationSupportPath() async => root;

  @override
  Future<String?> getLibraryPath() async => root;
}

void main() {
  late Directory tempDir;
  late String fixturePath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('epub_cfi_smoke_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    Hive.init(tempDir.path);
    await HiveBoxes.openAll();

    final fixture = File('test/fixtures/minimal.epub');
    expect(
      await fixture.exists(),
      isTrue,
      reason: 'test/fixtures/minimal.epub eksik — smoke fixture üretin',
    );
    fixturePath = '${tempDir.path}/minimal.epub';
    await fixture.copy(fixturePath);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('§9: geçerli EPUB kopyalanır; kill sonrası aynı CFI resume edilir', () async {
    final importService = EpubImportService();
    final library = LibraryService();
    final progressService = ReadingProgressService();

    // 1–2: ekle + metadata
    final book = await importService.importFromPath(
      fixturePath,
      fallbackTitle: 'minimal.epub',
    );
    expect(book.title, 'Smoke Test Kitabı');
    expect(book.author, 'Test Yazar');
    expect(File(book.filePath).existsSync(), isTrue);
    // Orijinal fixture yerinde kalır
    expect(File(fixturePath).existsSync(), isTrue);

    await library.addBook(book);

    // 4: konum kaydı (okuyucu debounce flush’ının eşleniği)
    const savedCfi = 'epubcfi(/6/8!/4/2/2/2/1:0)';
    await progressService.saveProgress(
      ReadingProgress(
        bookId: book.id,
        cfi: savedCfi,
        percent: 0.55,
        updatedAt: DateTime.now(),
      ),
    );
    await library.updateBook(
      book.copyWith(lastCfi: savedCfi, progressPercent: 0.55),
    );

    // Kill simülasyonu: box’ları kapatıp yeniden aç
    await Hive.close();
    await HiveBoxes.openAll();

    final reopenedLibrary = LibraryService();
    final reopenedProgress = ReadingProgressService();
    final loadedBook = await reopenedLibrary.getBook(book.id);
    final loadedProgress = await reopenedProgress.getProgress(book.id);

    expect(loadedProgress?.cfi, savedCfi);
    expect(
      resolveResumeCfi(
        progressCfi: loadedProgress?.cfi,
        bookLastCfi: loadedBook?.lastCfi,
      ),
      savedCfi,
    );
    expect(loadedBook?.progressPercent, 0.55);
  });

  test('§9.5: bozuk EPUB yarım kayıt bırakmaz', () async {
    final bad = File('${tempDir.path}/bad.epub')
      ..writeAsStringSync('not-an-epub');
    final importService = EpubImportService();
    final library = LibraryService();

    await expectLater(
      () => importService.importFromPath(bad.path),
      throwsA(isA<EpubImportException>()),
    );
    expect(await library.getBooks(), isEmpty);
    final epubs = Directory('${tempDir.path}/epubs');
    if (await epubs.exists()) {
      expect(epubs.listSync(), isEmpty);
    }
  });
}
