import 'package:flutter_riverpod/flutter_riverpod.dart';

final navigationIndexProvider = StateProvider<int>((ref) => 0);

final librarySearchQueryProvider = StateProvider<String>((ref) => '');
