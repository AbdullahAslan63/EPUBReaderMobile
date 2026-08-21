import '../models/reading_progress.dart';

/// CFI ilerlemesi — debounce'lu yazım Faz 1'de eklenecek.
class ReadingProgressService {
  Future<void> saveProgress(ReadingProgress progress) async {
    throw UnimplementedError(
      'ReadingProgressService.saveProgress Faz 1 kapsamında uygulanacak.',
    );
  }

  Future<ReadingProgress?> getProgress(String bookId) async {
    return null;
  }
}
