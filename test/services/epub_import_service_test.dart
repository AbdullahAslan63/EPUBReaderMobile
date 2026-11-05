import 'dart:io';

import 'package:epub_kutuphanesi/services/epub_import_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

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

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('epub_import_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('bozuk dosya EpubImportException fırlatır ve kopya bırakmaz', () async {
    final bad = File('${tempDir.path}/bad.epub')
      ..writeAsStringSync('this is not an epub');

    final service = EpubImportService();
    expect(
      () => service.importFromPath(bad.path, fallbackTitle: 'bad.epub'),
      throwsA(isA<EpubImportException>()),
    );

    final epubs = Directory('${tempDir.path}/epubs');
    if (await epubs.exists()) {
      expect(epubs.listSync(), isEmpty);
    }
  });

  test('olmayan dosya Türkçe hata verir', () async {
    final service = EpubImportService();
    expect(
      () => service.importFromPath('${tempDir.path}/yok.epub'),
      throwsA(
        isA<EpubImportException>().having(
          (e) => e.message,
          'message',
          contains('bulunamadı'),
        ),
      ),
    );
  });
}
