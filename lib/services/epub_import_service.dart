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
  EpubImportException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// EPUB seçimi, kopyalama ve metadata.
class EpubImportService {
  EpubImportService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  /// Picker iptalinde `null`. Başarıda Hive’a yazılmamış [Book] döner.
  Future<Book?> importFromPicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['epub'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.single;
    final sourcePath = picked.path;
    if (sourcePath == null) {
      throw EpubImportException(
        'Dosya yolu alınamadı. Lütfen başka bir konumdan tekrar deneyin.',
      );
    }

    return importFromPath(sourcePath, fallbackTitle: picked.name);
  }

  /// Test ve yeniden-ekleme için yol üzerinden import.
  Future<Book> importFromPath(
    String sourcePath, {
    String? fallbackTitle,
    String? existingId,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw EpubImportException('Seçilen dosya bulunamadı.');
    }

    final id = existingId ?? _uuid.v4();
    final docs = await getApplicationDocumentsDirectory();
    final epubsDir = Directory(p.join(docs.path, 'epubs'));
    final coversDir = Directory(p.join(docs.path, 'covers'));
    await epubsDir.create(recursive: true);
    await coversDir.create(recursive: true);

    final destPath = p.join(epubsDir.path, '$id.epub');
    final dest = File(destPath);

    try {
      await source.copy(destPath);
    } on FileSystemException {
      throw EpubImportException(
        'Dosya kopyalanamadı. Depolama alanını kontrol edin.',
      );
    }

    late EpubBook epub;
    try {
      final bytes = await dest.readAsBytes();
      epub = await EpubReader.readBook(bytes);
    } catch (_) {
      await _safeDelete(dest);
      throw EpubImportException(
        'Bu dosya geçerli bir EPUB değil veya bozulmuş.',
      );
    }

    final fileName = fallbackTitle ?? p.basename(sourcePath);
    final title = _nonEmpty(epub.Title) ??
        p.basenameWithoutExtension(fileName).replaceAll('_', ' ');
    final author = _nonEmpty(epub.Author) ?? 'Bilinmeyen';

    String? coverPath;
    final coverImage = epub.CoverImage;
    if (coverImage != null) {
      try {
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
      filePath: destPath,
      coverImagePath: coverPath,
      addedAt: DateTime.now(),
    );
  }

  String? _nonEmpty(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _safeDelete(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
