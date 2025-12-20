# Changelog

Bu proje [Semantic Versioning](https://semver.org/) kullanmaktadır.

## [1.1.3] - 2024-12-20

### ✅ Test Edildi ve Onaylandı

#### Bildirim Ayarları Entegrasyonu
- ✅ Bildirim ayarları background task service ve realtime service'de test edildi ve onaylandı
- ✅ Tüm bildirim filtreleri (ilk atama, tüm güncellemeler, sadece Hotfix, grup bildirimleri) çalışıyor
- ✅ Android ve iOS platformlarında test edildi

### 🔧 İyileştirmeler

#### Deploy Script'leri
- ✅ Otomatik deploy script'leri eklendi (build_and_deploy_all.sh, quick_deploy.sh)
- ✅ Android ve iOS için otomatik build ve deploy desteği
- ✅ Her derleme sonrasında otomatik deploy yapılabilir

#### Git Yönetimi
- ✅ APK ve IPA dosyaları .gitignore'a eklendi
- ✅ Büyük binary dosyalar repository'den kaldırıldı

---

## [1.1.2] - 2024-12-20

### 🔧 İyileştirmeler

#### Bildirim Ayarları Entegrasyonu
- Bildirim ayarları artık background task service ve realtime service'de aktif olarak kullanılıyor
- **İlk Atamada Bildirim** ayarı background servislerde uygulanıyor
- **Tüm Güncellemelerde Bildirim** ayarı background servislerde uygulanıyor
- **Sadece Hotfix** filtresi background servislerde uygulanıyor
- **Grup Bildirimleri** ayarı background servislerde uygulanıyor
- Tüm bildirim filtreleri hem uygulama açıkken hem de arka planda çalışırken aktif

### 🐛 Hata Düzeltmeleri

#### Settings Screen
- Bildirim ayarları için eksik değişken tanımlamaları düzeltildi
- Bildirim ayarları artık doğru şekilde yükleniyor ve kaydediliyor

---

## [1.1.0] - 2024-12-20

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
