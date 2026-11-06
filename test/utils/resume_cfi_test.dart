import 'package:epub_kutuphanesi/utils/resume_cfi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('progress CFI doluysa Book aynasını ezer', () {
    expect(
      resolveResumeCfi(
        progressCfi: 'epubcfi(/6/4!/4)',
        bookLastCfi: 'epubcfi(/6/2!/4)',
      ),
      'epubcfi(/6/4!/4)',
    );
  });

  test('progress boşsa Book.lastCfi yedek olur', () {
    expect(
      resolveResumeCfi(progressCfi: '', bookLastCfi: 'epubcfi(/6/2)'),
      'epubcfi(/6/2)',
    );
    expect(
      resolveResumeCfi(progressCfi: null, bookLastCfi: 'epubcfi(/6/2)'),
      'epubcfi(/6/2)',
    );
  });

  test('ikisi de boşsa null', () {
    expect(resolveResumeCfi(progressCfi: null, bookLastCfi: null), isNull);
    expect(resolveResumeCfi(progressCfi: '', bookLastCfi: ''), isNull);
  });
}
