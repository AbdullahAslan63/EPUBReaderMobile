import 'dart:io';

import 'package:epub_kutuphanesi/models/reading_progress.dart';
import 'package:epub_kutuphanesi/services/hive_boxes.dart';
import 'package:epub_kutuphanesi/services/reading_progress_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('epub_progress_test_');
    Hive.init(tempDir.path);
    await HiveBoxes.openAll();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('saveProgress CFI ve yüzdeyi saklar', () async {
    final service = ReadingProgressService();
    await service.saveProgress(
      ReadingProgress(
        bookId: 'b1',
        cfi: 'epubcfi(/6/4!/4/2/2/2/1:0)',
        percent: 0.42,
        updatedAt: DateTime(2024, 5, 1),
      ),
    );

    final loaded = await service.getProgress('b1');
    expect(loaded?.cfi, 'epubcfi(/6/4!/4/2/2/2/1:0)');
    expect(loaded?.percent, 0.42);
  });

  test('saveLocations mevcut CFI bilgisini korur', () async {
    final service = ReadingProgressService();
    await service.saveProgress(
      ReadingProgress(
        bookId: 'b1',
        cfi: 'epubcfi(/6/2)',
        percent: 0.1,
        updatedAt: DateTime.now(),
      ),
    );
    await service.saveLocations('b1', '["loc"]');

    final loaded = await service.getProgress('b1');
    expect(loaded?.cfi, 'epubcfi(/6/2)');
    expect(loaded?.locationsJson, '["loc"]');
    expect(await service.getLocations('b1'), '["loc"]');
  });
}
