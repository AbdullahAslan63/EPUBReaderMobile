import 'package:epub_kutuphanesi/utils/chapter_locator.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  EpubChapter ch({
    required String title,
    required String href,
    String id = '',
    List<EpubChapter> sub = const [],
  }) {
    return EpubChapter(title: title, href: href, id: id, subitems: sub);
  }

  test('flatten TOC ağacını sırayla düzleştirir', () {
    final chapters = [
      ch(
        title: 'A',
        href: 'a.xhtml',
        sub: [ch(title: 'A1', href: 'a1.xhtml')],
      ),
      ch(title: 'B', href: 'b.xhtml'),
    ];
    final flat = ChapterLocator.flatten(chapters);
    expect(flat.map((c) => c.title), ['A', 'A1', 'B']);
  });

  test('findForLocation CFI içindeki dosya adıyla eşleşir', () {
    final chapters = [
      ch(title: 'Giriş', href: 'Text/intro.xhtml', id: 'intro'),
      ch(title: 'Bölüm 1', href: 'Text/chapter1.xhtml', id: 'c1'),
    ];
    final found = ChapterLocator.findForLocation(
      chapters,
      'epubcfi(/6/8[c1]!/4/2/chapter1.xhtml/2/1:0)',
    );
    expect(found?.title, 'Bölüm 1');
  });

  test('findForLocation en uzun href eşleşmesini seçer', () {
    final chapters = [
      ch(title: 'Kısa', href: 'ch.xhtml'),
      ch(title: 'Uzun', href: 'Text/ch.xhtml'),
    ];
    final found = ChapterLocator.findForLocation(
      chapters,
      'OEBPS/Text/ch.xhtml',
    );
    expect(found?.title, 'Uzun');
  });

  test('findForLocation boş CFI’de null döner', () {
    expect(
      ChapterLocator.findForLocation(
        [ch(title: 'A', href: 'a.xhtml')],
        null,
      ),
      isNull,
    );
  });
}
