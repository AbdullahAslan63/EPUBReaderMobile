import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';

/// Fihrist / CFI eşlemesi — TOC ağacını düzleştirir ve CFI’den bölüm bulur.
abstract final class ChapterLocator {
  static List<EpubChapter> flatten(List<EpubChapter> chapters) {
    final out = <EpubChapter>[];
    void walk(List<EpubChapter> list) {
      for (final c in list) {
        out.add(c);
        if (c.subitems.isNotEmpty) walk(c.subitems);
      }
    }

    walk(chapters);
    return out;
  }

  /// CFI veya navigasyon href’i ile en iyi eşleşen bölümü bulur.
  ///
  /// epub.js CFI çoğu zaman dosya yolu / id içerir; en uzun href parçası kazanır.
  static EpubChapter? findForLocation(
    List<EpubChapter> chapters,
    String? location,
  ) {
    if (location == null || location.isEmpty || chapters.isEmpty) {
      return null;
    }

    final flat = flatten(chapters);
    EpubChapter? best;
    var bestScore = 0;

    for (final chapter in flat) {
      for (final key in _matchKeys(chapter)) {
        if (key.isEmpty) continue;
        if (location.contains(key) || key.contains(location)) {
          if (key.length > bestScore) {
            best = chapter;
            bestScore = key.length;
          }
        }
      }
    }
    return best;
  }

  static Iterable<String> _matchKeys(EpubChapter chapter) sync* {
    final href = chapter.href.trim();
    if (href.isNotEmpty) {
      yield href;
      final noFrag = href.split('#').first;
      yield noFrag;
      final fileName = noFrag.split('/').last;
      if (fileName.isNotEmpty) yield fileName;
    }
    final id = chapter.id.trim();
    if (id.isNotEmpty) yield id;
  }
}
