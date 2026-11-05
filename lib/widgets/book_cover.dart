import 'dart:io';

import 'package:flutter/material.dart';

import '../models/book.dart';

class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.book,
    this.width = 72,
    this.height = 100,
  });

  final Book book;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final path = book.coverImagePath;
    final hasFile = path != null && File(path).existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: width,
        height: height,
        child: hasFile
            ? Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, error, stackTrace) => _Placeholder(
                  title: book.title,
                  scheme: scheme,
                ),
              )
            : _Placeholder(title: book.title, scheme: scheme),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.title, required this.scheme});

  final String title;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final letter = title.trim().isEmpty ? '?' : title.trim()[0].toUpperCase();
    return ColoredBox(
      color: scheme.secondaryContainer,
      child: Center(
        child: Text(
          letter,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
        ),
      ),
    );
  }
}
