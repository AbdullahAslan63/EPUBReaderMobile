import 'dart:io';

import 'package:epubx/epubx.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/book.dart';

/// Kullanıcıya gösterilecek import hataları.
class EpubImportException implements Exception {
  const EpubImportException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// EPUB seçimi, PDF kopyalama ve metadata.
class EpubImportService {
  EpubImportService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  static const allowedExtensions = ['epub', 'pdf'];

  /// Picker iptalinde `null`. Başarıda Hive’a yazılmamış [Book] döner.
  /// PDF ise durum `converting` olur; EPUB ise metadata okunmuş hazır kitap.
  Future<Book?> importFromPicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.single;
    final sourcePath = picked.path;
    if (sourcePath == null) {
      throw const EpubImportException(
        'Dosya yolu alınamadı. Lütfen başka bir konumdan tekrar deneyin.',
      );
    }

    if (_isPdf(sourcePath)) {
      return stagePdfCopy(sourcePath, fallbackTitle: picked.name);
    }
    return importFromPath(sourcePath, fallbackTitle: picked.name);
  }

  /// Test ve yeniden-ekleme için yol üzerinden EPUB import.
  Future<Book> importFromPath(
    String sourcePath, {
    String? fallbackTitle,
    String? existingId,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw const EpubImportException('Seçilen dosya bulunamadı.');
    }

    final id = existingId ?? _uuid.v4();
    final docs = await getApplicationDocumentsDirectory();
    final epubsDir = Directory(p.join(docs.path, 'epubs'));
    await epubsDir.create(recursive: true);

    final destPath = p.join(epubsDir.path, '$id.epub');
    final dest = File(destPath);

    try {
      await source.copy(destPath);
    } on FileSystemException {
      throw const EpubImportException(
        'Dosya kopyalanamadı. Depolama alanını kontrol edin.',
      );
    }

    final fileName = fallbackTitle ?? p.basename(sourcePath);
    try {
      return await _bookFromEpubFile(
        id: id,
        epubPath: destPath,
        fallbackTitle: fileName,
        addedAt: DateTime.now(),
      );
    } catch (e) {
      await _safeDelete(dest);
      if (e is EpubImportException) rethrow;
      throw const EpubImportException(
        'Bu dosya geçerli bir EPUB değil veya bozulmuş.',
      );
    }
  }

  /// PDF’yi belge klasörüne kopyalar. Orijinal dosyaya dokunulmaz.
  /// Hive kaydı yazılmaz.
  Future<Book> stagePdfCopy(
    String sourcePath, {
    String? fallbackTitle,
    String? existingId,
    DateTime? addedAt,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw const EpubImportException('Seçilen dosya bulunamadı.');
    }

    final id = existingId ?? _uuid.v4();
    final docs = await getApplicationDocumentsDirectory();
    final sourcesDir = Directory(p.join(docs.path, 'sources'));
    await sourcesDir.create(recursive: true);
    final destPath = p.join(sourcesDir.path, '$id.pdf');

    try {
      await source.copy(destPath);
    } on FileSystemException {
      await _safeDelete(File(destPath));
      throw const EpubImportException(
        'Dosya kopyalanamadı. Depolama alanını kontrol edin.',
      );
    }

    final fileName = fallbackTitle ?? p.basename(sourcePath);
    final title = p.basenameWithoutExtension(fileName).replaceAll('_', ' ');
    return Book(
      id: id,
      title: title.trim().isEmpty ? 'Bilinmeyen' : title.trim(),
      author: 'Bilinmeyen',
      filePath: '',
      addedAt: addedAt ?? DateTime.now(),
      conversionStatus: ConversionStatus.converting,
      localSourcePath: destPath,
    );
  }

  /// İndirilmiş EPUB’dan metadata okur. Geçersizse dosyayı siler.
  Future<Book> describeCopiedEpub(Book book, String epubPath) async {
    try {
      return await _bookFromEpubFile(
        id: book.id,
        epubPath: epubPath,
        fallbackTitle: book.title,
        addedAt: book.addedAt,
        lastOpenedAt: book.lastOpenedAt,
        lastCfi: book.lastCfi,
        progressPercent: book.progressPercent,
      );
    } catch (e) {
      await _safeDelete(File(epubPath));
      if (e is EpubImportException) rethrow;
      throw const EpubImportException(
        'Bu dosya geçerli bir EPUB değil veya bozulmuş.',
      );
    }
  }

  Future<void> discardStagedFile(String? path) => _safeDeletePath(path);

  bool _isPdf(String sourcePath) =>
      p.extension(sourcePath).toLowerCase() == '.pdf';

  Future<Book> _bookFromEpubFile({
    required String id,
    required String epubPath,
    required String fallbackTitle,
    required DateTime addedAt,
    DateTime? lastOpenedAt,
    String? lastCfi,
    double progressPercent = 0,
  }) async {
    final dest = File(epubPath);
    final EpubBook epub;
    try {
      final bytes = await dest.readAsBytes();
      epub = await EpubReader.readBook(bytes);
    } catch (_) {
      throw const EpubImportException(
        'Bu dosya geçerli bir EPUB değil veya bozulmuş.',
      );
    }

    final title =
        _nonEmpty(epub.Title) ??
        p.basenameWithoutExtension(fallbackTitle).replaceAll('_', ' ');
    final author = _nonEmpty(epub.Author) ?? 'Bilinmeyen';

    String? coverPath;
    final coverImage = epub.CoverImage;
    if (coverImage != null) {
      try {
        final docs = await getApplicationDocumentsDirectory();
        final coversDir = Directory(p.join(docs.path, 'covers'));
        await coversDir.create(recursive: true);
        final jpg = img.encodeJpg(coverImage, quality: 85);
        coverPath = p.join(coversDir.path, '$id.jpg');
        await File(coverPath).writeAsBytes(jpg, flush: true);
      } catch (_) {
        coverPath = null;
      }
    }

    return Book(
      id: id,
      title: title,
      author: author,
      filePath: epubPath,
      coverImagePath: coverPath,
      addedAt: addedAt,
      lastOpenedAt: lastOpenedAt,
      lastCfi: lastCfi,
      progressPercent: progressPercent,
    );
  }

  String? _nonEmpty(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _safeDelete(File file) => _safeDeletePath(file.path);

  Future<void> _safeDeletePath(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
