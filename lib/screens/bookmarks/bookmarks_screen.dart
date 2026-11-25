import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/book.dart';
import '../../models/bookmark.dart';
import '../../providers/bookmarks_provider.dart';
import '../../providers/library_provider.dart';
import '../../widgets/app_page_header.dart';
import '../../widgets/book_cover.dart';
import '../../widgets/empty_state.dart';
import '../reader/reader_screen.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarksProvider);
    final booksAsync = ref.watch(booksProvider);

    return Column(
      children: [
        const AppPageHeader(title: 'İşaretler'),
        Expanded(
          child: bookmarksAsync.when(
            data: (bookmarks) {
              if (bookmarks.isEmpty) {
                return const EmptyState(
                  icon: Icons.bookmark_border,
                  title: 'Henüz işaret yok',
                  message:
                      'Okurken alt çubuktan işaret ekleyin. İşaretler CFI ile kaydedilir.',
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
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  for (final entry in grouped.entries) ...[
                    _BookHeading(book: books[entry.key]),
                    for (final bm in entry.value)
                      Dismissible(
                        key: ValueKey(bm.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Theme.of(context).colorScheme.errorContainer,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: Icon(
                            Icons.delete_outline,
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                        ),
                        onDismissed: (_) {
                          ref
                              .read(bookmarksProvider.notifier)
                              .deleteBookmark(bm.id);
                        },
                        child: _BookmarkRow(
                          bookmark: bm,
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
                  ],
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('İşaretler yüklenemedi: $e')),
          ),
        ),
      ],
    );
  }
}

class _BookHeading extends StatelessWidget {
  const _BookHeading({required this.book});

  final Book? book;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Row(
        children: [
          if (book != null) ...[
            BookCover(book: book!, width: 28, height: 40),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book?.title ?? 'Bilinmeyen kitap',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (book != null && book!.author.isNotEmpty)
                  Text(
                    book!.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookmarkRow extends StatelessWidget {
  const _BookmarkRow({required this.bookmark, required this.onTap});

  final Bookmark bookmark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final note = bookmark.note?.trim();
    final hasNote = note != null && note.isNotEmpty;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.bookmark_border,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasNote ? note : 'İşaret',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(bookmark.createdAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.'
        '${dt.year}';
  }
}
