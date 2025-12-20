# Azure DevOps Server 2022 Mobile App

**Geliştirici:** Alpay Bilgiç  
**Versiyon:** 1.1.3  
**Tarih:** 2024.12.20

## Genel Bakış

Bu uygulama, Azure DevOps Server 2022 on-premise kurulumları için mobil erişim sağlar. Kurumsal MDM (Mobile Device Management) sistemleri ile entegre edilerek güvenli bir şekilde dağıtılabilir.

## Özellikler

- ✅ Work Item görüntüleme ve yönetimi
- ✅ Query çalıştırma ve sonuç görüntüleme
- ✅ Wiki içerik görüntüleme
- ✅ Push notification desteği
- ✅ **Bildirim Ayarları Özelleştirmesi:**
  - İlk atamada bildirim (sadece size ilk atandığında)
  - Tüm güncellemelerde bildirim (atanmış work item'lar güncellendiğinde)
  - Sadece Hotfix filtresi (yalnızca Hotfix tipindeki work item'lar için)
  - Grup bildirimleri (belirtilen gruplara atama yapıldığında)
  - Tüm ayarlar background servislerde aktif olarak çalışır
- ✅ Personal Access Token (PAT) kimlik doğrulama
- ✅ Active Directory (AD) kimlik doğrulama
- ✅ MDM entegrasyonu
- ✅ Güvenli token saklama (FlutterSecureStorage)
- ✅ Belgeler ekranı (Güvenlik, Altyapı, MDM dokümantasyonları)
- ✅ **Market Özelliği:** IIS static dizininden APK ve IPA dosyalarını indirme

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
- **Market URL (opsiyonel):** IIS static dizin URL'si (APK ve IPA dosyalarını indirmek için)

### Market Özelliği

Market özelliği, IIS static dizininden APK ve IPA dosyalarını indirmenizi sağlar.

#### IIS Yapılandırması

1. **IIS'te static dosya servisini aktif edin**
2. **Directory browsing'i aktif edin**
3. **Market dizin yapısını oluşturun:**
   ```
   C:\inetpub\wwwroot\_static\market\
   ├── ProductA\
   │   ├── 1.0.0\
   │   │   ├── ProductA-1.0.0.apk
   │   │   └── ProductA-1.0.0.ipa
   │   └── 1.0.1\
   └── ProductB\
       └── 2.0.0\
   ```

4. **web.config dosyası oluşturun:**
   
   Ana market dizinine (`C:\inetpub\wwwroot\_static\market\`) `web.config` dosyası ekleyin:
   
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <configuration>
       <system.webServer>
           <staticContent>
               <mimeMap fileExtension=".IPA" mimeType="application/octet-stream" />
               <mimeMap fileExtension=".APK" mimeType="application/octet-stream" />
           </staticContent>
       </system.webServer>
   </configuration>
   ```

5. **HTTPS erişimini sağlayın**

#### Uygulama İçi Yapılandırma

Market kullanımı için IIS altında bir dizin oluşturularak bu HTML adresi uygulamaya girilir. O dizin altına da product ve versionlar ile ayrılmış dizinler oluşturulur ve APK ve IPA dosyaları buraya atılır. Ancak uygulama üzerinden dosya indirilebilmesi için aşağıdaki gibi ana folder altına `web.config` eklenmelidir.


**Yapılandırma Adımları:**

1. **Ayarlar** sayfasına gidin
2. **Market URL** alanına APK ve IPA dosyalarını uygun klasörlerle yükleyeceğiniz bir dizini IIS altında static dosyalar için oluşturmalısınız. Ardından bu repository URL'sini girin
   - Örnek: `https://uygun_iis.com/_static_files/market`
3. **Kaydet** butonuna tıklayın

#### Kullanım

1. Ana sayfada **Market** ikonuna tıklayın
2. Klasör yapısı görüntülenir (Product → Version → Files)
3. İstediğiniz dosyaya tıklayın
4. Dosya otomatik olarak indirilir:
   - **Android:** Downloads klasörüne kaydedilir
   - **iOS:** Files app'te görünür (Documents dizini)

#### Desteklenen Artifact'lar

- **Android APK:** `.apk` dosyaları
- **iOS IPA:** `.ipa` dosyaları
- **Android AAB:** `.aab` dosyaları (App Bundle) (bu veya başka dosya tipleri için webconfiğe yeni satır ekleyin.)

#### Notlar

- Market özelliği, IIS static dizininden dosyaları listeler ve indirir
- Git repository veya Azure DevOps Releases API kullanmaz
- Directory listing (HTML veya JSON) formatını destekler
- APK, IPA ve AAB dosyaları otomatik olarak filtrelenir
- Buraya kdar okuyan olursa bir Türk kahvesini içerim.

Detaylı bilgi için [docs/README.md](docs/README.md#market-özelliği-ile-dağıtım) dosyasına bakın.

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
│   ├── documents_screen.dart
│   └── market_screen.dart
├── services/                    # Servisler
│   ├── auth_service.dart
│   ├── storage_service.dart
│   ├── work_item_service.dart
│   ├── wiki_service.dart
│   ├── notification_service.dart
│   ├── background_task_service.dart
│   ├── realtime_service.dart
│   └── market_service.dart

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
**Son Güncelleme:** 2024 20 Aralık  
**Versiyon:** 1.1.3+41
