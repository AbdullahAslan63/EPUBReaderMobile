import 'package:hive_flutter/hive_flutter.dart';

/// Hive box adları — Map serileştirme (TypeAdapter yok).
abstract final class HiveBoxes {
  static const books = 'books';
  static const bookmarks = 'bookmarks';
  static const progress = 'progress';
  static const settings = 'settings';

  static Future<void> openAll() async {
    await Future.wait([
      Hive.openBox<Map>(books),
      Hive.openBox<Map>(bookmarks),
      Hive.openBox<Map>(progress),
      Hive.openBox(settings),
    ]);
  }

  static Box<Map> get booksBox => Hive.box<Map>(books);
  static Box<Map> get bookmarksBox => Hive.box<Map>(bookmarks);
  static Box<Map> get progressBox => Hive.box<Map>(progress);
  static Box get settingsBox => Hive.box(settings);
}
