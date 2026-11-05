import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/bookmark.dart';
import 'services_provider.dart';

final bookmarksProvider =
    AsyncNotifierProvider<BookmarksNotifier, List<Bookmark>>(
  BookmarksNotifier.new,
);

class BookmarksNotifier extends AsyncNotifier<List<Bookmark>> {
  @override
  Future<List<Bookmark>> build() {
    return ref.read(bookmarkServiceProvider).getAll();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(bookmarkServiceProvider).getAll(),
    );
  }

  Future<void> addBookmark({
    required String bookId,
    required String cfi,
    String? note,
  }) async {
    final bookmark = Bookmark(
      id: const Uuid().v4(),
      bookId: bookId,
      cfi: cfi,
      note: note,
      createdAt: DateTime.now(),
    );
    await ref.read(bookmarkServiceProvider).add(bookmark);
    await refresh();
  }

  Future<void> deleteBookmark(String id) async {
    await ref.read(bookmarkServiceProvider).delete(id);
    await refresh();
  }
}
