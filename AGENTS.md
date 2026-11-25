# AGENTS.md — EPUB Kütüphanesi

Bu dosya, bu proje üzerinde çalışan AI ajanları (Cursor, Claude Code vb.) için kurallardır.
Özellik planı, kabul kriterleri ve fazlar için **KUTUPHANE.md** tek kaynaktır.

## Proje özeti

Flutter ile geliştirilen, çoklu platform (Android, iOS, Windows, Linux) kişisel EPUB
okuyucu. Hazır `.epub` çevrimdışı eklenir. PDF seçilirse `converter/` servisi OCR
yapıp EPUB döner; okuma yine yalnızca EPUB ve CFI ile, çevrimdışıdır.

- **Görünen ad:** EPUB Kütüphanesi  
- **Paket / applicationId:** `com.epubkutuphanesi.app`  
- **UI dili (v1):** Türkçe  

## Teknoloji yığını (kilitli)

- **Framework:** Flutter (stable), Dart null-safety
- **State management:** Riverpod
- **Yerel veritabanı:** Hive
- **EPUB render:** `flutter_epub_viewer` (epub.js + flutter_inappwebview)
- **Metadata:** `epubx`
- **Dosya:** `file_picker` + `path_provider`
- **Lint:** AidatPanel ile uyumlu `analysis_options.yaml` (flutter_lints / strict)
- **PDF dönüşümü:** `converter/` — Express, disk kuyruğu, ocrmypdf, Calibre.
  Adres `lib/config/converter_config.dart` içinde sabit; kullanıcıdan istenmez.
  Faz 4 senkronu değildir.
- **v2 (ileride, kodlama):** Node.js/Express/Prisma/PostgreSQL + Firebase Auth
  (AidatPanel deseni) — v1’e sync veya Firebase eklenmez

Bu listedeki seçimleri değiştirmeyin; “daha iyi paket” diye Hive↔Drift veya
Riverpod↔Provider swap önermeyin.

## Kesin kurallar

1. **Okuma yalnızca EPUB.** PDF yüklenince `converter/` (OCR + Calibre) EPUB üretir.
   Uygulama içi PDF render paketi eklemeyin. Faz 4 sync / Firebase Auth eklemeyin.
2. **Orijinal dosyayı taşımayın/silmeyin.** Seçilen dosya uygulama belge klasörüne
   **kopyalanır**. Orijinal silinse bile kütüphane kopyası kalmalı. PDF kopyası,
   EPUB indirilip metadata yazılınca silinebilir.
3. **CFI tek doğruluk kaynağıdır** (ilerleme + işaretler). Sayfa numarasına güvenmeyin.
   `onRelocated` kayıtları **debounce** edilir; her scroll’da Hive yazılmaz.
4. **Lugat / kelime anlamı YOK (v1).** `onTextSelected`, DictionaryService, sözlük
   paketi veya anlam popup’ı eklemeyin. İlerideki sürümde KUTUPHANE.md güncellenmeden
   bu özellik açılmaz.
5. **Masaüstü ≠ mobil.** Webview farkları beklenir. Yeni okuma özelliğinde smoke test:
   Android + (Windows veya Linux); mümkünse iOS.
6. **Çift tema:** Uygulama `ThemeMode` ile epub `displaySettings` ayrı ama senkron
   yönetilir.
7. **Import hata yolu:** Bozuk EPUB / kopyalama hatası → kullanıcıya Türkçe mesaj;
   yarım Hive kaydı veya yetim dosya bırakmayın. Kapak/metadata yoksa placeholder ile
   devam edin. PDF’te sunucu yoksa kayıt açmayın. Dönüşüm hatasında kayıt `failed`
   kalır, yerel PDF durur, yarım EPUB ve yetim kapak silinir.

## Kod stili ve mimari

- Widget’lar küçük ve tek sorumluluklu; okuma iş mantığı `ReaderController` / servis
  katmanında, widget içinde değil.
- UI string’leri v1’de Türkçe.
- Commit yalnızca kullanıcı istediğinde; gizli dosya / `.env` commit edilmez.

## Test beklentisi

- Servis katmanı (import, ilerleme yazma, silme) için unit test yazılabilir olduğunda yazın.
- Faz 1 bitişi için KUTUPHANE.md §9 kabul kriterleri zorunludur; “kod derleniyor”
  yeterli değildir.
- Manuel smoke: en az bir geçerli EPUB ile ekle → oku → kill → aynı CFI; bir bozuk
  dosya ile hata mesajı.

## Klasör yapısı

```
lib/
  models/         # Book, Bookmark, ReadingProgress
  services/       # EpubImportService, LibraryService, PdfConversionService, ReadingProgressService
converter/        # PDF → EPUB (OCR + Calibre). Faz 4 senkronu değil.
  screens/
    library/      # Kitaplık
    reader/       # Okuma
    bookmarks/    # İşaretler
    settings/     # Ayarlar
  widgets/
  theme/
```

## Yapılmaması gerekenler

- PDF render paketleri (pdfx, Syncfusion vb.)
- Lugat / sözlük / `onTextSelected` anlam akışı
- Faz 4 sync, Firebase Auth veya EPUB’u PDF olarak ekranda açmak
- `localStorage` / tarayıcı depolama API’leri (Flutter native; konu dışı)
- KUTUPHANE.md’deki faz sırasını atlayarak v2 sync veya lugat iskeleti
