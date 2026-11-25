import 'dart:convert';
import 'dart:io';

import 'package:epub_kutuphanesi/models/book.dart';
import 'package:epub_kutuphanesi/services/epub_import_service.dart';
import 'package:epub_kutuphanesi/services/hive_boxes.dart';
import 'package:epub_kutuphanesi/services/library_service.dart';
import 'package:epub_kutuphanesi/services/pdf_conversion_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
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

enum _ServerMode { success, failed, badEpub, unauthorized }

class _FakeConverter {
  _FakeConverter(this.epubBytes);

  final List<int> epubBytes;
  var mode = _ServerMode.success;
  var posts = 0;
  var polls = 0;
  HttpServer? _server;

  Future<String> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    server.listen((request) async {
      if (request.method == 'POST') {
        await request.drain<void>();
      }
      final auth = request.headers.value('authorization');
      final path = request.uri.path;
      final authOk = auth == null || auth == 'Bearer test-key';
      if (mode == _ServerMode.unauthorized || !authOk) {
        request.response.statusCode = 401;
        request.response.write(jsonEncode({'error': 'Yetkisiz.'}));
        await request.response.close();
        return;
      }
      if (request.method == 'POST' && path == '/v1/conversions') {
        posts += 1;
        request.response.statusCode = 202;
        request.response.write(jsonEncode({'id': 'job-1', 'status': 'queued'}));
        await request.response.close();
        return;
      }
      if (request.method == 'GET' && path == '/v1/conversions/job-1/epub') {
        request.response.statusCode = 200;
        request.response.add(
          mode == _ServerMode.badEpub ? [1, 2, 3, 4] : epubBytes,
        );
        await request.response.close();
        return;
      }
      if (request.method == 'GET' && path == '/v1/conversions/job-1') {
        polls += 1;
        final status = switch (mode) {
          _ServerMode.failed => 'failed',
          _ => polls < 2 ? 'ocr' : 'ready',
        };
        request.response.write(
          jsonEncode({
            'id': 'job-1',
            'status': status,
            'error': status == 'failed' ? 'OCR başarısız.' : null,
          }),
        );
        await request.response.close();
        return;
      }
      request.response.statusCode = 404;
      request.response.write(jsonEncode({'error': 'Yol yok: $path'}));
      await request.response.close();
    });
    return 'http://${server.address.host}:${server.port}';
  }

  Future<void> close() async {
    await _server?.close(force: true);
  }
}

void main() {
  late Directory tempDir;
  late List<int> epubBytes;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pdf_conv_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    Hive.init(tempDir.path);
    await HiveBoxes.openAll();
    final fixture = File('test/fixtures/minimal.epub');
    expect(await fixture.exists(), isTrue);
    epubBytes = await fixture.readAsBytes();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Book stagedPdf() {
    final pdf = File('${tempDir.path}/kaynak.pdf')..writeAsStringSync('%PDF');
    return Book(
      id: 'pdf-1',
      title: 'kaynak',
      author: 'Bilinmeyen',
      filePath: '',
      addedAt: DateTime.utc(2024, 3, 1),
      conversionStatus: ConversionStatus.converting,
      localSourcePath: pdf.path,
    );
  }

  test('yükler, durumu sorar ve EPUB indirince kitabı hazırlar', () async {
    final converter = _FakeConverter(epubBytes);
    final base = await converter.start();
    final apiOwned = HttpConversionApi();
    final conversion = PdfConversionService(
      library: LibraryService(),
      epubImport: EpubImportService(),
      api: apiOwned,
      pollInterval: const Duration(milliseconds: 10),
    );
    addTearDown(apiOwned.close);
    addTearDown(converter.close);

    final library = LibraryService();
    final book = stagedPdf();
    await library.addBook(book);
    final notices = <String>[];

    await conversion.convert(
      book,
      baseUrl: base,
      apiKey: 'test-key',
      onMessage: notices.add,
    );

    final saved = await library.getBook(book.id);
    expect(saved, isNotNull);
    expect(saved!.conversionStatus, ConversionStatus.ready);
    expect(saved.title, 'Smoke Test Kitabı');
    expect(saved.author, 'Test Yazar');
    expect(saved.conversionJobId, isNull);
    expect(saved.localSourcePath, isNull);
    expect(File(book.localSourcePath!).existsSync(), isFalse);
    expect(File(saved.filePath).existsSync(), isTrue);
    expect(converter.posts, 1);
    expect(converter.polls, greaterThanOrEqualTo(2));
    expect(notices.single, contains('EPUB olarak hazır'));
  });

  test('sunucu hatasında PDF durur, yarım EPUB kalmaz', () async {
    final converter = _FakeConverter(epubBytes)..mode = _ServerMode.failed;
    final base = await converter.start();
    final apiOwned = HttpConversionApi();
    final conversion = PdfConversionService(
      library: LibraryService(),
      epubImport: EpubImportService(),
      api: apiOwned,
      pollInterval: const Duration(milliseconds: 10),
    );
    addTearDown(apiOwned.close);
    addTearDown(converter.close);

    final library = LibraryService();
    final book = stagedPdf();
    await library.addBook(book);

    await conversion.convert(book, baseUrl: base, apiKey: 'test-key');

    final saved = await library.getBook(book.id);
    expect(saved!.conversionStatus, ConversionStatus.failed);
    expect(saved.conversionError, 'OCR başarısız.');
    expect(File(book.localSourcePath!).existsSync(), isTrue);
    expect(File('${tempDir.path}/epubs/${book.id}.epub').existsSync(), isFalse);
  });

  test('bozuk indirme kitabı başarısız bırakır ve EPUB’u siler', () async {
    final converter = _FakeConverter(epubBytes)..mode = _ServerMode.badEpub;
    final base = await converter.start();
    final apiOwned = HttpConversionApi();
    final conversion = PdfConversionService(
      library: LibraryService(),
      epubImport: EpubImportService(),
      api: apiOwned,
      pollInterval: const Duration(milliseconds: 10),
    );
    addTearDown(apiOwned.close);
    addTearDown(converter.close);

    final library = LibraryService();
    final book = stagedPdf();
    await library.addBook(book);

    await conversion.convert(book, baseUrl: base, apiKey: 'test-key');

    final saved = await library.getBook(book.id);
    expect(saved!.conversionStatus, ConversionStatus.failed);
    expect(saved.conversionError, contains('EPUB'));
    expect(File(book.localSourcePath!).existsSync(), isTrue);
    expect(File('${tempDir.path}/epubs/${book.id}.epub').existsSync(), isFalse);
  });

  test('yetkisiz yanıt Türkçe hata olarak kaydolur', () async {
    final converter = _FakeConverter(epubBytes)
      ..mode = _ServerMode.unauthorized;
    final base = await converter.start();
    final apiOwned = HttpConversionApi();
    final conversion = PdfConversionService(
      library: LibraryService(),
      epubImport: EpubImportService(),
      api: apiOwned,
      pollInterval: const Duration(milliseconds: 10),
    );
    addTearDown(apiOwned.close);
    addTearDown(converter.close);

    final library = LibraryService();
    final book = stagedPdf();
    await library.addBook(book);

    await conversion.convert(book, baseUrl: base, apiKey: 'yanlis');

    final saved = await library.getBook(book.id);
    expect(saved!.conversionStatus, ConversionStatus.failed);
    expect(saved.conversionError, 'Yetkisiz.');
    expect(File(book.localSourcePath!).existsSync(), isTrue);
  });

  test('adres yokken ağ çağrısı yapmadan failed olur', () async {
    final apiOwned = HttpConversionApi();
    addTearDown(apiOwned.close);
    final conversion = PdfConversionService(
      library: LibraryService(),
      epubImport: EpubImportService(),
      api: apiOwned,
      pollInterval: const Duration(milliseconds: 10),
    );
    final library = LibraryService();
    final book = stagedPdf();
    await library.addBook(book);

    await conversion.convert(book, baseUrl: '', apiKey: '');

    final saved = await library.getBook(book.id);
    expect(saved!.conversionStatus, ConversionStatus.failed);
    expect(saved.conversionError, contains('yapılandırılmamış'));
    expect(File(book.localSourcePath!).existsSync(), isTrue);
  });

  test('anahtarsız istek başarıyla EPUB indirir', () async {
    final converter = _FakeConverter(epubBytes);
    final base = await converter.start();
    final apiOwned = HttpConversionApi();
    final conversion = PdfConversionService(
      library: LibraryService(),
      epubImport: EpubImportService(),
      api: apiOwned,
      pollInterval: const Duration(milliseconds: 10),
    );
    addTearDown(apiOwned.close);
    addTearDown(converter.close);

    final library = LibraryService();
    final book = stagedPdf();
    await library.addBook(book);

    await conversion.convert(book, baseUrl: base);

    final saved = await library.getBook(book.id);
    expect(saved!.isReady, isTrue);
    expect(converter.posts, 1);
  });

  test(
    'mevcut iş numarasıyla yeniden yüklemeden indirmeye devam eder',
    () async {
      final converter = _FakeConverter(epubBytes);
      final base = await converter.start();
      final apiOwned = HttpConversionApi();
      final conversion = PdfConversionService(
        library: LibraryService(),
        epubImport: EpubImportService(),
        api: apiOwned,
        pollInterval: const Duration(milliseconds: 10),
      );
      addTearDown(apiOwned.close);
      addTearDown(converter.close);

      final library = LibraryService();
      final book = stagedPdf().copyWith(conversionJobId: 'job-1');
      await library.addBook(book);

      await conversion.convert(book, baseUrl: base, apiKey: 'test-key');

      final saved = await library.getBook(book.id);
      expect(saved!.isReady, isTrue);
      expect(converter.posts, 0);
    },
  );
}
