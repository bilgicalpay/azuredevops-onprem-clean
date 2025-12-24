# Release Notes v1.0.15

**Tarih:** 24 Aralık 2025  
**Versiyon:** 1.0.15+117

## 🎉 Yeni Özellikler

### Release Yönetimi (Tam Entegrasyon)
- ✅ **Hiyerarşik Release Görünümü**: Projeler → Release Definitions → Releases
- ✅ **Release Definitions**: Klasör yapısında listeleme ve organize görünüm
- ✅ **Create New Release**: Release definition altından yeni release oluşturma
- ✅ **Deploy Options**:
  - **Deploy Multiple**: Tüm deploy edilebilir environment'lara toplu deploy
  - **Deploy Stage**: Belirli environment seçerek deploy
  - **Cancel**: Çalışan deployment'ları iptal etme
  - **Redeploy**: Cancel sonrası tekrar deploy etme
- ✅ **Release Logs**: Environment bazında anlık ve geçmiş log görüntüleme
- ✅ **Azure DevOps Services Desteği**: Cloud (dev.azure.com) ve On-Premise desteği
  - Otomatik endpoint detection (vsrm.dev.azure.com for Release API)
  - API version otomasyonu (6.0 for cloud, 7.0 for on-premise)

### Build Yönetimi (Geliştirilmiş)
- ✅ **Build Timeline**: Stages ve jobs görüntüleme
- ✅ **Build Logs**: Detaylı log görüntüleme
- ✅ **Build Actions**: Start, Cancel, View details

### Boards ve Work Items
- ✅ **Hiyerarşik Yapı**: Projeler → Work Item Types → Work Items
- ✅ **Create Work Item**: Proje, type ve field seçimi ile dinamik form
- ✅ **Tüm Work Items**: Sadece atanmış değil, tüm work items görüntüleme

### UI İyileştirmeleri
- ✅ **Ana Sayfa Grid**: 4 kutu (Boards, Work Items, Builds, Releases)
- ✅ **Dinamik Logo**: Server URL'den otomatik şirket adı/logo tespiti
- ✅ **Custom Logo Ayarları**: Settings'te logo display modu (Auto, Custom, Hide)

## 🔧 Düzeltmeler

- ✅ Release cancel sonrası redeploy butonu görünmüyor sorunu düzeltildi
- ✅ Azure DevOps Services için Release API endpoint düzeltmeleri
- ✅ Release API version otomasyonu (cloud vs on-premise)

## 🏗️ Teknik İyileştirmeler

- ✅ Release Service: getReleaseDefinitions, getReleasesByDefinition, getReleaseLogs metodları
- ✅ Build Service: Timeline ve logs desteği
- ✅ Board Service: Hiyerarşik yapı desteği
- ✅ Work Item Service: Create work item with dynamic fields

## 📱 Platform Desteği

- ✅ Android: Tam destek
- ✅ iOS: Tam destek (Simulator + Device)

## 🔒 Güvenlik

- ✅ Sertifika ile imzalı release build'ler
- ✅ Private key'ler asla binary içinde değil

---

**Not:** APK ve IPA dosyaları imzalı binary'lerdir ve GitHub Release'e yüklenmesi güvenlidir. Keystore ve private key'ler asla paylaşılmaz.
