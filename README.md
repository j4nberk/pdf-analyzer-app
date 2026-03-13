# StudySmart

Gemini API ile desteklenen cross-platform Flutter uygulaması. Yüklediğiniz slaytlar ve PDF belgelerini, geçmiş sınav sorularınıza göre analiz ederek önemli noktalar, hızlı tekrar tabloları, çalışma soruları ve flaşkartlar üretir.

## Özellikler

| Özellik | Açıklama |
|---|---|
| 📄 **PDF Yükleme** | Sınav soruları ve çalışma materyali PDF'lerini yükleyin |
| ⭐ **Önemli Noktalar** | Sınavda çıkması muhtemel 15 kritik nokta |
| 📋 **Hızlı Tekrar Tablosu** | Kavram → Açıklama formatında özet tablo |
| ❓ **Çalışma Soruları** | Materyale dayalı 10 düşündürücü soru |
| 🃏 **Flaşkartlar** | Dokunarak çevirilen etkileşimli soru/cevap kartları |
| 🔗 **Paylaşım** | Analiz sonuçlarını panoya kopyalayın |

## Gereksinimler

- **Flutter SDK 3.35+** — [flutter.dev](https://flutter.dev/docs/get-started/install) adresinden indirin
- **Dart SDK 3.9+**
- **Android Studio** veya **VS Code** (Flutter eklentisi ile)
- **Google Gemini API anahtarı** — [aistudio.google.com](https://aistudio.google.com) adresinden ücretsiz alabilirsiniz

## Kurulum

### 1. Repoyu Klonlayın

```bash
git clone https://github.com/j4nberk/StudySmart.git
cd StudySmart/flutter_app
```

### 2. Bağımlılıkları Yükleyin

```bash
flutter pub get
```

### 3. Uygulamayı Çalıştırın

```bash
# Bağlı cihaz veya emülatörde çalıştırın
flutter run
```

### 4. API Anahtarı Ekleyin

Uygulama açıldıktan sonra sağ üstteki ⚙️ **Ayarlar** simgesine dokunun ve Gemini API anahtarınızı girin.

## Kullanım

1. **Ayarlar**'dan Gemini API anahtarınızı girin (yalnızca ilk kullanımda gereklidir)
2. **Geçmiş Sınav Soruları** bölümüne sınav soruları PDF'inizi yükleyin
3. **Çalışma Materyalleri** bölümüne ders notları, slaytlar vb. PDF'leri ekleyin (birden fazla eklenebilir)
4. **Analiz Et** butonuna dokunun
5. Sonuçlara dört farklı sekmeden ulaşın:
   - **Önemli Noktalar** — Madde madde kritik bilgiler
   - **Tekrar Tablosu** — Kavram → Açıklama özet tablosu (arama destekli)
   - **Çalışma Soruları** — Sınav tarzı sorular
   - **Flaşkartlar** — Sola/sağa kaydırarak geçin, karta dokunarak çevirin

## Proje Yapısı

```
flutter_app/
├── lib/
│   ├── main.dart                     # Uygulama giriş noktası
│   ├── models/
│   │   ├── analysis_result.dart      # Analiz sonuç modeli (JSON kodlanabilir)
│   │   ├── app_error.dart            # Özel hata türleri
│   │   └── document.dart             # Belge modeli
│   ├── services/
│   │   ├── gemini_service.dart       # Gemini REST API istemcisi
│   │   └── pdf_service.dart          # PDF metin ayıklayıcı (syncfusion_flutter_pdf)
│   ├── theme/
│   │   └── study_smart_theme.dart    # Uygulama teması ve renk paleti
│   ├── viewmodels/
│   │   └── app_view_model.dart       # Merkezi durum yöneticisi (ChangeNotifier)
│   └── views/
│       ├── analysis_view.dart        # Sekmeli sonuç ekranı
│       ├── content_view.dart         # Ana ekran
│       ├── document_upload_view.dart # Belge yükleme ekranı
│       ├── empty_result_view.dart    # Boş durum görünümü
│       ├── flashcards_view.dart      # Etkileşimli flaşkart ekranı
│       ├── key_points_view.dart      # Önemli noktalar listesi
│       ├── review_table_view.dart    # Hızlı tekrar tablosu
│       ├── settings_view.dart        # API anahtarı ve model ayarları
│       └── study_questions_view.dart # Çalışma soruları listesi
└── test/
    └── pdf_analyzer_test.dart        # Birim testleri
```

## Kullanılan Paketler

| Paket | Sürüm | Açıklama |
|---|---|---|
| `provider` | ^6.1.2 | State management |
| `file_picker` | ^8.1.7 | Cross-platform dosya seçici |
| `shared_preferences` | ^2.3.4 | Kalıcı anahtar-değer depolama |
| `http` | ^1.2.2 | Gemini REST API için HTTP istemcisi |
| `syncfusion_flutter_pdf` | ^27.1.58 | PDF metin ayıklama (iOS & Android) |
| `url_launcher` | ^6.3.2 | Harici URL'leri tarayıcıda açma |

## Kullanılan Model Seçenekleri

| Model | Hız | Kalite | Kullanım |
|---|---|---|---|
| `gemini-2.0-flash` | ⚡ Hızlı | ✅ Yüksek | Varsayılan — çoğu belge için ideal |
| `gemini-2.0-flash-lite` | ⚡ En Hızlı | ✅ İyi | Hız öncelikli kullanım |
| `gemini-1.5-flash` | ⚡ Hızlı | ✅ İyi | Dengeli seçenek |
| `gemini-1.5-pro` | 🐢 Yavaş | 🏆 En yüksek | Karmaşık belgeler için |

## Güvenlik

- API anahtarı `SharedPreferences` içinde saklanır (geliştirme ortamı içindir).
- Üretim uygulamaları için API anahtarını güvenli bir depolama alanında veya arka uç proxy üzerinden yönetin.
- PDF metni yalnızca Gemini API'ye iletilir; başka bir sunucuya gönderilmez.

## Testler

```bash
cd flutter_app
dart test test/pdf_analyzer_test.dart
```

Testler; model kodlama/çözme, hata mesajları ve API yanıt ayrıştırma mantığını kapsar.

## Lisans

MIT
