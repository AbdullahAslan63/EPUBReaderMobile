import 'package:flutter/material.dart';

/// Okuyucu kabuğu — `flutter_epub_viewer` entegrasyonu Faz 1'de.
class ReaderScreen extends StatelessWidget {
  const ReaderScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Okuma')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Okuyucu henüz bağlanmadı.\nKitap: $bookId',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
