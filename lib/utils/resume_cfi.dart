/// Okuma açılış CFI’si — progress box tek doğruluk kaynağı, Book aynası yedek.
String? resolveResumeCfi({
  required String? progressCfi,
  required String? bookLastCfi,
}) {
  if (progressCfi != null && progressCfi.isNotEmpty) return progressCfi;
  if (bookLastCfi != null && bookLastCfi.isNotEmpty) return bookLastCfi;
  return null;
}
