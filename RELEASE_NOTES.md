# Release Notes - v1.1.4 (Build 43)

**Release Date:** 21-12-2025  
**Package Name:** io.rdc.azuredevops  
**Developer:** Alpay Bilgiç (bilgicalpay@gmail.com)

## 📦 Build Files

- **Android APK:** azuredevops-1.1.4.apk
- **iOS IPA:** azuredevops-1.1.4.ipa

## 🚀 Deployment Status

- ✅ **Android:** Ready for deployment
- ✅ **iOS:** Ready for deployment

## ✨ New Features & Improvements

### Türk Kültürü Popup Özelliği 🆕
- **Rastgele Kültür Bilgileri:** Ana sayfada pull-to-refresh yapıldığında rastgele Türk kültürü bilgileri gösterilir
- **50+ Tarihi Figür:** İbn-i Sina, Ali Kuşçu, Uluğ Bey, Farabi, Mimar Sinan, Evliya Çelebi, Katip Çelebi, Piri Reis, Cahit Arf, Aziz Sancar, Fazıl Say, Yunus Emre, Mehmet Akif Ersoy, Nazım Hikmet, Osman Hamdi Bey ve daha fazlası
- **12 Tarihi Türk Devleti:** Göktürk Kağanlığı, Uygur Kağanlığı, Karahanlılar, Gazneliler, Büyük Selçuklu İmparatorluğu, Anadolu Selçuklu Devleti, Osmanlı İmparatorluğu, Timur İmparatorluğu, Babür İmparatorluğu, Altın Orda Devleti, Harezmşahlar, Akkoyunlular
- **15 Modern Türk Cumhuriyeti:** Türkiye, Azerbaycan, Kazakistan, Kırgızistan, Özbekistan, Türkmenistan, Doğu Türkistan (Uygur Özerk Bölgesi), KKTC, Tataristan, Başkurdistan, Çuvaşistan, Saha (Yakut), Tuva, Altay, Hakasya
- **Popup Özellikleri:** Kapatılabilir (X butonu), maksimum 250 karakter içerik, bayrak emojileri ve yıllar gösterimi

### Work Item Attachments Özelliği 🆕
- **Dosya Ekleme:** Work item'lara dosya ekleme özelliği eklendi
- **Attachment Görüntüleme:** Work item attachment'larını görüntüleme özelliği eklendi
- **File Picker:** file_picker paketi ile dosya seçimi
- **Azure DevOps API:** uploadAttachment ve attachFileToWorkItem metodları eklendi
- **UI Entegrasyonu:** Attachment listesi work item detail ekranında gösterilir

### Work Item Custom Field İyileştirmeleri 🆕
- **Gizli Custom Field Filtreleme:** Gizli field'lar (isReadOnly, isLocked, isIdentity, !isQueryable) artık gösterilmiyor
- **Selectbox/Combobox Desteği:** Custom field'larda selectbox ve combobox değerleri düzenlenebilir
- **Checkbox/Tickbox Desteği:** Boolean field'lar için checkbox desteği eklendi
- **FieldDefinition İyileştirmeleri:** isHidden property eklendi ve field kontrolü iyileştirildi

### Discussion/Comments Özelliği 🆕
- **Yorum Ekleme:** Work item'lara yorum ekleme özelliği eklendi
- **Yorum Görüntüleme:** Work item yorumlarını görüntüleme özelliği eklendi
- **WorkItemComment API:** getWorkItemComments ve addWorkItemComment metodları eklendi
- **Discussion UI:** Work item detail ekranına Discussion bölümü eklendi

## 🐛 Bug Fixes

### Bildirim Ayarları
- ✅ **"Sadece bana ilk atandığında bildirim gönder" seçeneği düzeltildi**
- ✅ Bildirim kontrol mantığı BackgroundTaskService ve RealtimeService'de iyileştirildi
- ✅ Artık sadece ilk atamada bildirim gönder seçeneği doğru çalışıyor
- ✅ Bildirim filtreleme mantığı yeniden düzenlendi

### UI İyileştirmeleri
- ✅ Related work items debug kısmı temizlendi
- ✅ Gereksiz debug mesajları ve UI elementleri kaldırıldı
- ✅ Steps alanı work item detail ekranından kaldırıldı (artık gösterilmiyor)
- ✅ UI daha temiz ve kullanıcı dostu hale getirildi

## 🔧 Technical Improvements

### Work Item Service
- ✅ getWorkItemComments ve addWorkItemComment metodları eklendi
- ✅ getWorkItemAttachments, uploadAttachment ve attachFileToWorkItem metodları eklendi
- ✅ Field definition'da isHidden kontrolü eklendi
- ✅ Boolean field desteği iyileştirildi
- ✅ WorkItemComment sınıfı eklendi
- ✅ Steps parsing ve UI kodu tamamen kaldırıldı

### Dependency Updates
- ✅ file_picker: ^6.1.1 → ^8.3.7 (Flutter v2 embedding uyumluluğu için)
- ✅ package_info_plus: ^5.0.1 → ^8.3.1
- ✅ web_socket_channel: ^2.4.3 → ^3.0.3
- ✅ web: ^0.4.2 → ^1.1.1

### Background Services
- ✅ Bildirim kontrol mantığı iyileştirildi
- ✅ İlk atama kontrolü düzeltildi
- ✅ Güncelleme kontrolü iyileştirildi

## 📝 Documentation Updates

- ✅ **CHANGELOG.md:** v1.1.4 release notları eklendi
- ✅ **README.md:** Versiyon bilgileri güncellendi (1.1.4+42)
- ✅ **RELEASE_NOTES.md:** v1.1.4 release notları oluşturuldu

## 🔒 Security

- ✅ Güvenlik taraması yapıldı
- ✅ SBOM (Software Bill of Materials) oluşturuldu
- ✅ Artifact signing (Sigstore) hazır

## 📱 Platform Support

- ✅ **Android:** Minimum 5.0 (SDK 21), Target 14 (SDK 34)
- ✅ **iOS:** Minimum 12.0, Target 17.0

## 🔄 Migration Notes

Bu versiyon önceki versiyonlarla uyumludur. Herhangi bir migration işlemi gerekmez.

## 📥 Installation

### Android
1. APK dosyasını indirin
2. Cihazınızda "Bilinmeyen kaynaklardan yükleme" seçeneğini aktif edin
3. APK dosyasını açın ve yükleyin

### iOS
1. IPA dosyasını indirin
2. MDM sistemi veya TestFlight üzerinden yükleyin
3. Cihazınızda güven ayarlarını yapın

## 📋 Files Included

- `azuredevops-1.1.4.apk` - Android release APK
- `azuredevops-1.1.4.ipa` - iOS release IPA
- `sbom.json` - Software Bill of Materials (SPDX format)
- `sbom.txt` - Software Bill of Materials (text format)
- `*.sigstore` - Artifact signatures (Sigstore)

## 🐛 Known Issues

Şu anda bilinen kritik bir sorun yoktur.

## 📞 Support

Sorularınız için: bilgicalpay@gmail.com

---

**Not:** Bu release test edilmiş ve onaylanmıştır.
