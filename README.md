# Azure DevOps Server 2022 Mobile App

**Geliştirici:** Alpay Bilgiç  
**Versiyon:** 1.2.0+45  
**Tarih:** 21-12-2025

## 📱 Genel Bakış

Bu uygulama, Azure DevOps Server 2022 on-premise kurulumları için mobil erişim sağlar. Kurumsal MDM (Mobile Device Management) sistemleri ile entegre edilerek güvenli bir şekilde dağıtılabilir. Flutter framework kullanılarak geliştirilmiştir ve hem Android hem iOS platformlarını destekler.

## ✨ Özellikler

### Work Item Yönetimi
- ✅ Work Item görüntüleme ve yönetimi
- ✅ Custom field düzenleme (selectbox, combobox, tickbox desteği)
- ✅ Gizli field'lar otomatik filtrelenir
- ✅ Discussion/Comments özelliği (yorum ekleme ve görüntüleme)
- ✅ Work Item Attachments (dosya ekleme ve görüntüleme)
- ✅ HTML desteği (Description ve diğer HTML alanları)
- ✅ Query çalıştırma ve sonuç görüntüleme

### Bildirim Sistemi
- ✅ Push notification desteği
- ✅ **Bildirim Ayarları Özelleştirmesi:**
  - İlk atamada bildirim (sadece size ilk atandığında)
  - Tüm güncellemelerde bildirim (atanmış work item'lar güncellendiğinde)
  - Sadece Hotfix filtresi (yalnızca Hotfix tipindeki work item'lar için)
  - Grup bildirimleri (belirtilen gruplara atama yapıldığında)
  - Tüm ayarlar background servislerde aktif olarak çalışır
- ✅ **Akıllı Saat Bildirimleri:**
  - Android Wear OS ve iOS watchOS desteği
  - Xiaomi, Huawei, Samsung, Apple Watch desteği
  - Saat uygulamasında özel uygulama seçimi ile bildirim iletimi (Mi Fit, Xiaomi Wear, Samsung Galaxy Watch, Apple Watch)
  - Sadece ilk atamada akıllı saat bildirimi (titreşim, ses, ekran)
  - Etkileşimli butonlar ile state değiştirme (dropdown menü)
  - Dinamik state listesi (work item'ın mevcut state'leri)
  - Bildirimden "Telefonda Aç" ile work item detay sayfasına yönlendirme
- ✅ **Nöbetçi Modu:**
  - Telefon ve akıllı saat için ayrı ayrı aktif edilebilir
  - Agresif bildirimler (maksimum öncelik, daha fazla titreşim, daha yüksek ses)
  - Okunmayan bildirimler 3 kez otomatik yenilenir (30 saniye aralıklarla)
- ✅ **Tatil Modu:**
  - Telefon ve akıllı saat için ayrı ayrı aktif edilebilir
  - Tatil modunda hiçbir bildirim gelmez
- ✅ Gerçek zamanlı güncellemeler (WebSocket)
- ✅ Background task ile periyodik kontrol

### Kimlik Doğrulama
- ✅ Personal Access Token (PAT) kimlik doğrulama
- ✅ Active Directory (AD) kimlik doğrulama (local user desteği)
- ✅ Güvenli token saklama (FlutterSecureStorage - AES-256)
- ✅ Otomatik token kontrolü
- ✅ 30 günlük otomatik logout (inaktivite)

### Wiki ve İçerik
- ✅ Wiki içerik görüntüleme
- ✅ Markdown rendering desteği

### Market Özelliği
- ✅ IIS static dizininden APK ve IPA dosyalarını indirme
- ✅ Klasör yapısı desteği (Product → Version → Files)
- ✅ Otomatik dosya filtreleme (APK, IPA, AAB)

### Kültürel Özellikler
- ✅ Türk Kültürü Popup (ana sayfada pull-to-refresh ile rastgele bilgiler)
  - 50+ Türk tarihi figürü (bilim, sanat, edebiyat)
  - 12 tarihi Türk devleti
  - 15 modern Türk cumhuriyeti ve aktif Türk devleti

### Güvenlik
- ✅ Certificate Pinning (SHA-256)
- ✅ Root/Jailbreak Detection
- ✅ Security Logging
- ✅ Encrypted Storage (AES-256)
- ✅ MDM entegrasyonu
- ✅ Uzaktan silme desteği

### Belgeler
- ✅ Belgeler ekranı (Güvenlik, Altyapı, MDM dokümantasyonları)

## 🏗️ Mimari Topoloji

### Mimari Katmanlar

```
┌─────────────────────────────────────────────────────────┐
│              Presentation Layer (UI)                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐            │
│  │  Screens │  │ Widgets  │  │ Provider │            │
│  └──────────┘  └──────────┘  └──────────┘            │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│           Business Logic Layer (Services)              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐            │
│  │   Auth   │  │ WorkItem │  │  Wiki    │            │
│  └──────────┘  └──────────┘  └──────────┘            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐            │
│  │  Notify  │  │ Background│ │ Realtime │            │
│  └──────────┘  └──────────┘  └──────────┘            │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│              Data Layer                                 │
│  ┌──────────────┐  ┌──────────────┐                    │
│  │ Secure Store │  │ Preferences  │                    │
│  │ (Encrypted)  │  │  (Plain)     │                    │
│  └──────────────┘  └──────────────┘                    │
│  ┌──────────────┐  ┌──────────────┐                    │
│  │  HTTP Client │  │  WebSocket   │                    │
│  └──────────────┘  └──────────────┘                    │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│            Platform Layer                               │
│  ┌──────────────┐  ┌──────────────┐                    │
│  │   Android    │  │     iOS      │                    │
│  │   APIs       │  │    APIs      │                    │
│  └──────────────┘  └──────────────┘                    │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│              Network (HTTPS/TLS 1.2+)                  │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│         Azure DevOps Server (API v7.0)                  │
└─────────────────────────────────────────────────────────┘
```

### Servis Mimarisi

**Core Services:**
- **AuthService**: PAT ve AD kimlik doğrulama, token yönetimi
- **StorageService**: Güvenli veri saklama (FlutterSecureStorage, SharedPreferences)
- **WorkItemService**: Work item CRUD, custom fields, attachments, comments
- **WikiService**: Wiki içerik çekme ve rendering
- **NotificationService**: Local notification gönderme
- **BackgroundTaskService**: Periyodik work item kontrolü ve bildirim
- **RealtimeService**: WebSocket ile gerçek zamanlı güncellemeler
- **MarketService**: IIS static dizin listeleme ve dosya indirme
- **TurkishCultureService**: Rastgele Türk kültürü bilgileri
- **SecurityService**: Root/jailbreak tespiti, güvenlik loglama
- **CertificatePinningService**: SHA-256 certificate pinning

### Veri Akışı

1. **Authentication Flow:**
   - Kullanıcı kimlik bilgilerini girer
   - AuthService API'ye istek gönderir
   - Token alınır ve FlutterSecureStorage'da şifrelenmiş olarak saklanır
   - Token tüm API isteklerinde kullanılır

2. **Work Item Flow:**
   - Kullanıcı work item listesini görüntüler
   - WorkItemService API'den work item'ları çeker
   - Custom field definition'ları alınır
   - Veriler UI'da gösterilir
   - Kullanıcı değişiklik yaparsa API'ye gönderilir

3. **Notification Flow:**
   - BackgroundTaskService periyodik olarak çalışır
   - Yeni/güncellenmiş work item'lar kontrol edilir
   - Bildirim ayarlarına göre filtreleme yapılır
   - Uygun bildirimler gönderilir

Detaylı mimari bilgisi için [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) dosyasına bakın.

## 🔧 Teknik Özellikler

### Platform Desteği
- **Android:** Minimum 5.0 (SDK 21), Target 14 (SDK 34)
- **iOS:** Minimum 12.0, Target 17.0

### Teknoloji Stack
- **Framework:** Flutter 3.24.0
- **Language:** Dart
- **State Management:** Provider
- **UI Components:** Material Design, Cupertino
- **HTTP Client:** Dio
- **Storage:** FlutterSecureStorage (AES-256), SharedPreferences
- **Real-time:** WebSocket Channel

### Güvenlik Özellikleri
- **Certificate Pinning:** SHA-256 fingerprint doğrulama
- **Encryption:** AES-256 şifreleme (FlutterSecureStorage)
- **Root Detection:** Root/jailbreak tespiti
- **Security Logging:** Merkezi güvenlik loglama
- **Auto Logout:** 30 günlük inaktivite sonrası otomatik logout
- **MDM Integration:** MDM sistemleri ile entegrasyon

### API Entegrasyonu
- **Azure DevOps Server REST API:** v7.0
- **Protocol:** HTTPS/TLS 1.2+
- **Real-time:** WebSocket (WSS)
- **Authentication:** PAT veya AD (Basic Auth)

## 📋 Sistem Gereksinimleri

### Azure DevOps Server
- Azure DevOps Server 2022 veya üzeri
- API Versiyonu: 7.0
- HTTPS erişimi (TLS 1.2+)

### Mobil Cihazlar
- **Android:** Minimum 5.0 (SDK 21), Target 14 (SDK 34)
- **iOS:** Minimum 12.0, Target 17.0

## 🚀 Kurulum

### Geliştirme Ortamı

```bash
# Bağımlılıkları yükle
flutter pub get

# Android APK oluştur
flutter build apk --release

# iOS IPA oluştur
flutter build ipa
```

### MDM Üzerinden Dağıtım

1. APK/IPA dosyasını hazırlayın
2. MDM sisteminize yükleyin
3. Yapılandırma profilini oluşturun
4. Dağıtım grubunu seçin
5. Uygulamayı dağıtın

Detaylar için [docs/MDM_INTEGRATION.md](docs/MDM_INTEGRATION.md) dosyasına bakın.

## ⚙️ Yapılandırma

### Gerekli Ayarlar
- Azure DevOps Server URL'si
- Personal Access Token (PAT) veya AD kimlik bilgileri
- Collection adı (opsiyonel)
- **Market URL (opsiyonel):** IIS static dizin URL'si (APK ve IPA dosyalarını indirmek için)

### İlk Kurulum

1. Uygulamayı açın
2. **Ayarlar** sayfasına gidin
3. **Server URL** alanına Azure DevOps Server URL'sini girin
4. Kimlik doğrulama yöntemini seçin (PAT veya AD)
5. Giriş yapın

### Bildirim Ayarları

1. **Ayarlar** → **Bildirim Ayarları**
2. İstediğiniz bildirim seçeneklerini aktif edin:
   - İlk atamada bildirim
   - Tüm güncellemelerde bildirim
   - Sadece Hotfix filtresi
   - Grup bildirimleri (grup adları ekleyin)
3. **Akıllı Saat Bildirimleri:**
   - **Önce saat uygulamanızda Azure DevOps uygulamasını etkinleştirin:**
     - **Android saatler (Xiaomi, Huawei, Samsung):** Mi Fit / Xiaomi Wear / Samsung Galaxy Watch uygulamasında **Bildirimler** → **Özel Uygulama Seçimi** → **Azure DevOps** aktif edin
     - **Apple Watch:** iPhone Watch uygulamasında **Bildirimler** → **Azure DevOps** aktif edin
   - **Uygulama içinde:** Ayarlar → Bildirim Ayarları → **Akıllı Saat Bildirimleri** toggle switch'ini aktif edin
   - Sadece ilk atamada akıllı saat bildirimi gönderilir
   - Etkileşimli butonlar ile state değiştirme yapılabilir
   - Bildirimden "Telefonda Aç" seçeneği ile work item detay sayfasını açabilirsiniz
4. **Nöbetçi Modu:**
   - Telefon için nöbetçi modu: Agresif bildirimler, okunmayan bildirimler 3 kez yenilenir
   - Akıllı saat için nöbetçi modu: Agresif bildirimler
5. **Tatil Modu:**
   - Telefon için tatil modu: Hiçbir bildirim gelmez
   - Akıllı saat için tatil modu: Hiçbir bildirim gelmez
6. Ayarları kaydedin

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

1. **Ayarlar** sayfasına gidin
2. **Market URL** alanına IIS static dizin URL'sini girin
   - Örnek: `https://uygun_iis.com/_static_files/market`
3. **Kaydet** butonuna tıklayın

#### Kullanım

1. Ana sayfada **Market** ikonuna tıklayın
2. Klasör yapısı görüntülenir (Product → Version → Files)
3. İstediğiniz dosyaya tıklayın
4. Dosya otomatik olarak indirilir:
   - **Android:** Downloads klasörüne kaydedilir
   - **iOS:** Files app'te görünür (Documents dizini)

## 📖 Kullanım Kılavuzu

### Work Item Yönetimi

#### Work Item Görüntüleme
1. Ana sayfada **Work Items** bölümüne gidin
2. Work item listesini görüntüleyin
3. Bir work item'a tıklayarak detaylarını görüntüleyin

#### Custom Field Düzenleme
1. Work item detay ekranında **Custom Fields** bölümüne gidin
2. Düzenlemek istediğiniz field'a tıklayın
3. Değeri değiştirin:
   - **Selectbox/Combobox:** Dropdown'dan seçin
   - **Checkbox/Tickbox:** Checkbox'ı işaretleyin/kaldırın
   - **Date:** Tarih seçiciyi kullanın
   - **Text/HTML:** Metin alanını düzenleyin
4. **Kaydet** butonuna tıklayın

#### Attachment Ekleme
1. Work item detay ekranında **Attachments** bölümüne gidin
2. **Attach File** butonuna tıklayın
3. Dosyayı seçin
4. Dosya yüklenir ve work item'a eklenir

#### Yorum Ekleme
1. Work item detay ekranında **Discussion** bölümüne gidin
2. Yorum alanına metninizi yazın
3. **Add Comment** butonuna tıklayın
4. Yorum work item'a eklenir

### Query Çalıştırma

1. Ana sayfada **Queries** ikonuna tıklayın
2. Query listesini görüntüleyin
3. Bir query'ye tıklayın
4. Query sonuçları görüntülenir
5. Sonuçlardan bir work item'a tıklayarak detaylarını görüntüleyebilirsiniz

### Wiki Görüntüleme

1. Ana sayfada **Wiki** bölümüne gidin
2. Wiki içeriği görüntülenir
3. Markdown formatı desteklenir

### Bildirim Yönetimi

#### Bildirim Ayarları

**Ayarlar Ekranı Görünümü:**
- Ayarlar ekranında **Bildirim Ayarları** bölümü bulunur
- **Kontrol Sıklığı** ayarı ile polling interval'i ayarlayabilirsiniz (5-300 saniye arası)
- Hızlı (10s), Normal (15s), Yavaş (30s) gibi önceden tanımlı seçenekler mevcuttur

**Bildirim Türleri:**
1. **Ayarlar** → **Bildirim Ayarları** bölümüne gidin
2. İstediğiniz bildirim seçeneklerini aktif edin:
   - **İlk Atamada Bildirim:** Sadece size ilk atandığında bildirim alın
     - Toggle switch'i aktif edin
     - Bu seçenek aktifken, sadece ilk atamada bildirim gelir, sonraki güncellemelerde gelmez
   - **Tüm Güncellemelerde Bildirim:** Atanmış work item'lar güncellendiğinde bildirim alın
     - Toggle switch'i aktif edin
     - Bu seçenek aktifken, tüm güncellemelerde bildirim gelir
   - **Sadece Hotfix:** Yalnızca Hotfix tipindeki work item'lar için bildirim alın
     - Toggle switch'i aktif edin
     - Bu seçenek aktifken, sadece Hotfix tipindeki work item'lar için bildirim gelir
   - **Grup Bildirimleri:** Belirtilen gruplara atama yapıldığında bildirim alın
     - Toggle switch'i aktif edin
     - Grup adı eklemek için **+** butonuna tıklayın
     - Grup adı silmek için **X** butonuna tıklayın

**Akıllı Saat Bildirimleri:**

Akıllı saatlerinizde Azure DevOps bildirimlerini almak için önce saat uygulamanızda Azure DevOps uygulamasını etkinleştirmeniz gerekir.

**Android Saatler (Xiaomi, Huawei, Samsung, vb.):**

1. **Mi Fit / Xiaomi Wear / Samsung Galaxy Watch uygulamasını açın**
2. **Profil** veya **Ayarlar** bölümüne gidin
3. **Bildirimler** veya **Uygulama Bildirimleri** seçeneğini bulun
4. **Özel Uygulama Seçimi** veya **Uygulama Bildirimleri** bölümüne gidin
5. **Azure DevOps** uygulamasını bulun ve aktif edin
6. Bildirim ayarlarını kontrol edin:
   - **Bildirimleri Göster**: Açık
   - **Titreşim**: Açık (isteğe bağlı)
   - **Ses**: Açık (isteğe bağlı)

**Apple Watch (watchOS):**

1. iPhone'unuzda **Watch** uygulamasını açın
2. **Bildirimler** sekmesine gidin
3. **Azure DevOps** uygulamasını bulun
4. Bildirim stilini seçin:
   - **Bildirimleri Göster**: Açık
   - **Bildirimlerde Ses Çal**: Açık (isteğe bağlı)
   - **Titreşim**: Açık (isteğe bağlı)

**Uygulama İçi Ayarlar:**

1. **Ayarlar** → **Bildirim Ayarları** bölümüne gidin
2. **Akıllı Saat Bildirimleri** toggle switch'ini aktif edin
3. Bu özellik aktifken:
   - Sadece ilk atamada akıllı saatte bildirim gelir
   - Bildirimde titreşim, ses ve ekran bildirimi olur
   - Etkileşimli butonlar ile work item state'i değiştirilebilir
   - State listesi dinamik olarak work item'ın mevcut state'lerinden oluşur
   - Dropdown menü ile state seçimi yapılabilir

**Bildirimden Work Item Açma:**

Akıllı saatte bildirim geldiğinde:
1. Bildirime dokunun veya kaydırın
2. **"Telefonda Aç"** veya **"Open on Phone"** seçeneğini seçin
3. Telefondaki Azure DevOps uygulaması otomatik olarak açılır
4. İlgili work item detay sayfası gösterilir

**Not:** Bu özellik için telefon ve akıllı saatin eşleşmiş olması ve Bluetooth bağlantısının aktif olması gerekir.

**Nöbetçi Modu:**
- **Nöbetçi Modu** bölümünde telefon ve akıllı saat için ayrı ayrı ayarlar bulunur
- **Telefon için Nöbetçi Modu:**
  - Toggle switch'i aktif edin
  - Bildirimler daha agresif olur (maksimum öncelik, daha fazla titreşim, daha yüksek ses)
  - Okunmayan bildirimler 30 saniye aralıklarla 3 kez otomatik yenilenir
- **Akıllı Saat için Nöbetçi Modu:**
  - Toggle switch'i aktif edin
  - Akıllı saatte bildirimler daha agresif olur

**Tatil Modu:**
- **Tatil Modu** bölümünde telefon ve akıllı saat için ayrı ayrı ayarlar bulunur
- **Telefon için Tatil Modu:**
  - Toggle switch'i aktif edin
  - Bu mod aktifken telefonda hiçbir bildirim gelmez
- **Akıllı Saat için Tatil Modu:**
  - Toggle switch'i aktif edin
  - Bu mod aktifken akıllı saatte hiçbir bildirim gelmez

**Ayarlar Ekranı Özellikleri:**
- Tüm ayarlar gerçek zamanlı olarak kaydedilir
- Ayarlar cihazda kalıcı olarak saklanır
- Uygulama yeniden başlatıldığında ayarlar korunur

#### Bildirim Geçmişi
- Bildirim gönderilmiş work item'lar için tekrar bildirim gönderilmez
- Uygulama yeniden kurulduğunda bile bildirim geçmişi korunur
- İlk atamada bildirim gönderilmiş work item'lar için sonraki güncellemelerde bildirim gelmez (eğer sadece "ilk atamada bildirim" seçeneği aktifse)

## 🔒 Güvenlik

### Güvenlik Özellikleri

- ✅ **Token Şifreleme:** `flutter_secure_storage` kullanılıyor (Production'da aktif)
- Android: EncryptedSharedPreferences
  - iOS: Keychain Services
  - AES-256 şifreleme

- ✅ **Certificate Pinning:** Sertifika pinning uygulandı (Production Ready)
  - SHA-256 fingerprint doğrulama
  - Production build'lerde otomatik aktif (`PRODUCTION=true`)
  - Setup guide: `scripts/setup_certificate_pinning.md`

- ✅ **Root/Jailbreak Tespiti:** Root/jailbreak tespiti eklendi
  - Uygulama başlangıcında otomatik kontrol
  - Güvenlik olayları loglanıyor

- ✅ **Otomatik Logout:** Otomatik logout mekanizması eklendi
  - 30 gün kullanılmadığında otomatik logout
  - Son aktivite takibi
  - Uygulama açıldığında kontrol edilir

Detaylı güvenlik bilgileri için [docs/SECURITY.md](docs/SECURITY.md) dosyasına bakın.

## 📚 Dokümantasyon

### Ana Dokümantasyon
- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - Mimari topoloji dokümantasyonu
  - Mimari katmanlar
  - Bileşen diyagramları
  - Veri akışı
  - Güvenlik mimarisi
  - Deployment topolojisi

### Güvenlik ve Altyapı
- **[SECURITY.md](docs/SECURITY.md)** - Güvenlik dokümantasyonu
  - Güvenlik mimarisi
  - Kimlik doğrulama
  - Veri güvenliği
  - Ağ güvenliği
  - Güvenlik açıkları ve önlemler

- **[INFRASTRUCTURE.md](docs/INFRASTRUCTURE.md)** - Altyapı dokümantasyonu
  - Sistem gereksinimleri
  - Ağ yapılandırması
  - Sertifika yönetimi
  - Dağıtım adımları
  - İzleme ve bakım

- **[MDM_INTEGRATION.md](docs/MDM_INTEGRATION.md)** - MDM entegrasyon kılavuzu
  - Microsoft Intune entegrasyonu
  - VMware Workspace ONE entegrasyonu
  - Yapılandırma profilleri
  - Uyumluluk politikaları

- **[SECURITY_FEATURES.md](docs/SECURITY_FEATURES.md)** - Güvenlik özellikleri detayları

## 🛠️ Geliştirme

### Bağımlılıklar
- `flutter_secure_storage` - Güvenli token saklama
- `dio` - HTTP istekleri
- `provider` - State yönetimi
- `shared_preferences` - Yerel depolama
- `flutter_local_notifications` - Bildirimler
- `file_picker` - Dosya seçimi
- `web_socket_channel` - WebSocket bağlantıları

### Build
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# iOS IPA
flutter build ipa
```

### Proje Yapısı
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
│   ├── market_service.dart
│   ├── turkish_culture_service.dart
│   ├── security_service.dart
│   └── certificate_pinning_service.dart
└── assets/                      # Assets
└── images/
        └── logo.png

docs/                            # Dokümantasyon
├── ARCHITECTURE.md
├── SECURITY.md
├── INFRASTRUCTURE.md
├── MDM_INTEGRATION.md
├── SECURITY_FEATURES.md
└── README.md
```

## 📝 Release Notes

### v1.1.4+43 (21-12-2025)

#### Yeni Özellikler
- ✅ Türk Kültürü Popup (ana sayfada pull-to-refresh ile rastgele bilgiler)
- ✅ Work Item Attachments (dosya ekleme ve görüntüleme)
- ✅ Custom field düzenleme iyileştirmeleri
- ✅ Discussion/Comments özelliği
- ✅ Bildirim ayarları özelleştirmesi

#### İyileştirmeler
- ✅ Steps alanı kaldırıldı
- ✅ HTML desteği (Description ve diğer alanlar)
- ✅ AD login local user desteği
- ✅ Bildirim filtreleme mantığı iyileştirildi

Detaylı release notları için [RELEASE_NOTES.md](RELEASE_NOTES.md) dosyasına bakın.

## 📞 Destek

**Teknik Destek:**
- Geliştirici: Alpay Bilgiç
- E-posta: bilgicalpay@gmail.com

**Güvenlik Sorunları:**
- E-posta: bilgicalpay@gmail.com
- Repository: https://github.com/bilgicalpay/azuredevops-mobile

## 📄 Lisans

Bu uygulama açık kaynak kodlu olarak geliştirilmiştir ve özel bir lisans altında dağıtılmaktadır.

### Lisans Koşulları

**İzin Verilenler:**
- ✅ Yazılımı özgürce kullanabilirsiniz
- ✅ Yazılımı değiştirebilir ve geliştirebilirsiniz
- ✅ Yazılımı ticari olmayan amaçlarla dağıtabilirsiniz
- ✅ Eğitim ve kişisel kullanım için serbest

**Kesinlikle Yasak Olanlar:**
- ❌ **TİCARİ SATIŞ YASAKTIR**: Yazılımı veya türev eserlerini ticari amaçlarla satamazsınız
- ❌ **TİCARİ DAĞITIM YASAKTIR**: Yazılımı veya türev eserlerini ticari ürünlere dahil edemezsiniz
- ❌ **TİCARİ LİSANSLAMA YASAKTIR**: Türev eserleri sahipli veya ticari lisanslar altında lisanslayamazsınız
- ❌ **YENİDEN SATIŞ YASAKTIR**: Herhangi bir ticari dağıtım, yeniden satış veya ticarileştirme biçimi yasaktır

**Gereksinimler:**
- 📝 Kullanımda orijinal telif hakkı bildirimini ve atıfı korumalısınız
- 📝 Türev eserler aynı lisans koşulları altında dağıtılmalıdır
- 📝 Kaynak kodu kullanılabilir olmalıdır

**Ticari Kullanım:**
**ÖNEMLİ**: Ticari kullanım, satış, lisanslama veya dağıtım için **AÇIK YAZILI İZİN GEREKLİDİR**.

Ticari kullanım için lütfen iletişime geçin:
- E-posta: bilgicalpay@gmail.com

**Detaylı lisans metni (Türkçe ve İngilizce) için [LICENSE](LICENSE) dosyasına bakın.**

---

**Geliştirici:** Alpay Bilgiç  
**Son Güncelleme:** 21-12-2025  
**Versiyon:** 1.2.0+46
