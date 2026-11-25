import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/book.dart';
import '../../providers/library_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../services/epub_import_service.dart';
import '../../widgets/app_page_header.dart';
import '../../widgets/book_cover.dart';
import '../../widgets/confirm_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/progress_chip.dart';
import '../../widgets/quiet_search_field.dart';
import '../reader/reader_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  var _importing = false;
  var _grid = true;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    setState(() => _importing = true);
    try {
      final book = await ref.read(booksProvider.notifier).importBook();
      if (mounted) {
        final message = book.isConverting
            ? 'PDF eklendi. Dönüşüm arka planda sürüyor.'
            : 'Kitap eklendi';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } on ImportCancelled {
      // sessiz
    } on EpubImportException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Kitap eklenemedi: $e')));
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _confirmDelete(Book book) async {
    final ok = await showConfirmSheet(
      context: context,
      title: 'Kitabı sil',
      message: '“${book.title}” kütüphaneden silinsin mi?',
      confirmLabel: 'Sil',
      destructive: true,
    );
    if (ok) {
      await ref.read(booksProvider.notifier).deleteBook(book.id);
    }
  }

  Future<void> _openBook(Book book) async {
    if (book.isConverting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bu kitap henüz hazır değil. Dönüşüm bitince açabilirsiniz.',
          ),
        ),
      );
      return;
    }
    if (book.conversionStatus == ConversionStatus.failed) {
      try {
        await ref.read(booksProvider.notifier).retryConversion(book);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dönüşüm yeniden başlatıldı.')),
          );
        }
      } on EpubImportException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
      return;
    }

    final missing = book.filePath.isEmpty || !File(book.filePath).existsSync();
    if (missing) {
      final reimport = await showConfirmSheet(
        context: context,
        title: 'Dosya bulunamadı',
        message:
            'Bu kitabın EPUB dosyası cihazdan silinmiş görünüyor. Yeniden eklemek ister misiniz?',
        confirmLabel: 'Yeniden ekle',
      );
      if (!reimport || !mounted) return;
      try {
        final restored = await ref
            .read(booksProvider.notifier)
            .reimportMissingFile(book);
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ReaderScreen(bookId: book.id)),
    );
    ref.read(booksProvider.notifier).refresh();
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(librarySearchQueryProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(conversionNoticeProvider, (previous, next) {
      if (next == null || next.isEmpty) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next)));
      ref.read(conversionNoticeProvider.notifier).state = null;
    });

    final booksAsync = ref.watch(booksProvider);
    final rawQuery = ref.watch(librarySearchQueryProvider);
    final query = rawQuery.trim().toLowerCase();
    final continueBook = ref.watch(continueReadingProvider);
    final books = booksAsync.valueOrNull;
    final hasBooks = books != null && books.isNotEmpty;

    return Column(
      children: [
        AppPageHeader(
          title: 'Kitaplık',
          actions: [
            if (hasBooks)
              IconButton(
                tooltip: _grid ? 'Liste' : 'Izgara',
                onPressed: () => setState(() => _grid = !_grid),
                icon: Icon(_grid ? Icons.view_list : Icons.grid_view),
              ),
            if (_importing)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                tooltip: 'Kitap ekle',
                onPressed: _import,
                icon: const Icon(Icons.add),
              ),
          ],
        ),
        if (hasBooks)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: QuietSearchField(
              controller: _searchController,
              hint: 'Başlık veya yazar ara',
              showClear: rawQuery.isNotEmpty,
              onClear: _clearSearch,
              onChanged: (value) {
                ref.read(librarySearchQueryProvider.notifier).state = value;
              },
            ),
          ),
        Expanded(
          child: booksAsync.when(
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
                      'EPUB veya PDF ekleyerek kütüphanenizi oluşturun. PDF sunucuda EPUB’a dönüşür.',
                  actionLabel: 'Kitap ekle',
                  onAction: _importing ? null : _import,
                );
              }

              return CustomScrollView(
                slivers: [
                  if (continueBook != null && query.isEmpty)
                    SliverToBoxAdapter(
                      child: _ResumeStrip(
                        book: continueBook,
                        onTap: () => _openBook(continueBook),
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
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 14,
                              childAspectRatio: 0.52,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final book = filtered[index];
                          return _BookGridTile(
                            book: book,
                            onTap: () => _openBook(book),
                            onDelete: () => _confirmDelete(book),
                          );
                        }, childCount: filtered.length),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      sliver: SliverList.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        itemBuilder: (context, index) {
                          final book = filtered[index];
                          return _BookListRow(
                            book: book,
                            onTap: () => _openBook(book),
                            onDelete: () => _confirmDelete(book),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text('Kitaplık yüklenemedi: $error')),
          ),
        ),
      ],
    );
  }
}

class _ResumeStrip extends StatelessWidget {
  const _ResumeStrip({required this.book, required this.onTap});

  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
        child: Row(
          children: [
            BookCover(book: book, width: 40, height: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Devam et',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.primary,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ProgressChip(percent: book.progressPercent),
                ],
              ),
            ),
          ],
        ),
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
    final missing =
        book.conversionStatus == ConversionStatus.ready &&
        (book.filePath.isEmpty || !File(book.filePath).existsSync());
    return InkWell(
      onTap: onTap,
      onLongPress: onDelete,
      borderRadius: BorderRadius.circular(4),
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
                if (book.isConverting)
                  const ColoredBox(
                    color: Color(0x88000000),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                else if (book.conversionStatus == ConversionStatus.failed ||
                    missing)
                  ColoredBox(
                    color: const Color(0x88000000),
                    child: Center(
                      child: Icon(
                        book.conversionStatus == ConversionStatus.failed
                            ? Icons.error_outline
                            : Icons.broken_image_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          _BookStatusLine(book: book, missing: missing),
        ],
      ),
    );
  }
}

class _BookListRow extends StatelessWidget {
  const _BookListRow({
    required this.book,
    required this.onTap,
    required this.onDelete,
  });

  final Book book;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final missing =
        book.conversionStatus == ConversionStatus.ready &&
        (book.filePath.isEmpty || !File(book.filePath).existsSync());
    final scheme = Theme.of(context).colorScheme;
    final subtitle = switch (book.conversionStatus) {
      ConversionStatus.converting => 'Dönüştürülüyor',
      ConversionStatus.failed => book.conversionError ?? 'Dönüştürülemedi',
      ConversionStatus.ready =>
        missing ? '${book.author} · Dosya bulunamadı' : book.author,
    };
    final subtitleIsError =
        missing || book.conversionStatus == ConversionStatus.failed;
    return InkWell(
      onTap: onTap,
      onLongPress: onDelete,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            BookCover(book: book, width: 44, height: 60),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: subtitleIsError
                          ? scheme.error
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  if (book.conversionStatus == ConversionStatus.ready) ...[
                    const SizedBox(height: 8),
                    ProgressChip(percent: book.progressPercent),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookStatusLine extends StatelessWidget {
  const _BookStatusLine({required this.book, required this.missing});

  final Book book;
  final bool missing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (book.conversionStatus) {
      case ConversionStatus.converting:
        return Text(
          'Dönüştürülüyor',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        );
      case ConversionStatus.failed:
        return Text(
          'Dönüştürülemedi',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.error),
        );
      case ConversionStatus.ready:
        if (missing) {
          return Text(
            'Dosya bulunamadı',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.error),
          );
        }
        return ProgressChip(percent: book.progressPercent);
    }
  }
}
