import '../models/book.dart';

/// Kitaplık CRUD — Faz 1'de Hive box ile doldurulacak.
class LibraryService {
  Future<List<Book>> getBooks() async {
    return const [];
  }

  Future<void> addBook(Book book) async {
    throw UnimplementedError(
      'LibraryService.addBook Faz 1 kapsamında uygulanacak.',
    );
  }

  Future<void> deleteBook(String id) async {
    throw UnimplementedError(
      'LibraryService.deleteBook Faz 1 kapsamında uygulanacak.',
    );
  }

  Future<Book?> getBook(String id) async {
    return null;
  }
}
