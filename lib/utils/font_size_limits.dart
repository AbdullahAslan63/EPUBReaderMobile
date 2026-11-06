/// Erişilebilir yazı boyutu aralığı (görme güçlüğü için yüksek tavan).
abstract final class FontSizeLimits {
  static const double min = 12;
  static const double max = 64;
  static const int divisions = 26; // 2’şer adım: 12…64

  static double clamp(double size) => size.clamp(min, max).toDouble();
}
