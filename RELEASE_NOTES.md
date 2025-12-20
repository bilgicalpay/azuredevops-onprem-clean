# Release Notes - v1.1.3 (Build 41)

**Release Date:** 2024-12-20  
**Package Name:** io.rdc.azuredevops  
**Developer:** Alpay Bilgiç (bilgicalpay@gmail.com)

## 📦 Build Files

- **Android APK:** azuredevops-1.1.3.apk
- **iOS IPA:** azuredevops-1.1.3.ipa (if available)

## 🚀 Deployment Status

- ✅ **Android:** Ready for deployment
- ✅ **iOS:** Ready for deployment

## ✨ New Features & Improvements

### Bildirim Ayarları Entegrasyonu ✅
- Bildirim ayarları artık background task service ve realtime service'de aktif olarak kullanılıyor
- **İlk Atamada Bildirim** ayarı background servislerde uygulanıyor
- **Tüm Güncellemelerde Bildirim** ayarı background servislerde uygulanıyor
- **Sadece Hotfix** filtresi background servislerde uygulanıyor
- **Grup Bildirimleri** ayarı background servislerde uygulanıyor
- Tüm bildirim filtreleri hem uygulama açıkken hem de arka planda çalışırken aktif

### Deploy Script'leri ✅
- **build_and_deploy_all.sh:** Her derleme sonrasında otomatik deploy
- **quick_deploy.sh:** Sadece deploy için (build zaten yapılmışsa)
- **build_and_deploy.sh:** iOS desteği eklendi
- Android ve iOS için otomatik build ve deploy desteği

## 🐛 Bug Fixes

### Settings Screen
- Bildirim ayarları için eksik değişken tanımlamaları düzeltildi
- Bildirim ayarları artık doğru şekilde yükleniyor ve kaydediliyor

## 🔧 Technical Improvements

### Git Yönetimi
- APK ve IPA dosyaları .gitignore'a eklendi
- Büyük binary dosyalar repository'den kaldırıldı
- Repository boyutu optimize edildi

## 📝 Documentation Updates

- ✅ **CHANGELOG.md:** v1.1.3 release notları eklendi
- ✅ **README.md:** Versiyon bilgileri güncellendi (1.1.3+41)
- ✅ **DEPLOY_README.md:** Deploy script'leri kullanım kılavuzu eklendi

## 🔒 Security

- Tüm önceki güvenlik özellikleri korunuyor
- Bildirim ayarları güvenli bir şekilde saklanıyor

## 📱 Platform Support

- ✅ **Android:** Minimum 5.0 (SDK 21), Target 14 (SDK 34)
- ✅ **iOS:** Minimum 12.0, Target 17.0

## 🔄 Migration Notes

### For Existing Users
- Bildirim ayarları otomatik olarak yüklenir
- Mevcut ayarlar korunur
- Uygulama güncellemesi sorunsuz

### For Developers
- Deploy script'leri kullanarak otomatik build ve deploy yapabilirsiniz
- `./scripts/build_and_deploy_all.sh` - Build ve deploy
- `./scripts/quick_deploy.sh` - Sadece deploy

## 📦 Files Included in Release

- azuredevops-1.1.3.apk (Android APK)
- azuredevops-1.1.3.ipa (iOS IPA - if available)
- RELEASE_NOTES.md (This file)
- CHANGELOG.md

## 🔗 Links

- **Repository:** https://github.com/bilgicalpay/azuredevops-server-mobile
- **Release:** https://github.com/bilgicalpay/azuredevops-server-mobile/releases/tag/v1.1.3

## 📞 Support

**Developer:** Alpay Bilgiç  
**Email:** bilgicalpay@gmail.com

---

## 🎯 Summary of Changes

### New Features
1. ✅ Bildirim ayarları background servislerde aktif
2. ✅ Otomatik deploy script'leri
3. ✅ Git repository optimizasyonu

### Bug Fixes
1. ✅ Settings screen değişken tanımlamaları düzeltildi
2. ✅ Bildirim ayarları yükleme/kaydetme düzeltildi

### Documentation
1. ✅ CHANGELOG güncellendi
2. ✅ README versiyon bilgileri senkronize edildi
3. ✅ Deploy kılavuzu eklendi

---

**Note:** Bu release bildirim ayarları entegrasyonunu tamamlar ve test edilmiştir. Tüm özellikler Android ve iOS platformlarında çalışmaktadır.
