/// Okuma ilerlemesi anlık durumu (CFI tek doğruluk kaynağı).
class ReadingProgress {
  const ReadingProgress({
    required this.bookId,
    required this.cfi,
    required this.percent,
    required this.updatedAt,
  });

  final String bookId;
  final String cfi;
  final double percent;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'cfi': cfi,
      'percent': percent,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ReadingProgress.fromMap(Map<dynamic, dynamic> map) {
    return ReadingProgress(
      bookId: map['bookId'] as String,
      cfi: map['cfi'] as String,
      percent: (map['percent'] as num).toDouble(),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
