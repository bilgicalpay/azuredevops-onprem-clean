# MDM Entegrasyon Kılavuzu

**Uygulama:** Azure DevOps Server 2022 Mobile App  
**Geliştirici:** Alpay Bilgiç  
**Versiyon:** 1.1.4+43  
**Tarih:** 21-12-2025

## İçindekiler

1. [MDM Genel Bakış](#mdm-genel-bakış)
2. [Microsoft Intune Entegrasyonu](#microsoft-intune-entegrasyonu)
3. [VMware Workspace ONE Entegrasyonu](#vmware-workspace-one-entegrasyonu)
4. [Genel MDM Yapılandırması](#genel-mdm-yapılandırması)
5. [Yapılandırma Profilleri](#yapılandırma-profilleri)
6. [Uyumluluk Politikaları](#uyumluluk-politikaları)
7. [Dağıtım Senaryoları](#dağıtım-senaryoları)

---

## MDM Genel Bakış

### Desteklenen MDM Platformları

Bu uygulama aşağıdaki MDM platformları ile uyumludur:

- **Microsoft Intune** (Önerilen)
- **VMware Workspace ONE**
- **MobileIron**
- **IBM MaaS360**
- **SOTI MobiControl**
- **Diğer standart MDM sistemleri**

### MDM Özellikleri

Uygulama aşağıdaki MDM özelliklerini destekler:

- ✅ Uygulama dağıtımı (APK/IPA)
- ✅ Uygulama yapılandırması (Managed App Configuration)
- ✅ Cihaz uyumluluk kontrolü
- ✅ Uzaktan silme (Remote Wipe)
- ✅ VPN yapılandırması
- ✅ Sertifika dağıtımı
- ✅ Uygulama güncelleme yönetimi

---

## Microsoft Intune Entegrasyonu

### Uygulama Bilgileri

**Android:**
- Package Name: `io.rdc.azuredevops`
- Minimum SDK: 21
- Target SDK: 34

**iOS:**
- Bundle ID: `io.rdc.azuredevops`
- Minimum iOS: 12.0
- Target iOS: 17.0

### Android Enterprise Yapılandırması

#### 1. Uygulama Ekleme

1. **Intune Admin Center** → **Apps** → **Android**
2. **Add** → **Line-of-business app**
3. APK dosyasını yükle
4. Uygulama bilgilerini doldur:
   - Name: Azure DevOps Mobile
   - Description: Azure DevOps Server 2022 Mobile App
   - Publisher: RDC Partner
   - Minimum operating system: Android 5.0

#### 2. Yapılandırma Profili Oluşturma

**App Configuration Policy:**

```json
{
  "server_url": "https://devops.example.com",
  "collection": "DefaultCollection",
  "require_vpn": true,
  "certificate_pinning": false,
  "auto_logout_minutes": 30,
  "require_device_encryption": true,
  "block_rooted_devices": true
}
```

**Adımlar:**
1. **Apps** → **App configuration policies** → **Add**
2. Platform: **Android**
3. Profile type: **Managed apps**
4. Target app: **Azure DevOps Mobile**
5. Configuration settings: JSON yapılandırmasını ekle

#### 3. Uyumluluk Politikası

**Önerilen Politikalar:**

1. **Device Health:**
   - Rooted devices: Block
   - Minimum OS version: Android 5.0

2. **Device Properties:**
   - Device encryption: Require
   - Minimum password length: 6

3. **System Security:**
   - Require device lock: Yes
   - Lock screen timeout: 5 minutes

#### 4. Dağıtım

1. **Apps** → **Azure DevOps Mobile** → **Properties**
2. **Assignments** → **Add group**
3. Dağıtım grubunu seç
4. Assignment type: **Required**
5. **Save**

### iOS Yapılandırması

#### 1. Uygulama Ekleme

1. **Intune Admin Center** → **Apps** → **iOS**
2. **Add** → **Line-of-business app**
3. IPA dosyasını yükle
4. Uygulama bilgilerini doldur

#### 2. Yapılandırma Profili

**App Configuration Policy (XML):**

```xml
<dict>
  <key>server_url</key>
  <string>https://devops.example.com</string>
  <key>collection</key>
  <string>DefaultCollection</string>
  <key>require_vpn</key>
  <true/>
  <key>certificate_pinning</key>
  <false/>
  <key>auto_logout_minutes</key>
  <integer>30</integer>
  <key>require_device_encryption</key>
  <true/>
  <key>block_jailbroken_devices</key>
  <true/>
</dict>
```

**Adımlar:**
1. **Apps** → **App configuration policies** → **Add**
2. Platform: **iOS/iPadOS**
3. Profile type: **Managed apps**
4. Target app: **Azure DevOps Mobile**
5. Configuration settings: XML yapılandırmasını ekle

#### 3. Uyumluluk Politikası

**Önerilen Politikalar:**

1. **Device Health:**
   - Jailbroken devices: Block
   - Minimum OS version: iOS 12.0

2. **Device Properties:**
   - Device encryption: Require
   - Passcode required: Yes
   - Minimum passcode length: 6

---

## VMware Workspace ONE Entegrasyonu

### Android Yapılandırması

#### 1. Uygulama Ekleme

1. **Workspace ONE UEM Console** → **Apps** → **Native**
2. **Add Application** → **Internal**
3. APK dosyasını yükle
4. Uygulama bilgilerini doldur

#### 2. Yapılandırma Ayarları

**App Configuration:**

```json
{
  "server_url": "https://devops.example.com",
  "collection": "DefaultCollection",
  "require_vpn": true,
  "auto_logout_minutes": 30
}
```

**Adımlar:**
1. Uygulama → **App Configuration**
2. **Add Configuration**
3. JSON yapılandırmasını ekle

#### 3. Dağıtım

1. Uygulama → **Assignment**
2. **Add Assignment**
3. Smart Group seç
4. Installation: **Auto Install**
5. **Save & Publish**

### iOS Yapılandırması

#### 1. Uygulama Ekleme

1. **Workspace ONE UEM Console** → **Apps** → **Native**
2. **Add Application** → **Internal**
3. IPA dosyasını yükle

#### 2. Yapılandırma Ayarları

**App Configuration (XML):**

```xml
<dict>
  <key>server_url</key>
  <string>https://devops.example.com</string>
  <key>collection</key>
  <string>DefaultCollection</string>
</dict>
```

---

## Genel MDM Yapılandırması

### Yapılandırma Parametreleri

#### Zorunlu Parametreler

- **server_url** (String): Azure DevOps Server URL'si
  - Örnek: `https://devops.example.com`

#### Opsiyonel Parametreler

- **collection** (String): Collection adı
  - Örnek: `DefaultCollection`

- **default_project** (String): Varsayılan proje adı
  - Örnek: `MyProject`

- **wiki_url** (String): Varsayılan wiki URL'si
  - Örnek: `https://devops.example.com/Collection/Project/_wiki/wikis/Wiki/1/README`

#### Güvenlik Parametreleri

- **require_vpn** (Boolean): VPN zorunluluğu
  - Varsayılan: `false`

- **certificate_pinning** (Boolean): Sertifika pinning aktif
  - Varsayılan: `false`
  - Not: Henüz uygulanmamıştır

- **auto_logout_minutes** (Integer): Otomatik logout süresi (dakika)
  - Varsayılan: `30`
  - Not: Henüz uygulanmamıştır

- **require_device_encryption** (Boolean): Cihaz şifreleme zorunluluğu
  - Varsayılan: `false`
  - Not: MDM tarafında kontrol edilir

- **block_rooted_devices** (Boolean): Root/jailbreak cihazları engelle
  - Varsayılan: `false`
  - Not: Henüz uygulanmamıştır

### Yapılandırma Formatları

#### JSON (Android)

```json
{
  "server_url": "https://devops.example.com",
  "collection": "DefaultCollection",
  "require_vpn": true,
  "auto_logout_minutes": 30
}
```

#### XML (iOS)

```xml
<dict>
  <key>server_url</key>
  <string>https://devops.example.com</string>
  <key>collection</key>
  <string>DefaultCollection</string>
  <key>require_vpn</key>
  <true/>
  <key>auto_logout_minutes</key>
  <integer>30</integer>
</dict>
```

#### Key-Value Pairs (Alternatif)

```
server_url=https://devops.example.com
collection=DefaultCollection
require_vpn=true
auto_logout_minutes=30
```

---

## Yapılandırma Profilleri

### Android Enterprise

**Örnek Yapılandırma:**

```json
{
  "app_config": {
    "server_url": "https://devops.example.com",
    "collection": "DefaultCollection",
    "default_project": "MyProject",
    "wiki_url": "https://devops.example.com/Collection/Project/_wiki/wikis/Wiki/1/README",
    "require_vpn": true,
    "certificate_pinning": false,
    "auto_logout_minutes": 30,
    "require_device_encryption": true,
    "block_rooted_devices": true
  }
}
```

### iOS Configuration Profile

**Örnek Yapılandırma:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>server_url</key>
  <string>https://devops.example.com</string>
  <key>collection</key>
  <string>DefaultCollection</string>
  <key>default_project</key>
  <string>MyProject</string>
  <key>wiki_url</key>
  <string>https://devops.example.com/Collection/Project/_wiki/wikis/Wiki/1/README</string>
  <key>require_vpn</key>
  <true/>
  <key>certificate_pinning</key>
  <false/>
  <key>auto_logout_minutes</key>
  <integer>30</integer>
  <key>require_device_encryption</key>
  <true/>
  <key>block_jailbroken_devices</key>
  <true/>
</dict>
</plist>
```

---

## Uyumluluk Politikaları

### Önerilen Politikalar

#### 1. Cihaz Güvenliği

**Android:**
- Device encryption: Required
- Minimum password length: 6
- Screen lock timeout: 5 minutes
- Root detection: Block

**iOS:**
- Device encryption: Required
- Passcode required: Yes
- Minimum passcode length: 6
- Jailbreak detection: Block

#### 2. Uygulama Güvenliği

- App data encryption: Required
- App transfer restrictions: Enabled
- Screen capture: Allowed (opsiyonel olarak engellenebilir)

#### 3. Ağ Güvenliği

- VPN required: Yes (opsiyonel)
- Certificate validation: Required
- Certificate pinning: Recommended

---

## Dağıtım Senaryoları

### Senaryo 1: Pilot Dağıtım

**Hedef:** Küçük bir kullanıcı grubu (10-20 kullanıcı)

**Adımlar:**
1. Pilot kullanıcı grubu oluştur
2. Uygulamayı pilot gruba dağıt
3. 1-2 hafta test et
4. Geri bildirim topla
5. Gerekli düzeltmeleri yap
6. Genel dağıtıma geç

### Senaryo 2: Aşamalı Dağıtım

**Hedef:** Tüm kullanıcılar (aşamalı olarak)

**Adımlar:**
1. İlk aşama: %25 kullanıcı
2. İkinci aşama: %50 kullanıcı
3. Üçüncü aşama: %75 kullanıcı
4. Son aşama: %100 kullanıcı

### Senaryo 3: Zorunlu Dağıtım

**Hedef:** Tüm kullanıcılar (tek seferde)

**Adımlar:**
1. Uygulamayı tüm kullanıcılara dağıt
2. Installation: Required
3. Kullanıcı eğitimi sağla
4. Destek kanallarını hazırla

---

## Sorun Giderme

### Yaygın Sorunlar

#### 1. Yapılandırma Uygulanmıyor

**Belirtiler:**
- Uygulama yapılandırma parametreleri görünmüyor
- Varsayılan değerler kullanılıyor

**Çözümler:**
- MDM yapılandırma profilinin doğru formatta olduğunu kontrol et
- Uygulama hedeflemesinin doğru olduğunu kontrol et
- Cihazın MDM'e kayıtlı olduğunu kontrol et
- Uygulamayı yeniden yükle

#### 2. Uygulama Yüklenmiyor

**Belirtiler:**
- Uygulama cihazda görünmüyor
- Yükleme hatası mesajları

**Çözümler:**
- APK/IPA dosyasının geçerli olduğunu kontrol et
- Cihaz uyumluluğunu kontrol et
- MDM loglarını kontrol et
- Cihaz depolama alanını kontrol et

#### 3. VPN Bağlantısı Çalışmıyor

**Belirtiler:**
- Uygulama Azure DevOps Server'a bağlanamıyor
- VPN bağlantı hatası

**Çözümler:**
- VPN yapılandırmasını kontrol et
- VPN profili dağıtımını kontrol et
- Ağ bağlantısını kontrol et
- Firewall kurallarını kontrol et

---

## Destek ve İletişim

**MDM Yöneticisi:**
- E-posta: [MDM Yöneticisi E-postası]
- Telefon: [MDM Yöneticisi Telefonu]

**Teknik Destek:**
- Geliştirici: Alpay Bilgiç
- E-posta: bilgicalpay@gmail.com

---

**Son Güncelleme:** 21-12-2025  
**Dokümantasyon Versiyonu:** 1.1.4

