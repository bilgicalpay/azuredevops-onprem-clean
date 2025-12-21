# Altyapı ve Dağıtım Dokümantasyonu

**Uygulama:** Azure DevOps Server 2022 Mobile App  
**Geliştirici:** Alpay Bilgiç  
**Versiyon:** 1.1.4+43  
**Tarih:** 21-12-2025

## İçindekiler

1. [Sistem Gereksinimleri](#sistem-gereksinimleri)
2. [MDM Entegrasyonu](#mdm-entegrasyonu)
3. [Ağ Yapılandırması](#ağ-yapılandırması)
4. [Sertifika Yönetimi](#sertifika-yönetimi)
5. [Dağıtım Adımları](#dağıtım-adımları)
6. [Yapılandırma](#yapılandırma)
7. [İzleme ve Bakım](#izleme-ve-bakım)
8. [Sorun Giderme](#sorun-giderme)

---

## Sistem Gereksinimleri

### Azure DevOps Server Gereksinimleri

**Minimum Versiyon:**
- Azure DevOps Server 2022 veya üzeri
- API Versiyonu: 7.0

**Gerekli Özellikler:**
- HTTPS erişimi (TLS 1.2+)
- Personal Access Token (PAT) desteği
- Active Directory entegrasyonu (opsiyonel)
- Work Item Tracking API erişimi
- Wiki API erişimi (opsiyonel)

**Ağ Gereksinimleri:**
- Port 443 (HTTPS) erişimi
- İnternet erişimi gerekli değildir (on-premise)
- VPN bağlantısı desteklenir

### Mobil Cihaz Gereksinimleri

**Android:**
- Minimum Android SDK: 21 (Android 5.0 Lollipop)
- Target Android SDK: 34 (Android 14)
- Minimum RAM: 2GB
- İnternet bağlantısı (Azure DevOps Server'a erişim için)

**iOS:**
- Minimum iOS: 12.0
- Target iOS: 17.0
- Minimum RAM: 2GB
- İnternet bağlantısı (Azure DevOps Server'a erişim için)

### MDM Sistemi Gereksinimleri

**Desteklenen MDM Platformları:**
- Microsoft Intune
- VMware Workspace ONE
- MobileIron
- IBM MaaS360
- SOTI MobiControl
- Diğer MDM sistemleri (standart protokoller)

**MDM Özellikleri:**
- Uygulama dağıtımı
- Uygulama yapılandırması
- Cihaz uyumluluk kontrolü
- Uzaktan silme
- VPN yapılandırması
- Sertifika dağıtımı

---

## MDM Entegrasyonu

### Uygulama Paket Bilgileri

**Android:**
- Package Name: `io.rdc.azuredevops`
- Application ID: `io.rdc.azuredevops`
- Minimum SDK: 21
- Target SDK: 34

**iOS:**
- Bundle ID: `io.rdc.azuredevops`
- Minimum iOS: 12.0
- Target iOS: 17.0

### MDM Yapılandırma Profili

#### Android Enterprise (Recommended)

**Yapılandırma Parametreleri:**

```json
{
  "server_url": "https://devops.example.com",
  "collection": "DefaultCollection",
  "require_vpn": true,
  "certificate_pinning": true,
  "auto_logout_minutes": 30,
  "require_device_encryption": true,
  "block_rooted_devices": true
}
```

**Yapılandırma Anahtarları:**
- `server_url`: Azure DevOps Server URL'si (zorunlu)
- `collection`: Collection adı (opsiyonel)
- `require_vpn`: VPN zorunluluğu (true/false)
- `certificate_pinning`: Sertifika pinning aktif (true/false)
- `auto_logout_minutes`: Otomatik logout süresi (dakika)
- `require_device_encryption`: Cihaz şifreleme zorunluluğu
- `block_rooted_devices`: Root cihazları engelle

#### iOS Configuration Profile

**Yapılandırma Parametreleri:**

```xml
<dict>
  <key>server_url</key>
  <string>https://devops.example.com</string>
  <key>collection</key>
  <string>DefaultCollection</string>
  <key>require_vpn</key>
  <true/>
  <key>certificate_pinning</key>
  <true/>
  <key>auto_logout_minutes</key>
  <integer>30</integer>
  <key>require_device_encryption</key>
  <true/>
  <key>block_jailbroken_devices</key>
  <true/>
</dict>
```

### Uygulama Dağıtımı

#### 1. APK/IPA Hazırlama

**Android APK:**
```bash
# Release APK oluşturma
flutter build apk --release

# APK konumu
build/app/outputs/flutter-apk/app-release.apk
```

**iOS IPA:**
```bash
# Release IPA oluşturma
flutter build ipa

# IPA konumu
build/ios/ipa/*.ipa
```

#### 2. MDM'e Yükleme

**Microsoft Intune:**
1. Intune Admin Center → Apps → Android/iOS
2. "Add" → "Line-of-business app"
3. APK/IPA dosyasını yükle
4. Yapılandırma profilini ekle
5. Dağıtım grubunu seç

**VMware Workspace ONE:**
1. Workspace ONE UEM Console → Apps → Native
2. "Add Application" → "Internal"
3. APK/IPA dosyasını yükle
4. Yapılandırma ayarlarını ekle
5. Assignment profili oluştur

### Cihaz Uyumluluk Politikaları

**Önerilen Politikalar:**

1. **Cihaz Şifreleme:**
   - Zorunlu: Evet
   - Minimum şifre uzunluğu: 6 karakter
   - Biometric authentication: Desteklenir

2. **Jailbreak/Root Tespiti:**
   - Root/jailbreak cihazlarda uygulama çalışmamalı
   - Tespit edildiğinde uygulama erişimi engellenmeli

3. **Ekran Kilidi:**
   - Zorunlu: Evet
   - Timeout: 5 dakika

4. **Uygulama Güvenliği:**
   - Uygulama verileri şifrelenmeli
   - Ekran görüntüsü engellenebilir (opsiyonel)
   - Uygulama kopyalama engellenebilir

---

## Ağ Yapılandırması

### Firewall Kuralları

**Gerekli Portlar:**
- 443/TCP (HTTPS) - Azure DevOps Server API erişimi
- 443/TCP (WSS) - WebSocket bağlantıları (opsiyonel)

**Gerekli Endpoint'ler:**
```
https://[devops-server]/_apis/*
https://[devops-server]/[collection]/_apis/*
https://[devops-server]/[collection]/[project]/_apis/*
```

**API Endpoint Örnekleri:**
- `/_apis/projects?api-version=7.0`
- `/_apis/wit/workitems?api-version=7.0`
- `/_apis/wit/queries?api-version=7.0`
- `/_apis/wiki/wikis/*?api-version=7.0`

### VPN Yapılandırması

**Desteklenen VPN Türleri:**
- IPsec VPN
- SSL VPN
- Always-On VPN (Android Enterprise)
- Per-App VPN (iOS)

**VPN Yapılandırma:**
- MDM üzerinden VPN profili dağıtılabilir
- Uygulama özel VPN yapılandırması (gelecekte)

### Proxy Yapılandırması

**Desteklenen Proxy Türleri:**
- HTTP Proxy
- HTTPS Proxy
- SOCKS Proxy (sınırlı)

**Yapılandırma:**
- Sistem proxy ayarları kullanılır
- MDM üzerinden proxy yapılandırması yapılabilir

---

## Sertifika Yönetimi

### SSL/TLS Sertifikaları

**Gereksinimler:**
- Geçerli SSL sertifikası (Azure DevOps Server için)
- Sertifika zinciri tam olmalı
- Sertifika süresi dolmamış olmalı

**Sertifika Türleri:**
- Kurumsal CA sertifikası (önerilir)
- Public CA sertifikası
- Self-signed sertifikası (test için)

### Sertifika Dağıtımı

**MDM Üzerinden:**
1. Sertifika dosyasını (.p12, .pfx, .cer) MDM'e yükle
2. Dağıtım grubunu seç
3. Sertifika güven ayarlarını yapılandır
4. Cihazlara dağıt

**Android:**
- Sertifika "User" veya "System" trust store'a eklenebilir
- MDM üzerinden otomatik dağıtım

**iOS:**
- Sertifika "Keychain" içine eklenir
- MDM üzerinden otomatik dağıtım

### Certificate Pinning

**Uygulama İçi Pinning:**
- Azure DevOps Server sertifikası pin edilebilir
- Sertifika değişikliklerinde uygulama güncellemesi gerekir

**Yapılandırma:**
```dart
// Örnek yapılandırma (gelecekte eklenecek)
final certificatePinning = {
  'devops.example.com': [
    'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='
  ]
};
```

---

## Dağıtım Adımları

### Ön Hazırlık

1. **Azure DevOps Server Kontrolü:**
   - API erişimi test edilmeli
   - PAT token oluşturulmalı (test için)
   - AD entegrasyonu kontrol edilmeli (varsa)

2. **MDM Yapılandırması:**
   - MDM hesabı hazır olmalı
   - Dağıtım grubu oluşturulmalı
   - Yapılandırma profili hazırlanmalı

3. **Ağ Yapılandırması:**
   - Firewall kuralları eklenmeli
   - VPN yapılandırması hazırlanmalı (gerekirse)
   - Proxy ayarları yapılandırılmalı (gerekirse)

### Dağıtım Süreci

#### Adım 1: Uygulama Paketini Hazırlama

```bash
# Android APK
cd /path/to/project
flutter build apk --release

# iOS IPA
flutter build ipa
```

#### Adım 2: MDM'e Yükleme

1. MDM konsoluna giriş yap
2. Uygulama bölümüne git
3. Yeni uygulama ekle
4. APK/IPA dosyasını yükle
5. Yapılandırma profilini ekle

#### Adım 3: Dağıtım Grubunu Yapılandırma

1. Dağıtım grubunu seç
2. Yükleme politikasını ayarla (zorunlu/opsiyonel)
3. Güncelleme politikasını ayarla
4. Uyumluluk politikalarını ayarla

#### Adım 4: Pilot Test

1. Küçük bir kullanıcı grubuna dağıt
2. Fonksiyonellik testleri yap
3. Performans testleri yap
4. Geri bildirim topla

#### Adım 5: Genel Dağıtım

1. Tüm kullanıcı gruplarına dağıt
2. Kullanıcı eğitimi sağla
3. Destek kanallarını hazırla

---

## Yapılandırma

### Uygulama Yapılandırma Parametreleri

**Zorunlu Parametreler:**
- `server_url`: Azure DevOps Server URL'si

**Opsiyonel Parametreler:**
- `collection`: Collection adı
- `default_project`: Varsayılan proje
- `wiki_url`: Varsayılan wiki URL'si

**Güvenlik Parametreleri:**
- `require_vpn`: VPN zorunluluğu
- `certificate_pinning`: Sertifika pinning aktif
- `auto_logout_minutes`: Otomatik logout süresi
- `require_device_encryption`: Cihaz şifreleme zorunluluğu
- `block_rooted_devices`: Root cihazları engelle

### Kullanıcı Yapılandırması

**İlk Kurulum:**
1. Uygulama açılır
2. Server URL girilir (MDM'den otomatik gelebilir)
3. Kimlik doğrulama yöntemi seçilir (PAT/AD)
4. Giriş yapılır

**Ayarlar:**
- Server URL değiştirilebilir
- Wiki URL ayarlanabilir
- Çıkış yapılabilir

---

## İzleme ve Bakım

### İzleme Metrikleri

**Uygulama Metrikleri:**
- Aktif kullanıcı sayısı
- Günlük/haftalık kullanım
- Hata oranları
- Performans metrikleri

**Güvenlik Metrikleri:**
- Başarısız giriş denemeleri
- Cihaz uyumsuzluk raporları
- API hata oranları

### Bakım Planı

**Haftalık:**
- Log analizi
- Hata raporları kontrolü
- Performans değerlendirmesi

**Aylık:**
- Güvenlik açığı taraması
- Bağımlılık güncellemeleri
- Kullanıcı geri bildirimleri değerlendirme

**Yıllık:**
- Güvenlik denetimi
- Altyapı gözden geçirme
- Politika güncellemeleri

### Güncelleme Süreci

1. **Güncelleme Hazırlama:**
   - Yeni APK/IPA oluştur
   - Test et
   - Sürüm notlarını hazırla

2. **MDM'e Yükleme:**
   - Yeni versiyonu MDM'e yükle
   - Güncelleme politikasını ayarla
   - Dağıtım grubunu seç

3. **Dağıtım:**
   - Pilot gruba dağıt
   - Test et
   - Genel dağıtım

---

## Sorun Giderme

### Yaygın Sorunlar

#### 1. Bağlantı Hatası

**Belirtiler:**
- "Server URL gerekli" hatası
- "Bağlantı hatası" mesajı

**Çözümler:**
- Server URL'in doğru olduğunu kontrol et
- Ağ bağlantısını kontrol et
- VPN bağlantısını kontrol et
- Firewall kurallarını kontrol et

#### 2. Kimlik Doğrulama Hatası

**Belirtiler:**
- "Giriş başarısız" mesajı
- 401 Unauthorized hatası

**Çözümler:**
- Token'ın geçerli olduğunu kontrol et
- Token süresinin dolmadığını kontrol et
- AD kimlik bilgilerinin doğru olduğunu kontrol et
- Azure DevOps Server'da kullanıcı izinlerini kontrol et

#### 3. API Hataları

**Belirtiler:**
- 403 Forbidden hatası
- 404 Not Found hatası
- 500 Internal Server Error

**Çözümler:**
- API versiyonunu kontrol et (7.0)
- Kullanıcı izinlerini kontrol et
- Collection/Project adının doğru olduğunu kontrol et
- Azure DevOps Server loglarını kontrol et

#### 4. Sertifika Hatası

**Belirtiler:**
- SSL/TLS hata mesajları
- "Sertifika güvenilir değil" hatası

**Çözümler:**
- Sertifikanın geçerli olduğunu kontrol et
- Sertifika zincirinin tam olduğunu kontrol et
- MDM üzerinden sertifika dağıtımını kontrol et
- Cihaz saat/tarih ayarlarını kontrol et

### Log Toplama

**Android:**
```bash
adb logcat | grep azuredevops
```

**iOS:**
- Xcode → Window → Devices and Simulators
- Cihazı seç → View Device Logs

**Uygulama Logları:**
- Debug logları uygulama içinde görüntülenebilir
- Production'da log seviyesi azaltılmalıdır

---

## Destek ve İletişim

**Teknik Destek:**
- Geliştirici: Alpay Bilgiç
- E-posta: bilgicalpay@gmail.com

**Altyapı Desteği:**
- Ağ Ekibi: [Ağ Ekibi İletişim]
- Güvenlik Ekibi: [Güvenlik Ekibi İletişim]
- MDM Yöneticisi: [MDM Yöneticisi İletişim]

**Acil Durum:**
- Telefon: [Acil Durum Telefonu]
- E-posta: [Acil Durum E-postası]

---

**Son Güncelleme:** 21-12-2025  
**Dokümantasyon Versiyonu:** 1.1.4

