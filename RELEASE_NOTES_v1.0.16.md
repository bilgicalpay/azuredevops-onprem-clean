# Release Notes v1.0.16

**Tarih:** 24 Aralık 2025  
**Versiyon:** 1.0.16+111

## 🔧 İyileştirmeler

### Build Detail Screen
- ✅ **Scroll Sorunu Düzeltildi**: Build detail screen'de tüm içerik (timeline, stages, jobs, actions) artık düzgün şekilde scroll edilebiliyor
- ✅ LayoutBuilder ile scroll constraints düzeltildi

### Settings Ekranı
- ✅ **RDC Hizmetleri Bölümü Eklendi**: Bağış yap bölümünün üstüne RDC Hizmetleri bölümü eklendi
- ✅ RDC Partner logosu ve "Hizmetler hakkında destek almak için tıklayınız" mesajı eklendi
- ✅ https://rdc.com.tr linki ile RDC web sitesine yönlendirme

## 🆕 Yeni Özellikler

### İlk Açılış Welcome Dialog
- ✅ **Welcome Dialog**: Uygulama ilk kez açıldığında welcome dialog gösteriliyor
- ✅ **Mesaj**: "RDC Partner tarafından AzureDevOps kullanıcılarına sunulmuştur."
- ✅ **Otomatik Kapanma**: Dialog 3 saniye sonra otomatik olarak kapanıyor
- ✅ **Bir Kez Gösterilme**: Dialog bir kez gösterildikten sonra bir daha gösterilmiyor (StorageService ile kontrol)

## 🏗️ Teknik İyileştirmeler

- ✅ StorageService'e `hasShownWelcomeDialog()` ve `setHasShownWelcomeDialog()` metodları eklendi
- ✅ Build detail screen'de LayoutBuilder kullanılarak scroll sorunu düzeltildi
- ✅ WelcomeDialog widget'ı main.dart'a eklendi

## 📦 Build Bilgileri

- **Android AAB:** 48.2 MB
- **Android APK:** 61.3 MB
- **Version Code:** 111

