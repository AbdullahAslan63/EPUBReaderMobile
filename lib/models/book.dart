class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.filePath,
    this.coverImagePath,
    required this.addedAt,
    this.lastOpenedAt,
    this.lastCfi,
    this.progressPercent = 0,
  });

  final String id;
  final String title;
  final String author;
  final String filePath;
  final String? coverImagePath;
  final DateTime addedAt;
  final DateTime? lastOpenedAt;
  final String? lastCfi;
  final double progressPercent;

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? filePath,
    String? coverImagePath,
    DateTime? addedAt,
    DateTime? lastOpenedAt,
    String? lastCfi,
    double? progressPercent,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      filePath: filePath ?? this.filePath,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      addedAt: addedAt ?? this.addedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      lastCfi: lastCfi ?? this.lastCfi,
      progressPercent: progressPercent ?? this.progressPercent,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'filePath': filePath,
      'coverImagePath': coverImagePath,
      'addedAt': addedAt.toIso8601String(),
      'lastOpenedAt': lastOpenedAt?.toIso8601String(),
      'lastCfi': lastCfi,
      'progressPercent': progressPercent,
    };
  }

  factory Book.fromMap(Map<dynamic, dynamic> map) {
    return Book(
      id: map['id'] as String,
      title: map['title'] as String,
      author: map['author'] as String,
      filePath: map['filePath'] as String,
      coverImagePath: map['coverImagePath'] as String?,
      addedAt: DateTime.parse(map['addedAt'] as String),
      lastOpenedAt: map['lastOpenedAt'] != null
          ? DateTime.parse(map['lastOpenedAt'] as String)
          : null,
      lastCfi: map['lastCfi'] as String?,
      progressPercent: (map['progressPercent'] as num?)?.toDouble() ?? 0,
    );
  }
}
