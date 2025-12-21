# Changelog

Bu proje [Semantic Versioning](https://semver.org/) kullanmaktadır.

## [1.1.0] - 21-12-2025

### 🆕 Yeni Özellikler

#### Bildirim Ayarları Özelleştirmesi
- **İlk Atamada Bildirim**: Sadece size ilk atandığında bildirim gönderme seçeneği
- **Tüm Güncellemelerde Bildirim**: Size atanmış work item'lar güncellendiğinde bildirim alma
- **Sadece Hotfix**: Yalnızca Hotfix tipindeki work item'lar için bildirim filtresi
- **Grup Bildirimleri**: Belirtilen gruplara atama yapıldığında bildirim alma
  - Grup adı ekleme/silme özelliği
  - Birden fazla grup tanımlama desteği
- Tüm ayarlar kalıcı olarak saklanır

#### Bildirim Geçmişi Kalıcılığı
- Daha önce bildirim gönderilmiş work item'lar için tekrar bildirim gönderilmez
- Uygulama yeniden kurulduğunda bile bildirim geçmişi korunur

### 🔧 İyileştirmeler

#### Market Dosya İndirme
- Android: Dosyalar /Download/RDC_AzureDevOps/ klasörüne indirilir
- iOS: Dosyalar Documents/RDC_AzureDevOps/ klasörüne indirilir
- Klasör yapısı korunur (ürün adı/versiyon/dosya)

### 📱 Platform Desteği
- ✅ Android
- ✅ iOS

---

## Versiyon Numaralandırma

- **MAJOR** (X.0.0): Geriye dönük uyumsuz değişiklikler
- **MINOR** (0.X.0): Yeni özellikler
- **PATCH** (0.0.X): Hata düzeltmeleri
- **BUILD** (+XX): Her build için artan sayı
