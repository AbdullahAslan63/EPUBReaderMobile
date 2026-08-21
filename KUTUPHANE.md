# KUTUPHANE.md — Proje Planı

## 1. Vizyon

Risale-i Nur Kütüphanesi tarzı esnek, konforlu bir okuma deneyimi sunan; ama herhangi
bir EPUB kitabı kabul eden kişisel kütüphane uygulaması. Kullanıcı kendi EPUB
dosyalarını yükler; uygulama onları koyu tema, ayarlanabilir metin boyutu, kaldığın
yerden devam etme ve işaretlerle sunar.

Kapsam dışı (bilinçli karar): PDF desteği, sunucu taraflı dönüştürme, OCR. Kullanıcı
elinde EPUB yoksa uygulama dışında (Calibre vb.) dönüştürüp öyle yükler.

**Lugat / kelime anlamı** v1 kapsamında değildir. İleride ayrı bir sürümde
değerlendirilebilir; bu faza kadar sözlük, `onTextSelected` akışı veya Dictionary
servisi eklenmez.

## 2. Kimlik ve platformlar

| Alan | Karar |
|------|--------|
| Görünen ad | EPUB Kütüphanesi |
| Uygulama kimliği (çalışma adı) | epub_kutuphanesi |
| Android / uygulama kimliği | `com.epubkutuphanesi.app` |
| UI dili (v1) | Türkçe |
| Kod tabanı | Flutter (stable), tek repo |

Hedef platformlar:

- Android, iOS (telefon)
- Windows, Linux (masaüstü)
- Masaüstü webview davranışı mobilden farklı olabilir — risk kabul edilir; okuma
  özellikleri Android + (Windows veya Linux) + mümkünse iOS’ta manuel smoke test edilir.

## 3. Sabit teknik kararlar

| Konu | Karar |
|------|--------|
| State management | **Riverpod** |
| Yerel veritabanı | **Hive** |
| EPUB render | `flutter_epub_viewer` |
| Metadata | `epubx` |
| Dosya seçimi / yollar | `file_picker` + `path_provider` |
| Lint | `analysis_options.yaml` — AidatPanel ile uyumlu flutter_lints / strict kurallar |

Bu tablodaki seçimler v1 boyunca değiştirilmez; alternatif paket önermek veya sessizce
swap etmek yasaktır (bkz. AGENTS.md).

## 4. v1 özellik listesi

### 4.1 Kitaplık
- [ ] "Kitap Ekle" → `file_picker` ile `.epub` seçimi
- [ ] Seçilen dosyanın uygulama belge klasörüne kopyalanması (orijinal taşınmaz/silinmez)
- [ ] `epubx` ile metadata: başlık, yazar, kapak görseli
- [ ] Kapak yoksa / metadata eksikse anlamlı placeholder (dosya adı veya “Bilinmeyen”)
- [ ] Kitaplık: kapak görselli grid/liste
- [ ] Kitap silme (kopyalanmış dosya + Hive kaydı)
- [ ] Başlığa göre arama/filtreleme

### 4.2 Okuma ekranı
- [ ] `flutter_epub_viewer` entegrasyonu
- [ ] Metin boyutu (pinch + ayarlar menüsü)
- [ ] Koyu / açık / sepya okuma teması
- [ ] Paginated vs. kaydırmalı mod tercihi
- [ ] TOC paneli, bölüme atlama

### 4.3 Kaldığın yerden devam etme
- [ ] `onRelocated` → CFI kaydı (debounce; her scroll event’inde yazma)
- [ ] Kitaplıkta `% tamamlandı`
- [ ] Açılışta son okunan kitaba hızlı erişim

### 4.4 İşaretler (bookmark)
- [ ] CFI bazlı işaret ekleme
- [ ] Opsiyonel not
- [ ] İşaretler listesi → tıklanınca ilgili CFI’ye gitme

### 4.5 Ayarlar
- [ ] Uygulama teması (sistem / koyu / açık)
- [ ] Varsayılan okuma teması ve font boyutu
- [ ] Yazı tipi seçimi → v1.1’e ertelenebilir

## 5. Veri modeli

```
Book
- id
- title
- author
- filePath           // kopyalanan epub’un yerel yolu
- coverImagePath     // nullable; yoksa UI placeholder
- addedAt
- lastOpenedAt
- lastCfi            // kaldığın yer (CFI)
- progressPercent

Bookmark
- id
- bookId
- cfi
- note (opsiyonel)
- createdAt
```

Okuma konumu ve işaretler için **CFI tek doğruluk kaynağıdır**; sayfa numarasına
güvenilmez.

## 6. Hata ve kenar durumları (v1’de ele alınacak)

| Durum | Beklenen davranış |
|-------|-------------------|
| Kullanıcı seçimi iptal | Sessizce çık; hata gösterme |
| Bozuk / geçersiz EPUB | Snackbar/dialog; kütüphaneye yarım kayıt bırakma |
| Metadata veya kapak yok | Placeholder ile eklemeye devam |
| Dosya kopyalama / disk hatası | Kullanıcıya net mesaj; DB’ye yazma |
| İzin reddi (platform) | Neden gerektiğini söyleyen mesaj |
| Kayıtlı dosya sonradan silinmiş | Kitaplıkta “dosya bulunamadı”; yeniden ekleme yolu |

## 7. Non-functional (v1 hedefleri)

- Tamamen **offline**; ağ zorunluluğu yok.
- İlerleme kaydı UI’yi kilitlemez (debounce’lu arka plan yazımı).
- Büyük EPUB’larda ilk açılış yavaş olabilir; crash / ANR olmamalı.
- Uygulama genel `ThemeMode` ile epub `displaySettings` senkron tutulur.

## 8. Fazlandırma / yol haritası

**Faz 1 — Çekirdek (MVP)**  
Kitap ekleme, kitaplık, temel okuma (font + tema), kaldığın yerden devam (CFI).

**Faz 2 — Konfor**  
İşaretler, TOC, kitaplık içi arama.

**Faz 3 — Cilalama**  
Ayarlar genişletme, animasyonlar, boş durum ekranları, mağaza görselleri.

**Faz 4 — Senkronizasyon (v2, planlanan / v1 dışı)**  
Node/Express/Prisma/PostgreSQL + Firebase Auth; epub + ilerleme + işaretler.
AidatPanel backend deseni. Şart: v1 offline davranışı stabil.

**İleride (ayrı sürüm, şu an kapsam dışı)**  
Lugat / kelime anlamı (`onTextSelected`, cihaz içi veya sunucu sözlük). Lisans ve
veri kaynağı o sürümde ayrıca kararlaştırılır.

## 9. MVP kabul kriterleri (Faz 1 “bitti” tanımı)

Aşağıdakilerin **hepsi** sağlanmadan Faz 1 tamamlanmış sayılmaz:

1. `.epub` seçilip uygulama klasörüne kopyalanır; orijinal dosya yerinde kalır.
2. Kitaplıkta başlık/yazar (veya placeholder) ve kapak/placeholder görünür.
3. Kitap açılır; font boyutu ve okuma teması değişir.
4. Uygulama kill edilip yeniden açılınca aynı kitap **aynı CFI** konumunda açılır.
5. Bozuk EPUB eklenmeye çalışılınca kullanıcı uyarılır; yarım/bozuk kütüphane kaydı kalmaz.
6. Smoke: en az **Android** ve **Windows veya Linux** üzerinde 1–4 doğrulanır.

## 10. Bilinçli ertelemeler

- Yazı tipi seçimi → v1.1 adayı
- Lugat → ilerideki sürüm
- PDF / OCR / sunucu dönüştürme → ürün vizyonu dışı (veya çok sonraki faz)
- Çoklu cihaz sync → Faz 4 (v2)
