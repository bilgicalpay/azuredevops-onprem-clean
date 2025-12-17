# Azure DevOps Server 2022 Mobile App

**Geliştirici:** Alpay Bilgiç  
**Versiyon:** 1.0.0  
**Tarih:** 2025.12.17

## Genel Bakış

Bu uygulama, Azure DevOps Server 2022 on-premise kurulumları için mobil erişim sağlar. Kurumsal MDM (Mobile Device Management) sistemleri ile entegre edilerek güvenli bir şekilde dağıtılabilir.

## Özellikler

- ✅ Work Item görüntüleme ve yönetimi
- ✅ Query çalıştırma ve sonuç görüntüleme
- ✅ Wiki içerik görüntüleme
- ✅ Push notification desteği
- ✅ Personal Access Token (PAT) kimlik doğrulama
- ✅ Active Directory (AD) kimlik doğrulama
- ✅ MDM entegrasyonu
- ✅ Güvenli token saklama (FlutterSecureStorage)
- ✅ Belgeler ekranı (Güvenlik, Altyapı, MDM dokümantasyonları)

## Sistem Gereksinimleri

### Azure DevOps Server
- Azure DevOps Server 2022 veya üzeri
- API Versiyonu: 7.0
- HTTPS erişimi (TLS 1.2+)

### Mobil Cihazlar
- **Android:** Minimum 5.0 (SDK 21), Target 14 (SDK 34)
- **iOS:** Minimum 12.0, Target 17.0

## Kurulum

```bash
# Bağımlılıkları yükle
flutter pub get

# Android APK oluştur
flutter build apk --release

# iOS IPA oluştur
flutter build ipa
```

## Yapılandırma

### Gerekli Ayarlar
- Azure DevOps Server URL'si
- Personal Access Token (PAT) veya AD kimlik bilgileri
- Collection adı (opsiyonel)

### MDM Entegrasyonu
Detaylı bilgi için `docs/MDM_INTEGRATION.md` dosyasına bakın.

## Güvenlik

- Token'lar FlutterSecureStorage'da şifrelenmiş olarak saklanır
- Android: EncryptedSharedPreferences
- iOS: Keychain
- Tüm API çağrıları HTTPS üzerinden yapılır

Detaylı güvenlik bilgileri için `docs/SECURITY.md` dosyasına bakın.

## Dokümantasyon

- `docs/SECURITY.md` - Güvenlik dokümantasyonu
- `docs/INFRASTRUCTURE.md` - Altyapı dokümantasyonu
- `docs/MDM_INTEGRATION.md` - MDM entegrasyon kılavuzu
- `docs/README.md` - Genel dokümantasyon

## Proje Yapısı

```
lib/
├── main.dart                    # Uygulama giriş noktası
├── screens/                     # Ekranlar
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── work_item_detail_screen.dart
│   ├── work_item_list_screen.dart
│   ├── queries_screen.dart
│   ├── settings_screen.dart
│   ├── wiki_viewer_screen.dart
│   └── documents_screen.dart
├── services/                    # Servisler
│   ├── auth_service.dart
│   ├── storage_service.dart
│   ├── work_item_service.dart
│   ├── wiki_service.dart
│   ├── notification_service.dart
│   ├── background_task_service.dart
│   └── realtime_service.dart

assets/
└── images/
    └── logo.png                 # Uygulama logosu

docs/                            # Dokümantasyon
├── SECURITY.md
├── INFRASTRUCTURE.md
├── MDM_INTEGRATION.md
└── README.md

android/                         # Android platform dosyaları
```

## Geliştirme

### Bağımlılıklar
- `flutter_secure_storage` - Güvenli token saklama
- `dio` - HTTP istekleri
- `provider` - State yönetimi
- `shared_preferences` - Yerel depolama
- `flutter_local_notifications` - Bildirimler
- `flutter_markdown` - Markdown render

### Build
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release
```

## Lisans

Bu uygulama kurumsal kullanım için geliştirilmiştir.

---

**Geliştirici:** Alpay Bilgiç  
**Son Güncelleme:** 2025 17 Aralık
