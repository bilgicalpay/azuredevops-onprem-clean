# Changelog

Bu proje [Semantic Versioning](https://semver.org/) kullanmaktadır.

## [1.1.4] - 21-12-2025

### 🆕 Yeni Özellikler

#### Türk Kültürü Popup Özelliği
- ✅ Ana sayfada pull-to-refresh yapıldığında rastgele Türk kültürü bilgileri gösterilir
- ✅ 50+ Türk tarihi figürü (bilim, sanat, edebiyat alanlarından)
- ✅ 12 tarihi Türk devleti (Göktürk, Selçuklu, Osmanlı, vb.)
- ✅ 15 modern Türk cumhuriyeti ve aktif Türk devleti (Türkiye, Azerbaycan, Kazakistan, Kırgızistan, Özbekistan, Türkmenistan, Uygur Özerk Bölgesi, KKTC, ve Rusya içindeki özerk Türk cumhuriyetleri)
- ✅ Popup kapatılabilir (X butonu ve "Kapat" butonu)
- ✅ İçerik maksimum 250 karakter ile sınırlandırılmıştır
- ✅ TurkishCultureService servisi eklendi

#### Work Item Attachments Özelliği
- ✅ Work item'lara dosya ekleme özelliği eklendi
- ✅ Work item attachment'larını görüntüleme özelliği eklendi
- ✅ File picker entegrasyonu (file_picker paketi)
- ✅ Azure DevOps API'ye dosya yükleme desteği
- ✅ Attachment listesi work item detail ekranında gösterilir

#### Work Item Custom Field İyileştirmeleri
- ✅ Gizli custom field'lar filtrelendi (isHidden kontrolü eklendi)
- ✅ Selectbox, combobox, tickbox custom field'ları düzenlenebilir hale getirildi
- ✅ Boolean field'lar için checkbox/tickbox desteği eklendi
- ✅ FieldDefinition sınıfına isHidden property eklendi

#### Discussion/Comments Özelliği
- ✅ Work item'lara yorum ekleme özelliği eklendi
- ✅ Work item yorumlarını görüntüleme özelliği eklendi
- ✅ WorkItemComment sınıfı ve API metodları eklendi
- ✅ Discussion UI'ı work item detail ekranına eklendi

### 🐛 Hata Düzeltmeleri

#### Bildirim Ayarları
- ✅ "Sadece bana ilk atandığında bildirim gönder" seçeneği düzeltildi
- ✅ Bildirim kontrol mantığı BackgroundTaskService ve RealtimeService'de iyileştirildi
- ✅ Artık sadece ilk atamada bildirim gönder seçeneği doğru çalışıyor

#### UI İyileştirmeleri
- ✅ Related work items debug kısmı temizlendi
- ✅ Gereksiz debug mesajları ve UI elementleri kaldırıldı
- ✅ Steps alanı work item detail ekranından kaldırıldı (artık gösterilmiyor)

### 🔧 İyileştirmeler

#### Work Item Service
- ✅ getWorkItemComments ve addWorkItemComment metodları eklendi
- ✅ getWorkItemAttachments, uploadAttachment ve attachFileToWorkItem metodları eklendi
- ✅ Field definition'da isHidden kontrolü eklendi
- ✅ Boolean field desteği iyileştirildi
- ✅ Steps parsing ve UI kodu tamamen kaldırıldı

#### Dependency Updates
- ✅ file_picker: ^6.1.1 → ^8.3.7 (Flutter v2 embedding uyumluluğu için)
- ✅ package_info_plus: ^5.0.1 → ^8.3.1
- ✅ web_socket_channel: ^2.4.3 → ^3.0.3
- ✅ web: ^0.4.2 → ^1.1.1

---

## [1.1.3] - 21-12-2025

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

## [1.1.2] - 21-12-2025

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
