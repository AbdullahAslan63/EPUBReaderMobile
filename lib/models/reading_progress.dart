/// Okuma ilerlemesi anlık durumu (CFI tek doğruluk kaynağı).
class ReadingProgress {
  const ReadingProgress({
    required this.bookId,
    required this.cfi,
    required this.percent,
    required this.updatedAt,
    this.locationsJson,
  });

  final String bookId;
  final String cfi;
  final double percent;
  final DateTime updatedAt;

  /// `onLocationsGenerated` çıktısı — sonraki açılışta progress anında hazır.
  final String? locationsJson;

  ReadingProgress copyWith({
    String? bookId,
    String? cfi,
    double? percent,
    DateTime? updatedAt,
    String? locationsJson,
  }) {
    return ReadingProgress(
      bookId: bookId ?? this.bookId,
      cfi: cfi ?? this.cfi,
      percent: percent ?? this.percent,
      updatedAt: updatedAt ?? this.updatedAt,
      locationsJson: locationsJson ?? this.locationsJson,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'cfi': cfi,
      'percent': percent,
      'updatedAt': updatedAt.toIso8601String(),
      'locationsJson': locationsJson,
    };
  }

  factory ReadingProgress.fromMap(Map<dynamic, dynamic> map) {
    return ReadingProgress(
      bookId: map['bookId'] as String,
      cfi: map['cfi'] as String,
      percent: (map['percent'] as num).toDouble(),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      locationsJson: map['locationsJson'] as String?,
    );
  }
}
