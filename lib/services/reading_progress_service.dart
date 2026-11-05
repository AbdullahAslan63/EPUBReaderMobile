import 'package:hive/hive.dart';

import '../models/reading_progress.dart';
import 'hive_boxes.dart';

/// CFI ilerlemesi — debounce UI/controller katmanında yapılır.
class ReadingProgressService {
  ReadingProgressService({Box<Map>? progressBox})
      : _progress = progressBox ?? HiveBoxes.progressBox;

  final Box<Map> _progress;

  Future<void> saveProgress(ReadingProgress progress) async {
    final existing = await getProgress(progress.bookId);
    final merged = progress.copyWith(
      locationsJson: progress.locationsJson ?? existing?.locationsJson,
    );
    await _progress.put(progress.bookId, merged.toMap());
  }

  Future<ReadingProgress?> getProgress(String bookId) async {
    final raw = _progress.get(bookId);
    if (raw == null) return null;
    return ReadingProgress.fromMap(Map<dynamic, dynamic>.from(raw));
  }

  Future<void> saveLocations(String bookId, String locationsJson) async {
    final existing = await getProgress(bookId);
    if (existing == null) {
      await _progress.put(
        bookId,
        ReadingProgress(
          bookId: bookId,
          cfi: '',
          percent: 0,
          updatedAt: DateTime.now(),
          locationsJson: locationsJson,
        ).toMap(),
      );
      return;
    }
    await _progress.put(
      bookId,
      existing.copyWith(locationsJson: locationsJson).toMap(),
    );
  }

  Future<String?> getLocations(String bookId) async {
    return (await getProgress(bookId))?.locationsJson;
  }
}
