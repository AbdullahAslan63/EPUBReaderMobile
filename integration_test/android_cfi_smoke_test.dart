import 'dart:io';

import 'package:epub_kutuphanesi/models/reading_progress.dart';
import 'package:epub_kutuphanesi/services/epub_import_service.dart';
import 'package:epub_kutuphanesi/services/hive_boxes.dart';
import 'package:epub_kutuphanesi/services/library_service.dart';
import 'package:epub_kutuphanesi/services/reading_progress_service.dart';
import 'package:epub_kutuphanesi/utils/resume_cfi.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

/// KUTUPHANE.md §9 Android smoke — ekle → CFI → Hive “kill” → aynı CFI.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android: import + kill sonrası CFI korunur', (tester) async {
    await Hive.initFlutter();
    await HiveBoxes.openAll();

    final docs = await getApplicationDocumentsDirectory();
    final source = File('${docs.path}/smoke_source/minimal.epub');
    await source.parent.create(recursive: true);
    final bytes = await rootBundle.load('test/fixtures/minimal.epub');
    await source.writeAsBytes(bytes.buffer.asUint8List(), flush: true);

    final importService = EpubImportService();
    final library = LibraryService();
    final progressService = ReadingProgressService();

    final book = await importService.importFromPath(
      source.path,
      fallbackTitle: 'minimal.epub',
    );
    expect(book.title, 'Smoke Test Kitabı');
    expect(book.author, 'Test Yazar');
    expect(File(book.filePath).existsSync(), isTrue);
    // Orijinal kaynak kopyası yerinde kalır
    expect(source.existsSync(), isTrue);

    await library.addBook(book);

    const savedCfi = 'epubcfi(/6/8!/4/2/2/2/1:12)';
    await progressService.saveProgress(
      ReadingProgress(
        bookId: book.id,
        cfi: savedCfi,
        percent: 0.62,
        updatedAt: DateTime.now(),
      ),
    );
    await library.updateBook(
      book.copyWith(lastCfi: savedCfi, progressPercent: 0.62),
    );

    // Süreç kill eşleniği: Hive kapat → cihaz depolamasından yeniden aç
    await Hive.close();
    await Hive.initFlutter();
    await HiveBoxes.openAll();

    final loadedProgress =
        await ReadingProgressService().getProgress(book.id);
    final loadedBook = await LibraryService().getBook(book.id);

    expect(loadedProgress?.cfi, savedCfi);
    expect(
      resolveResumeCfi(
        progressCfi: loadedProgress?.cfi,
        bookLastCfi: loadedBook?.lastCfi,
      ),
      savedCfi,
    );
    expect(loadedBook?.progressPercent, closeTo(0.62, 1e-9));
  });
}
