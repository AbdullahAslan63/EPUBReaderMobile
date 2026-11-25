enum ConversionStatus { ready, converting, failed }

const _unset = Object();

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
    this.conversionStatus = ConversionStatus.ready,
    this.conversionJobId,
    this.localSourcePath,
    this.conversionError,
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
  final ConversionStatus conversionStatus;
  final String? conversionJobId;
  final String? localSourcePath;
  final String? conversionError;

  bool get isConverting => conversionStatus == ConversionStatus.converting;

  bool get isReady =>
      conversionStatus == ConversionStatus.ready && filePath.isNotEmpty;

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
    ConversionStatus? conversionStatus,
    Object? conversionJobId = _unset,
    Object? localSourcePath = _unset,
    Object? conversionError = _unset,
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
      conversionStatus: conversionStatus ?? this.conversionStatus,
      conversionJobId: conversionJobId == _unset
          ? this.conversionJobId
          : conversionJobId as String?,
      localSourcePath: localSourcePath == _unset
          ? this.localSourcePath
          : localSourcePath as String?,
      conversionError: conversionError == _unset
          ? this.conversionError
          : conversionError as String?,
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
      'conversionStatus': conversionStatus.name,
      'conversionJobId': conversionJobId,
      'localSourcePath': localSourcePath,
      'conversionError': conversionError,
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
      conversionStatus: _statusFromName(map['conversionStatus']),
      conversionJobId: map['conversionJobId'] as String?,
      localSourcePath: map['localSourcePath'] as String?,
      conversionError: map['conversionError'] as String?,
    );
  }

  static ConversionStatus _statusFromName(Object? raw) {
    for (final status in ConversionStatus.values) {
      if (status.name == raw) return status;
    }
    return ConversionStatus.ready;
  }
}
