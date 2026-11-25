import 'package:epub_kutuphanesi/models/app_settings.dart';
import 'package:epub_kutuphanesi/models/book.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('eski Hive kaydı dönüşüm alanlarını ready kabul eder', () {
    final book = Book.fromMap({
      'id': 'eski',
      'title': 'Kitap',
      'author': 'Yazar',
      'filePath': '/kitap.epub',
      'addedAt': '2024-01-01T00:00:00.000',
    });

    expect(book.conversionStatus, ConversionStatus.ready);
    expect(book.conversionJobId, isNull);
    expect(book.localSourcePath, isNull);
    expect(book.conversionError, isNull);
    expect(book.isReady, isTrue);
  });

  test('dönüşüm alanları kayda yazılıp temizlenebilir', () {
    final book = Book(
      id: 'pdf',
      title: 'Tarama',
      author: 'Bilinmeyen',
      filePath: '',
      addedAt: DateTime.utc(2024, 5, 1),
      conversionStatus: ConversionStatus.failed,
      conversionJobId: 'job-1',
      localSourcePath: '/sources/pdf.pdf',
      conversionError: 'OCR başarısız.',
    );

    final loaded = Book.fromMap(book.toMap());
    expect(loaded.conversionStatus, ConversionStatus.failed);
    expect(loaded.conversionJobId, 'job-1');
    expect(loaded.localSourcePath, '/sources/pdf.pdf');
    expect(loaded.conversionError, 'OCR başarısız.');

    final cleared = loaded.copyWith(
      conversionStatus: ConversionStatus.ready,
      conversionJobId: null,
      localSourcePath: null,
      conversionError: null,
      filePath: '/epubs/pdf.epub',
    );
    expect(cleared.conversionJobId, isNull);
    expect(cleared.localSourcePath, isNull);
    expect(cleared.conversionError, isNull);
    expect(cleared.isReady, isTrue);
  });

  test('eski ayar kaydı okuma alanlarını korur', () {
    final settings = AppSettings.fromMap({
      'themeMode': 'dark',
      'readingTheme': 'sepia',
      'fontSize': 20,
      'paginated': false,
      'converterBaseUrl': 'http://eski',
      'converterApiKey': 'eski-anahtar',
    });

    expect(settings.readingTheme, ReadingTheme.sepia);
    expect(settings.themeMode, ThemeMode.dark);
    expect(settings.fontSize, 20);
    expect(settings.paginated, isFalse);
    expect(settings.toMap().containsKey('converterBaseUrl'), isFalse);
  });
}
