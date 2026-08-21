import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book.dart';
import '../services/library_service.dart';

final libraryServiceProvider = Provider<LibraryService>((ref) {
  return LibraryService();
});

/// Kitaplık listesi — Faz 1'de Hive'dan doldurulacak; iskelette boş liste.
final booksProvider = FutureProvider<List<Book>>((ref) async {
  return ref.watch(libraryServiceProvider).getBooks();
});
