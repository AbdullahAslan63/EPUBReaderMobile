import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/book.dart';
import '../../providers/library_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../services/epub_import_service.dart';
import '../../widgets/book_cover.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/progress_chip.dart';
import '../reader/reader_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  var _importing = false;
  var _grid = true;

  Future<void> _import() async {
    setState(() => _importing = true);
    try {
      await ref.read(booksProvider.notifier).importBook();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kitap eklendi')),
        );
      }
    } on ImportCancelled {
      // sessiz
    } on EpubImportException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kitap eklenemedi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _confirmDelete(Book book) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kitabı sil'),
        content: Text('“${book.title}” kütüphaneden silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(booksProvider.notifier).deleteBook(book.id);
    }
  }

  Future<void> _openBook(Book book) async {
    final missing = !File(book.filePath).existsSync();
    if (missing) {
      final action = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Dosya bulunamadı'),
          content: const Text(
            'Bu kitabın EPUB dosyası cihazdan silinmiş görünüyor. '
            'Yeniden eklemek ister misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'reimport'),
              child: const Text('Yeniden ekle'),
            ),
          ],
        ),
      );
      if (action != 'reimport' || !mounted) return;
      try {
        final restored =
            await ref.read(booksProvider.notifier).reimportMissingFile(book);
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ReaderScreen(bookId: restored.id),
          ),
        );
      } on ImportCancelled {
        return;
      } on EpubImportException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
        }
      }
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReaderScreen(bookId: book.id),
      ),
    );
    ref.read(booksProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider);
    final query = ref.watch(librarySearchQueryProvider).trim().toLowerCase();
    final continueBook = ref.watch(continueReadingProvider);

    return Scaffold(
      body: booksAsync.when(
        data: (books) {
          final filtered = query.isEmpty
              ? books
              : books
                  .where(
                    (b) =>
                        b.title.toLowerCase().contains(query) ||
                        b.author.toLowerCase().contains(query),
                  )
                  .toList();

          if (books.isEmpty) {
            return EmptyState(
              icon: Icons.menu_book_outlined,
              title: 'Henüz kitap yok',
              message:
                  'Hazır EPUB dosyalarınızı ekleyerek kişisel kütüphanenizi oluşturun.',
              actionLabel: 'Kitap Ekle',
              onAction: _importing ? null : _import,
            );
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: SearchBar(
                    hintText: 'Başlık veya yazar ara',
                    leading: const Icon(Icons.search),
                    trailing: [
                      if (query.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            ref.read(librarySearchQueryProvider.notifier).state =
                                '';
                          },
                        ),
                      IconButton(
                        tooltip: _grid ? 'Liste' : 'Izgara',
                        icon: Icon(_grid ? Icons.view_list : Icons.grid_view),
                        onPressed: () => setState(() => _grid = !_grid),
                      ),
                    ],
                    onChanged: (value) {
                      ref.read(librarySearchQueryProvider.notifier).state =
                          value;
                    },
                  ),
                ),
              ),
              if (continueBook != null && query.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _openBook(continueBook),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              BookCover(
                                book: continueBook,
                                width: 48,
                                height: 68,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Devam et',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                    ),
                                    Text(
                                      continueBook.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    ProgressChip(
                                      percent: continueBook.progressPercent,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (filtered.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.search_off,
                    title: 'Sonuç yok',
                    message: 'Aramanızla eşleşen kitap bulunamadı.',
                  ),
                )
              else if (_grid)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.55,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final book = filtered[index];
                        return _BookGridTile(
                          book: book,
                          onTap: () => _openBook(book),
                          onDelete: () => _confirmDelete(book),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  sliver: SliverList.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final book = filtered[index];
                      final missing = !File(book.filePath).existsSync();
                      return ListTile(
                        leading: BookCover(
                          book: book,
                          width: 44,
                          height: 60,
                        ),
                        title: Text(book.title),
                        subtitle: Text(
                          missing
                              ? '${book.author} · Dosya bulunamadı'
                              : book.author,
                        ),
                        trailing: ProgressChip(percent: book.progressPercent),
                        onTap: () => _openBook(book),
                        onLongPress: () => _confirmDelete(book),
                      );
                    },
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Kitaplık yüklenemedi: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _importing ? null : _import,
        icon: _importing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add),
        label: Text(_importing ? 'Ekleniyor…' : 'Kitap Ekle'),
      ),
    );
  }
}

class _BookGridTile extends StatelessWidget {
  const _BookGridTile({
    required this.book,
    required this.onTap,
    required this.onDelete,
  });

  final Book book;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final missing = !File(book.filePath).existsSync();
    return InkWell(
      onTap: onTap,
      onLongPress: onDelete,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: BookCover(book: book, width: 120, height: 170),
                ),
                if (missing)
                  const ColoredBox(
                    color: Color(0x88000000),
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          ProgressChip(percent: book.progressPercent),
        ],
      ),
    );
  }
}
