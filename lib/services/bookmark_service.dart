import 'package:hive/hive.dart';

import '../models/bookmark.dart';
import 'hive_boxes.dart';

class BookmarkService {
  BookmarkService({Box<Map>? bookmarksBox})
      : _bookmarks = bookmarksBox ?? HiveBoxes.bookmarksBox;

  final Box<Map> _bookmarks;

  Future<List<Bookmark>> getAll() async {
    final list = _bookmarks.values
        .map((raw) => Bookmark.fromMap(Map<dynamic, dynamic>.from(raw)))
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<List<Bookmark>> getByBookId(String bookId) async {
    final list = (await getAll()).where((b) => b.bookId == bookId).toList();
    return list;
  }

  Future<void> add(Bookmark bookmark) async {
    await _bookmarks.put(bookmark.id, bookmark.toMap());
  }

  Future<void> delete(String id) async {
    await _bookmarks.delete(id);
  }
}
