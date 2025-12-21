# Azure DevOps Server 2022 Mobile App - Dokümantasyon

**Geliştirici:** Alpay Bilgiç  
**Versiyon:** 1.1.4+43  
**Tarih:** 21-12-2025

## Genel Bakış

Bu uygulama, Azure DevOps Server 2022 on-premise kurulumları için mobil erişim sağlar. Kurumsal MDM (Mobile Device Management) sistemleri ile entegre edilerek güvenli bir şekilde dağıtılabilir.

## Özellikler

- ✅ Work Item görüntüleme ve yönetimi
  - Custom field düzenleme (selectbox, combobox, tickbox desteği)
  - Gizli field'lar otomatik filtrelenir
  - Discussion/Comments özelliği (yorum ekleme ve görüntüleme)
  - Work Item Attachments (dosya ekleme ve görüntüleme)
- ✅ Query çalıştırma ve sonuç görüntüleme
- ✅ Wiki içerik görüntüleme
- ✅ Push notification desteği
  - Bildirim ayarları özelleştirmesi (ilk atama, tüm güncellemeler, Hotfix filtresi, grup bildirimleri)
- ✅ Personal Access Token (PAT) kimlik doğrulama
- ✅ Active Directory (AD) kimlik doğrulama (local user desteği)
- ✅ MDM entegrasyonu
- ✅ Market özelliği (IIS static dizininden APK/IPA indirme)
- ✅ Türk Kültürü Popup (ana sayfada pull-to-refresh ile rastgele bilgiler)

## Dokümantasyon

### Mimari ve Topoloji

1. **[ARCHITECTURE.md](ARCHITECTURE.md)** - Mimari topoloji dokümantasyonu
   - Mimari katmanlar
   - Bileşen diyagramları
   - Veri akışı
   - Güvenlik mimarisi
   - Deployment topolojisi
   - Teknoloji stack

### Güvenlik ve Altyapı

2. **[SECURITY.md](SECURITY.md)** - Güvenlik dokümantasyonu
   - Güvenlik mimarisi
   - Kimlik doğrulama
   - Veri güvenliği
   - Ağ güvenliği
   - Güvenlik açıkları ve önlemler

3. **[INFRASTRUCTURE.md](INFRASTRUCTURE.md)** - Altyapı dokümantasyonu
   - Sistem gereksinimleri
   - Ağ yapılandırması
   - Sertifika yönetimi
   - Dağıtım adımları
   - İzleme ve bakım

4. **[MDM_INTEGRATION.md](MDM_INTEGRATION.md)** - MDM entegrasyon kılavuzu
   - Microsoft Intune entegrasyonu
   - VMware Workspace ONE entegrasyonu
   - Yapılandırma profilleri
   - Uyumluluk politikaları

## Hızlı Başlangıç

### Güvenlik Ekibi İçin

1. **[SECURITY.md](SECURITY.md)** dosyasını inceleyin
2. Güvenlik gereksinimlerini değerlendirin
3. Güvenlik açıklarını gözden geçirin
4. Önerilen iyileştirmeleri planlayın

### Altyapı Ekibi İçin

1. **[INFRASTRUCTURE.md](INFRASTRUCTURE.md)** dosyasını inceleyin
2. Sistem gereksinimlerini kontrol edin
3. Ağ yapılandırmasını planlayın
4. Sertifika yönetimini yapılandırın

### MDM Yöneticisi İçin

1. **[MDM_INTEGRATION.md](MDM_INTEGRATION.md)** dosyasını inceleyin
2. MDM platformunuza göre entegrasyon adımlarını takip edin
3. Yapılandırma profillerini oluşturun
4. Uyumluluk politikalarını ayarlayın

## Sistem Gereksinimleri

### Azure DevOps Server

- Azure DevOps Server 2022 veya üzeri
- API Versiyonu: 7.0
- HTTPS erişimi (TLS 1.2+)

### Mobil Cihazlar

**Android:**
- Minimum: Android 5.0 (SDK 21)
- Target: Android 14 (SDK 34)

**iOS:**
- Minimum: iOS 12.0
- Target: iOS 17.0

## Güvenlik Notları

✅ **Tüm güvenlik özellikleri uygulandı:**

1. ✅ **Token Şifreleme:** `flutter_secure_storage` kullanılıyor (Production'da aktif)
   - Android: EncryptedSharedPreferences
   - iOS: Keychain Services
   - AES-256 şifreleme

2. ✅ **Certificate Pinning:** Sertifika pinning uygulandı (Production Ready)
   - SHA-256 fingerprint doğrulama
   - Production build'lerde otomatik aktif (`PRODUCTION=true`)
   - Setup guide: `scripts/setup_certificate_pinning.md`

3. ✅ **Root/Jailbreak Tespiti:** Root/jailbreak tespiti eklendi
   - Uygulama başlangıcında otomatik kontrol
   - Güvenlik olayları loglanıyor
   - Package: `root_detector: ^0.0.2`

4. ✅ **Otomatik Logout:** Otomatik logout mekanizması eklendi
   - 30 gün kullanılmadığında otomatik logout
   - Son aktivite takibi
   - Uygulama açıldığında kontrol edilir

5. ✅ **Market Özelliği:** IIS static dizininden uygulama dosyaları indirme
   - IIS directory listing desteği (HTML ve JSON)
   - APK, IPA, AAB dosyaları için otomatik filtreleme
   - Dosya boyutu gösterimi
   - Pull-to-refresh desteği

Detaylar için [SECURITY.md](SECURITY.md) dosyasına bakın.

## Dağıtım

### MDM Üzerinden Dağıtım

1. APK/IPA dosyasını hazırlayın
2. MDM sisteminize yükleyin
3. Yapılandırma profilini oluşturun
4. Dağıtım grubunu seçin
5. Uygulamayı dağıtın

Detaylar için [MDM_INTEGRATION.md](MDM_INTEGRATION.md) dosyasına bakın.

### Market Özelliği ile Dağıtım

Market özelliği, kullanıcıların uygulama güncellemelerini doğrudan cihazlarına indirmelerini sağlar.

#### IIS Yapılandırması

1. **IIS'te static dosya servisini aktif edin**
   - IIS Manager → Sites → [Your Site] → Features View
   - Static Content modülünü aktif edin

2. **Directory browsing'i aktif edin**
   - IIS Manager → Sites → [Your Site] → Features View
   - Directory Browsing → Enable

3. **Market dizin yapısını oluşturun**
   ```
   C:\inetpub\wwwroot\_static\market\
   ├── ProductA\
   │   ├── 1.0.0\
   │   │   ├── ProductA-1.0.0.apk
   │   │   └── ProductA-1.0.0.ipa
   │   └── 1.0.1\
   │       ├── ProductA-1.0.1.apk
   │       └── ProductA-1.0.1.ipa
   └── ProductB\
       └── 2.0.0\
           ├── ProductB-2.0.0.apk
           └── ProductB-2.0.0.ipa
   ```

4. **web.config dosyası oluşturun**
   
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
   
   **Not:** Bu dosya, APK ve IPA dosyalarının doğru MIME type ile sunulmasını sağlar. Aksi halde dosyalar indirilemez.

5. **HTTPS erişimini sağlayın**
   - SSL sertifikası yapılandırın
   - HTTPS binding ekleyin

#### Uygulama İçi Yapılandırma

1. **Ayarlar** sayfasına gidin
2. **Market URL** alanına IIS static dizin URL'sini girin
   - Format: `https://your-server.com/_static/market/`
   - Örnek: `https://devops.higgscloud.com/_static/market/`
3. **Kaydet** butonuna tıklayın

#### Kullanım

1. Ana ekranda **Market** ikonuna tıklayın
2. Klasör yapısı görüntülenir (Product → Version → Files)
3. İstediğiniz dosyaya tıklayın
4. Dosya otomatik olarak indirilir:
   - **Android:** Downloads klasörüne kaydedilir
   - **iOS:** Files app'te görünür (Documents dizini)

#### Dosya İndirme

- **Android:** Dosyalar Downloads klasörüne kaydedilir. Android 10+ için özel izin gerekmez (scoped storage).
- **iOS:** Dosyalar Documents dizinine kaydedilir ve Files app'te görünür.

#### Notlar

- Market özelliği, IIS static dizininden dosyaları listeler ve indirir
- Git repository veya Azure DevOps Releases API kullanmaz
- Directory listing (HTML veya JSON) formatını destekler
- APK, IPA ve AAB dosyaları otomatik olarak filtrelenir

## Destek

**Teknik Destek:**
- Geliştirici: Alpay Bilgiç
- E-posta: bilgicalpay@gmail.com

**Güvenlik Sorunları:**
- E-posta: [Güvenlik Ekibi E-postası]

**Altyapı Desteği:**
- E-posta: [Altyapı Ekibi E-postası]

## Lisans

Bu uygulama kurumsal kullanım için geliştirilmiştir.

---

**Son Güncelleme:** 21-12-2025  
**Dokümantasyon Versiyonu:** 1.1.4

