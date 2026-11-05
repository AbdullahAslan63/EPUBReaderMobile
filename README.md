# EPUB Kütüphanesi

Kişisel, tamamen çevrimdışı EPUB okuyucu (Flutter). Hazır `.epub` dosyalarını
kitaplığa ekleyip koyu/açık/sepya tema, font boyutu, CFI ile kaldığın yerden
devam ve işaretlerle okursunuz.

- **Paket / applicationId:** `com.epubkutuphanesi.app`
- **UI dili (v1):** Türkçe
- **Stack:** Riverpod, Hive, `flutter_epub_viewer`, `epubx`

Özellik planı ve kabul kriterleri: [KUTUPHANE.md](KUTUPHANE.md).  
AI ajan kuralları: [AGENTS.md](AGENTS.md).

## Çalıştırma

```bash
flutter pub get
flutter run -d android   # önerilen smoke hedefi
# flutter run -d macos   # okuyucu desteklenir
# flutter run -d linux   # kütüphane UI; okuyucu paket matrisi dışı olabilir
```

## v1 durum

Faz 1–3 uygulandı (MVP, TOC/işaretler/arama, ayarlar + polish).

**Hariç / ertelenen:** sunucu sync, lugat, PDF/OCR, yazı tipi seçimi (v1.1).

## Smoke (Faz 1)

1. Geçerli EPUB ekle → kitaplıkta görünür  
2. Oku → font/tema değiştir  
3. Uygulamayı öldür → aynı CFI  
4. Bozuk dosya → Türkçe hata, yarım kayıt yok  

Okuyucu smoke: **Android** zorunlu; iOS/macOS mümkünse. Windows/Linux’ta
`flutter_epub_viewer` resmi olarak desteklenmez.
