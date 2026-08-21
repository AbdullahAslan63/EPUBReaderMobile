class Bookmark {
  const Bookmark({
    required this.id,
    required this.bookId,
    required this.cfi,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String bookId;
  final String cfi;
  final String? note;
  final DateTime createdAt;

  Bookmark copyWith({
    String? id,
    String? bookId,
    String? cfi,
    String? note,
    DateTime? createdAt,
  }) {
    return Bookmark(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      cfi: cfi ?? this.cfi,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'cfi': cfi,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Bookmark.fromMap(Map<dynamic, dynamic> map) {
    return Bookmark(
      id: map['id'] as String,
      bookId: map['bookId'] as String,
      cfi: map['cfi'] as String,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
