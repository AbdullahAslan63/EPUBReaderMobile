import 'package:flutter/material.dart';

/// Sakin utility + hafif mürekkep/kâğıt yüzeyi.
abstract final class AppTokens {
  static const radius = 8.0;
  static const dockHeight = 64.0;
  static const chromeAnim = Duration(milliseconds: 220);

  static const paper = Color(0xFFF4F2ED);
  static const paperRaised = Color(0xFFEBE7E0);
  static const ink = Color(0xFF161513);
  static const inkMuted = Color(0xFF5E5A54);
  static const hairline = Color(0xFFD5D0C7);

  static const surfaceInk = Color(0xFF111110);
  static const surfaceInkRaised = Color(0xFF1C1C1A);
  static const inkSoft = Color(0xFFE6E1D8);
  static const inkSoftMuted = Color(0xFFA9A49B);
  static const hairlineDark = Color(0xFF2E2E2B);

  static const accent = Color(0xFF2C3338);
  static const accentOnDark = Color(0xFFD9D3C8);
}
