import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/book.dart';
import '../../models/bookmark.dart';
import '../../providers/bookmarks_provider.dart';
import '../../providers/library_provider.dart';
import '../../widgets/empty_state.dart';
import '../reader/reader_screen.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarksProvider);
    final booksAsync = ref.watch(booksProvider);

    return bookmarksAsync.when(
      data: (bookmarks) {
        if (bookmarks.isEmpty) {
          return const EmptyState(
            icon: Icons.bookmark_border,
            title: 'Henüz işaret yok',
            message:
                'Okurken menüden işaret ekleyebilirsiniz. İşaretler CFI ile kaydedilir.',
          );
        }

        final books = {
          for (final b in booksAsync.valueOrNull ?? <Book>[]) b.id: b,
        };

        final grouped = <String, List<Bookmark>>{};
        for (final bm in bookmarks) {
          grouped.putIfAbsent(bm.bookId, () => []).add(bm);
        }

        return ListView(
          children: [
            for (final entry in grouped.entries) ...[
              ListTile(
                title: Text(
                  books[entry.key]?.title ?? 'Bilinmeyen kitap',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(books[entry.key]?.author ?? ''),
              ),
              for (final bm in entry.value)
                Dismissible(
                  key: ValueKey(bm.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Theme.of(context).colorScheme.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(
                      Icons.delete,
                      color: Theme.of(context).colorScheme.onError,
                    ),
                  ),
                  onDismissed: (_) {
                    ref.read(bookmarksProvider.notifier).deleteBookmark(bm.id);
                  },
                  child: ListTile(
                    leading: const Icon(Icons.bookmark),
                    title: Text(
                      bm.note?.isNotEmpty == true
                          ? bm.note!
                          : 'İşaret',
                    ),
                    subtitle: Text(
                      _formatDate(bm.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ReaderScreen(
                            bookId: bm.bookId,
                            initialCfiOverride: bm.cfi,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const Divider(),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('İşaretler yüklenemedi: $e')),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.'
        '${dt.year}';
  }
}
