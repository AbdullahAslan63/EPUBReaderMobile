import 'package:epub_kutuphanesi/app.dart';
import 'package:epub_kutuphanesi/services/hive_boxes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async => '/tmp/epub_test_docs';

  @override
  Future<String?> getTemporaryPath() async => '/tmp/epub_test_tmp';

  @override
  Future<String?> getApplicationSupportPath() async => '/tmp/epub_test_support';

  @override
  Future<String?> getLibraryPath() async => '/tmp/epub_test_lib';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    PathProviderPlatform.instance = _FakePathProvider();
    Hive.init('/tmp/epub_kutuphanesi_widget_hive');
    await HiveBoxes.openAll();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  testWidgets('Ana kabuk Kitaplık sekmesini gösterir', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: EpubKutuphanesiApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kitaplık'), findsWidgets);
    expect(find.text('Henüz kitap yok'), findsOneWidget);
  });
}
