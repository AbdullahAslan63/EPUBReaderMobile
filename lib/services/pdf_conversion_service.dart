import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/book.dart';
import 'epub_import_service.dart';
import 'library_service.dart';

class PdfConversionException implements Exception {
  const PdfConversionException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ConversionSnapshot {
  const ConversionSnapshot({required this.status, this.error});

  final String status;
  final String? error;
}

/// Sunucu dönüştürme HTTP uçları.
class HttpConversionApi {
  HttpConversionApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  void close() => _client.close();

  Future<String> startJob({
    required Uri conversionsUri,
    String apiKey = '',
    required File pdf,
  }) async {
    final request = http.MultipartRequest('POST', conversionsUri);
    request.headers.addAll(_headers(apiKey));
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        pdf.path,
        filename: p.basename(pdf.path),
      ),
    );
    final streamed = await _client.send(request);
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 202) {
      throw PdfConversionException(_errorMessage(streamed.statusCode, body));
    }
    final decoded = _decodeMap(body);
    final id = decoded['id'];
    if (id is! String || id.isEmpty) {
      throw const PdfConversionException('Sunucu iş numarası döndürmedi.');
    }
    return id;
  }

  Future<ConversionSnapshot> fetchJob({
    required Uri conversionsUri,
    String apiKey = '',
    required String jobId,
  }) async {
    final response = await _client.get(
      _jobUri(conversionsUri, jobId),
      headers: _headers(apiKey),
    );
    if (response.statusCode != 200) {
      throw PdfConversionException(
        _errorMessage(response.statusCode, response.body),
      );
    }
    final decoded = _decodeMap(response.body);
    final status = decoded['status'];
    if (status is! String || status.isEmpty) {
      throw const PdfConversionException('Sunucu iş durumu döndürmedi.');
    }
    final error = decoded['error'];
    return ConversionSnapshot(
      status: status,
      error: error is String && error.isNotEmpty ? error : null,
    );
  }

  Future<void> downloadEpub({
    required Uri conversionsUri,
    String apiKey = '',
    required String jobId,
    required File dest,
  }) async {
    final request = http.Request('GET', _jobUri(conversionsUri, '$jobId/epub'));
    request.headers.addAll(_headers(apiKey));
    final streamed = await _client.send(request);
    if (streamed.statusCode != 200) {
      final body = await streamed.stream.bytesToString();
      throw PdfConversionException(_errorMessage(streamed.statusCode, body));
    }
    await dest.parent.create(recursive: true);
    try {
      final sink = dest.openWrite();
      await streamed.stream.pipe(sink);
    } catch (_) {
      await _deleteQuiet(dest);
      throw const PdfConversionException('EPUB indirilemedi. Bağlantı koptu.');
    }
  }

  Map<String, String> _headers(String apiKey) {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) return const {};
    return {'Authorization': 'Bearer $trimmed'};
  }

  Map<String, dynamic> _decodeMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {}
    throw const PdfConversionException('Sunucu yanıtı okunamadı.');
  }

  String _errorMessage(int status, String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is String) {
        return _clip(decoded['error'] as String);
      }
    } catch (_) {}
    return 'Dönüştürme sunucusu hata verdi ($status).';
  }
}

/// PDF kopyasını sunucuya yollar, EPUB’u indirir, kitabı hazır işaretler.
class PdfConversionService {
  PdfConversionService({
    required LibraryService library,
    required EpubImportService epubImport,
    HttpConversionApi? api,
    this.pollInterval = const Duration(seconds: 3),
  }) : _library = library,
       _epubImport = epubImport,
       _api = api ?? HttpConversionApi();

  final LibraryService _library;
  final EpubImportService _epubImport;
  final HttpConversionApi _api;
  final Duration pollInterval;
  final Set<String> _inflight = {};
  final Set<String> _cancelled = {};

  void cancel(String bookId) {
    _cancelled.add(bookId);
  }

  Future<void> convert(
    Book book, {
    required String baseUrl,
    String apiKey = '',
    void Function(Book book)? onUpdated,
    void Function(String message)? onMessage,
  }) async {
    if (!_inflight.add(book.id)) return;
    _cancelled.remove(book.id);
    try {
      await _run(
        book,
        baseUrl: baseUrl,
        apiKey: apiKey,
        onUpdated: onUpdated,
        onMessage: onMessage,
      );
    } finally {
      _inflight.remove(book.id);
    }
  }

  Future<void> _run(
    Book book, {
    required String baseUrl,
    String apiKey = '',
    void Function(Book book)? onUpdated,
    void Function(String message)? onMessage,
  }) async {
    if (baseUrl.trim().isEmpty) {
      await _fail(
        book,
        'Dönüştürme sunucusu yapılandırılmamış.',
        onUpdated: onUpdated,
        onMessage: onMessage,
      );
      return;
    }

    final Uri conversionsUri;
    try {
      conversionsUri = _conversionsUri(baseUrl);
    } on PdfConversionException catch (e) {
      await _fail(book, e.message, onUpdated: onUpdated, onMessage: onMessage);
      return;
    }

    try {
      var current = await _library.getBook(book.id) ?? book;
      if (!_alive(current.id)) return;

      var jobId = current.conversionJobId;
      if (jobId == null || jobId.isEmpty) {
        final sourcePath = current.localSourcePath;
        if (sourcePath == null || !File(sourcePath).existsSync()) {
          await _fail(
            current,
            'PDF kopyası bulunamadı. Kitabı yeniden ekleyin.',
            onUpdated: onUpdated,
            onMessage: onMessage,
          );
          return;
        }
        jobId = await _api.startJob(
          conversionsUri: conversionsUri,
          apiKey: apiKey.trim(),
          pdf: File(sourcePath),
        );
        current = current.copyWith(
          conversionStatus: ConversionStatus.converting,
          conversionJobId: jobId,
          conversionError: null,
        );
        if (!await _save(current, onUpdated: onUpdated)) return;
      }

      while (true) {
        if (!_alive(current.id)) return;
        final snapshot = await _api.fetchJob(
          conversionsUri: conversionsUri,
          apiKey: apiKey.trim(),
          jobId: jobId,
        );
        if (snapshot.status == 'failed') {
          await _fail(
            current,
            snapshot.error ?? 'Dönüştürme başarısız.',
            onUpdated: onUpdated,
            onMessage: onMessage,
          );
          return;
        }
        if (snapshot.status == 'ready') break;
        await Future<void>.delayed(pollInterval);
      }

      if (!_alive(current.id)) return;
      final docs = await getApplicationDocumentsDirectory();
      final dest = File(p.join(docs.path, 'epubs', '${current.id}.epub'));
      await _api.downloadEpub(
        conversionsUri: conversionsUri,
        apiKey: apiKey.trim(),
        jobId: jobId,
        dest: dest,
      );
      if (!_alive(current.id)) {
        await _deleteQuiet(dest);
        return;
      }

      final latest = await _library.getBook(current.id);
      if (latest == null || !_alive(latest.id)) {
        await _deleteQuiet(dest);
        return;
      }

      final described = await _epubImport.describeCopiedEpub(latest, dest.path);
      final ready = described.copyWith(
        conversionStatus: ConversionStatus.ready,
        conversionJobId: null,
        localSourcePath: null,
        conversionError: null,
      );
      if (!await _save(ready, onUpdated: onUpdated)) {
        await _deleteQuiet(dest);
        final cover = ready.coverImagePath;
        if (cover != null) await _deleteQuiet(File(cover));
        return;
      }
      await _epubImport.discardStagedFile(latest.localSourcePath);
      _notify(() => onMessage?.call('“${ready.title}” EPUB olarak hazır.'));
    } on PdfConversionException catch (e) {
      await _fail(book, e.message, onUpdated: onUpdated, onMessage: onMessage);
    } on EpubImportException catch (e) {
      await _fail(book, e.message, onUpdated: onUpdated, onMessage: onMessage);
    } catch (_) {
      await _fail(
        book,
        'Dönüştürme sırasında bağlantı koptu.',
        onUpdated: onUpdated,
        onMessage: onMessage,
      );
    }
  }

  bool _alive(String id) => !_cancelled.contains(id);

  Future<bool> _save(Book book, {void Function(Book book)? onUpdated}) async {
    if (!_alive(book.id)) return false;
    final existing = await _library.getBook(book.id);
    if (existing == null || !_alive(book.id)) return false;
    await _library.updateBook(book);
    if (!_alive(book.id)) {
      await _library.deleteBook(book.id);
      return false;
    }
    _notify(() => onUpdated?.call(book));
    return true;
  }

  Future<void> _fail(
    Book book,
    String message, {
    void Function(Book book)? onUpdated,
    void Function(String message)? onMessage,
  }) async {
    final clipped = _clip(message);
    final existing = await _library.getBook(book.id);
    if (existing == null || !_alive(book.id)) return;
    final docs = await getApplicationDocumentsDirectory();
    await _deleteQuiet(File(p.join(docs.path, 'epubs', '${book.id}.epub')));
    final failed = existing.copyWith(
      filePath: '',
      conversionStatus: ConversionStatus.failed,
      conversionError: clipped,
    );
    if (!await _save(failed, onUpdated: onUpdated)) return;
    _notify(() => onMessage?.call(clipped));
  }

  void _notify(void Function() callback) {
    try {
      callback();
    } catch (_) {}
  }

  Uri _conversionsUri(String base) {
    var trimmed = base.trim();
    if (!trimmed.contains('://')) trimmed = 'http://$trimmed';
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) {
      throw const PdfConversionException('Dönüştürme adresi geçersiz.');
    }
    var path = uri.path;
    if (path.endsWith('/')) path = path.substring(0, path.length - 1);
    if (!path.endsWith('/v1/conversions')) {
      path = '${path.isEmpty ? '' : path}/v1/conversions';
    }
    if (!path.startsWith('/')) path = '/$path';
    return uri.replace(path: path);
  }
}

Uri _jobUri(Uri conversions, String suffix) {
  final basePath = conversions.path.endsWith('/')
      ? conversions.path
      : '${conversions.path}/';
  return conversions.replace(path: basePath).resolve(suffix);
}

String _clip(String message) {
  final trimmed = message.trim();
  if (trimmed.length <= 240) return trimmed;
  return '${trimmed.substring(0, 237)}...';
}

Future<void> _deleteQuiet(File file) async {
  try {
    if (await file.exists()) await file.delete();
  } catch (_) {}
}
