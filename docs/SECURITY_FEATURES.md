# Güvenlik Özellikleri Dokümantasyonu

**Son Güncelleme:** 21-12-2025  
**Versiyon:** 1.1.4+43

## Genel Bakış

Bu dokümantasyon, Azure DevOps Server 2022 Mobil Uygulaması'nda uygulanan güvenlik özelliklerini, son geliştirmeleri ve önemli yapılandırma notlarını açıklar.

## 🔒 Uygulanan Güvenlik Özellikleri

### 1. Certificate Pinning

**Durum:** ✅ Uygulandı (Production Hazır)

Certificate pinning, uygulamanın yalnızca belirli SSL/TLS sertifikalarına sahip sunucularla iletişim kurmasını sağlayarak man-in-the-middle (MITM) saldırılarını önler.

#### Uygulama Detayları:
- **Service:** `lib/services/certificate_pinning_service.dart`
- **Method:** SHA-256 fingerprint doğrulama
- **Aktivasyon:** Production build'lerde otomatik olarak etkin (`PRODUCTION=true`)
- **Manuel Test:** `ENABLE_CERT_PINNING=true` flag'i kullanın

#### Gerekli Yapılandırma:
1. Azure DevOps Server'ınızdan certificate fingerprint'lerini çıkarın:
   ```bash
   ./scripts/extract_certificate_fingerprints.sh https://your-azure-devops-server.com
   ```

2. Fingerprint'leri `lib/services/certificate_pinning_service.dart` dosyasına ekleyin:
   ```dart
   static const List<String> _allowedFingerprints = [
     'SHA256:AB:CD:EF:...',  // Your Azure DevOps Server
   ];
   ```

#### Önemli Notlar:
- ⚠️ **Certificate fingerprint'leri production deployment'tan önce eklenmelidir**
- ⚠️ **Sunucu sertifikaları yenilendiğinde fingerprint'ler güncellenmelidir**
- ✅ Development build'ler fingerprint olmadan normal çalışır (pinning devre dışı)
- ✅ Production build'ler fingerprint eksikse ve pinning etkinse başarısız olur

#### Dokümantasyon:
- Kurulum Kılavuzu: `scripts/setup_certificate_pinning.md`
- Extraction Script: `scripts/extract_certificate_fingerprints.sh`

---

### 2. Root/Jailbreak Detection

**Durum:** ✅ Uygulandı

Cihazın root edilmiş (Android) veya jailbreak yapılmış (iOS) olup olmadığını tespit eden cihaz güvenlik kontrolleri.

#### Uygulama Detayları:
- **Service:** `lib/services/security_service.dart`
- **Package:** `flutter_root_jailbreak_checker: ^2.0.1`
- **Method:** `checkOfflineIntegrity()` (API v2.0+)
- **Kontrol Zamanı:** Uygulama başlangıcında

#### API Kullanımı:
```dart
final checker = FlutterRootJailbreakChecker();
final result = await checker.checkOfflineIntegrity();
final isCompromised = result.isRooted || result.isJailbroken;
```

#### Davranış:
- ✅ Uygulama başlangıcında cihaz güvenliğini kontrol eder
- ✅ Güvenlik olaylarını loglar (uygulama kullanımını engellemez)
- ✅ Hata yönetimi: Hata durumunda cihazı güvenli varsayar (meşru kullanıcıları engellememek için)

#### Önemli Notlar:
- ⚠️ **Package API v2.0+ sürümünde değişti**: `checkOfflineIntegrity()` metodunu kullanın
- ⚠️ **Instance-based**: Metodu çağırmadan önce instance oluşturun
- ✅ **Non-blocking**: Cihaz güvenliği ihlal edilse bile uygulama çalışmaya devam eder (izleme için loglanır)

**Not:** Şu anda geçici olarak devre dışı bırakılmıştır (package derleme hatası nedeniyle). Gelecekte yeniden etkinleştirilecektir.

---

### 3. Automatic Token Refresh

**Durum:** ✅ Uygulandı (PAT'ler için kavramsal)

Kimlik doğrulama token'larının geçerli kalmasını sağlamak için otomatik token yenileme mekanizması.

#### Uygulama Detayları:
- **Service:** `lib/services/token_refresh_service.dart`
- **Kontrol Zamanı:** Uygulama başlangıcında
- **Expiry Buffer:** Token süresi dolmadan 5 dakika önce

#### Mevcut Uygulama:
- ✅ Token süresi kontrolü
- ✅ Otomatik yenileme tetikleme
- ⚠️ **PAT Limitation:** Azure DevOps PAT'ler refresh token'a sahip değildir
- ⚠️ **Placeholder:** Gerçek yenileme mantığı auth method'una göre uygulanmalıdır

#### Depolama:
- Token süresi `StorageService` aracılığıyla `SharedPreferences`'da saklanır
- Metodlar: `getTokenExpiry()`, `setTokenExpiry()`

#### Önemli Notlar:
- ⚠️ **PAT Yenileme Uygulanmadı:** Azure DevOps PAT'ler manuel token oluşturma gerektirir
- ⚠️ **Gelecek Geliştirme:** OAuth2 veya diğer auth method'ları için yenileme uygulanmalıdır
- ✅ **Süre Takibi:** Şu anda token süresi durumunu takip eder ve loglar

---

### 4. Security Logging

**Durum:** ✅ Uygulandı

İzleme ve denetim için merkezi güvenlik olayı loglama.

#### Uygulama Detayları:
- **Service:** `lib/services/security_service.dart`
- **Package:** `logging: ^1.3.0`
- **Log Seviyeleri:** INFO, WARNING, SEVERE

#### Loglanan Olaylar:
- ✅ Kimlik doğrulama olayları (`logAuthentication`)
- ✅ Token işlemleri (`logTokenOperation`)
- ✅ API çağrıları (`logApiCall`)
- ✅ Hassas veri erişimi (`logSensitiveDataAccess`)
- ✅ Güvenlik olayları (`logSecurityEvent`)

#### Kullanım Örneği:
```dart
SecurityService.logAuthentication('Token login attempt', details: {'serverUrl': serverUrl});
SecurityService.logTokenOperation('Token stored', success: true);
SecurityService.logApiCall('/api/projects', method: 'GET', statusCode: 200);
```

#### Önemli Notlar:
- ✅ **Merkezi:** Tüm güvenlik olayları `SecurityService` aracılığıyla loglanır
- ✅ **Seviye tabanlı:** Farklı önem dereceleri için farklı log seviyeleri
- ⚠️ **Production Entegrasyonu:** TODO: Güvenlik izleme servisi ile entegre edilmeli
- ✅ **Console Çıktısı:** Debug mode'da console'a loglar (WARNING+)

---

## 🔧 Entegrasyon Noktaları

### Ana Uygulama (`lib/main.dart`)

Tüm güvenlik servisleri uygulama başlangıcında başlatılır:

```dart
// Önce güvenlik servisini başlat
await SecurityService.initialize();

// Cihaz güvenliğini kontrol et
final isCompromised = await SecurityService.isDeviceCompromised();

// Token'ın geçerli olduğundan emin ol
await TokenRefreshService.ensureValidToken(storage);
```

### API Servisleri

Tüm API çağrıları certificate pinning kullanır:

- `lib/services/auth_service.dart` - `CertificatePinningService.createSecureDio()` kullanır
- `lib/services/work_item_service.dart` - `CertificatePinningService.createSecureDio()` kullanır
- `lib/services/wiki_service.dart` - `CertificatePinningService.createSecureDio()` kullanır

### Storage Service

Token süresi takibi:

- `lib/services/storage_service.dart` - Metodlar: `getTokenExpiry()`, `setTokenExpiry()`

---

## 📋 CI/CD Entegrasyonu

Tüm güvenlik özellikleri CI/CD pipeline'larına entegre edilmiştir:

### GitHub Actions
- ✅ Build komutlarında `PRODUCTION=true` flag'i
- ✅ Workflow'da güvenlik kontrolleri
- ✅ SBOM oluşturma
- ✅ Güvenlik denetim raporları

### GitLab CI
- ✅ Build komutlarında `PRODUCTION=true` flag'i
- ✅ Güvenlik tarama aşamaları

### Jenkins
- ✅ Build komutlarında `PRODUCTION=true` flag'i
- ✅ Güvenlik denetim işleri

---

## 🚨 Önemli Güvenlik Notları

### Certificate Pinning
1. **Fingerprint Yapılandırması Gerekli:** Production'dan önce sunucu fingerprint'lerini eklemelisiniz
2. **Certificate Yenileme:** Sertifikalar yenilendiğinde fingerprint'leri güncelleyin
3. **Çoklu Sertifikalar:** Zincirdeki tüm sertifikaları ekleyin (sunucu, load balancer, CDN)

### Root/Jailbreak Detection
1. **Non-Blocking:** Cihaz güvenliği ihlal edilse bile uygulama çalışmaya devam eder
2. **İzleme:** Güvenlik olayları araştırma için loglanır
3. **Production Düşüncesi:** Güvenliği ihlal edilmiş cihazlarda uygulama kullanımını engellemek isteyebilirsiniz

### Token Refresh
1. **PAT Limitation:** Azure DevOps PAT'ler refresh token'ı desteklemez
2. **Manuel Token Oluşturma:** Kullanıcılar süresi dolduğunda yeni PAT oluşturmalıdır
3. **Gelecek Geliştirme:** OAuth2 veya diğer auth method'ları için uygulanmalıdır

### Security Logging
1. **Production Entegrasyonu:** TODO: Logları güvenlik izleme servisine gönderin
2. **Log Saklama:** Log saklama politikalarını düşünün
3. **Gizlilik:** Hassas verilerin loglanmadığından emin olun

---

## 📚 İlgili Dokümantasyon

- **Certificate Pinning Kurulumu:** `scripts/setup_certificate_pinning.md`
- **Güvenlik Denetimi:** `security/security_audit.md`
- **Güvenlik Raporu:** `security/security_report.md`
- **Güvenlik Uygulama Raporu:** `security/security_implementation_report.md`
- **Kapsamlı Denetim:** `security/comprehensive_audit.md`

---

## 🔄 Son Değişiklikler (v1.0.20+)

### Certificate Pinning
- ✅ Fingerprint extraction script düzeltildi (colon formatı korunuyor)
- ✅ Kapsamlı kurulum dokümantasyonu eklendi
- ✅ Hata yönetimi ve uyarılar iyileştirildi
- ✅ Manuel test için `ENABLE_CERT_PINNING` flag'i eklendi

### Root/Jailbreak Detection
- ✅ `flutter_root_jailbreak_checker` v2.0+ için API kullanımı düzeltildi
- ✅ `checkOfflineIntegrity()` metodunu kullanacak şekilde güncellendi
- ✅ Hata yönetimi iyileştirildi
- ⚠️ Geçici olarak devre dışı bırakıldı (package derleme hatası nedeniyle)

### Security Logging
- ✅ Tüm kimlik doğrulama akışlarına entegre edildi
- ✅ API çağrıları için loglama eklendi
- ✅ Token işlemleri için loglama eklendi

---

## 📞 Destek

Güvenlik ile ilgili sorunlar veya sorular için:
- Güvenlik uygulama raporunu inceleyin: `security/security_implementation_report.md`
- Güvenlik denetimini kontrol edin: `security/security_audit.md`
- Güvenlik kontrollerini çalıştırın: `./scripts/security_checks.sh`

---

**Geliştirici:** Alpay Bilgiç  
**E-posta:** bilgicalpay@gmail.com  
**Son Güncelleme:** 2025-12-18
