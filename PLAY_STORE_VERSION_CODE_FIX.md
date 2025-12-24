# Google Play Console - Version Code Hatası Çözümü

## Hata Mesajı
"Bu APK, daha yüksek sürüm koduna sahip bir veya daha fazla APK tarafından tamamen sınırlandırıldığı için hiçbir kullanıcıya sunulmayacak."

## Sorun
Release'de birden fazla APK/AAB var ve bazılarının version code'u diğerlerinden düşük. Google Play Store, düşük version code'a sahip APK'ları otomatik olarak engeller.

## Çözüm Adımları

### 1. Google Play Console'a Giriş Yapın
- [Kapalı Test Release Sayfası](https://play.google.com/console/u/0/developers/8121688757413593376/app/4972741124424744352/tracks/4699689361728791147/releases/4/review)

### 2. Release İçeriğini Kontrol Edin
- Release sayfasında tüm APK/AAB dosyalarını görüntüleyin
- Her dosyanın version code'unu kontrol edin

### 3. Düşük Version Code'lu Dosyaları Kaldırın
- Version code'u **110'dan düşük** olan TÜM APK/AAB dosyalarını kaldırın
- Sadece **version code 110** veya daha yüksek olan dosyayı bırakın

### 4. Yeni Release Oluşturun (Önerilen)
Eğer release'i düzenlemek zor ise:

1. **Mevcut release'i archive edin veya silin**
2. **Yeni release oluşturun**
3. **Sadece yeni AAB dosyasını yükleyin**:
   - Dosya: `build/app/outputs/bundle/release/app-release.aab`
   - Version: 1.0.15
   - Version Code: 110

### 5. AAB Dosyasını Yükleyin
```
build/app/outputs/bundle/release/app-release.aab
```

## Önemli Notlar

- ✅ **AAB kullanın, APK değil** (Google Play Store AAB formatını tercih eder)
- ✅ **Sadece en yüksek version code'lu dosyayı bırakın**
- ✅ **Eski release'leri archive edin** (tamamen silmeyin, geçmiş için saklayın)
- ✅ **Version code her zaman artmalı** (110, 111, 112, vb.)

## Mevcut Build Bilgileri

- **Version:** 1.0.15
- **Version Code:** 110
- **Build Dosyası:** `build/app/outputs/bundle/release/app-release.aab`
- **Boyut:** ~46 MB

## Sonraki Adımlar

1. Google Play Console'da release'i düzenleyin
2. Eski/düşük version code'lu APK'ları kaldırın
3. Yeni AAB dosyasını yükleyin (version code: 110)
4. Release'i kaydedin ve incelemeye gönderin
