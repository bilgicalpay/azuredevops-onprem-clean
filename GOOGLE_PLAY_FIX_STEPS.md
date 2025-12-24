# Google Play Console Sorun Çözümü - Adım Adım Kılavuz

## Sorun
- "Bu sürüm, mevcut kullanıcıların yeni eklenen uygulama paketlerine geçmelerine izin vermediği için kullanıma sunulamaz."
- "Bu APK'nın hiçbir kullanıcısı, bu sürüme eklenen hiçbir yeni APK sürümüne geçemeyecek."

## Hızlı Çözüm (Manuel - Önerilen)

### 1. Closed Testing Track'i Temizle

1. [Google Play Console](https://play.google.com/console/)'a gidin
2. Uygulamanızı seçin
3. **Testing** > **Closed testing**'e gidin
4. Mevcut release'i bulun
5. **Actions** (3 nokta) > **Archive release**'e tıklayın
   - VEYA release'i tamamen silin (önerilmez, geçmiş için archive daha iyi)

### 2. Closed Testing için Yeni Release Oluştur

1. **Closed testing** sayfasında **Create new release** butonuna tıklayın
2. **AAB dosyasını yükleyin**:
   - Dosya: `build/app/outputs/bundle/release/app-release.aab`
   - Version: 1.0.15
   - Version Code: 110
3. **Release name** (isteğe bağlı): `v1.0.15`
4. **Release notes** (isteğe bağlı):
   ```
   Release v1.0.15 (Version Code: 110)
   
   Yeni Özellikler:
   - Release Management geliştirmeleri
   - Build stage log görüntüleme
   - Boards ve Work Items iyileştirmeleri
   ```
5. **Save** butonuna tıklayın
6. **Review release** sayfasında kontrol edin
7. **Start rollout to closed testing** butonuna tıklayın

### 3. Alpha Track'i Temizle ve Yeni Release Oluştur

1. **Testing** > **Alpha**'ya gidin
2. Mevcut release'i **Archive** edin
3. **Create new release** butonuna tıklayın
4. **Aynı AAB dosyasını yükleyin**: `build/app/outputs/bundle/release/app-release.aab`
5. Release notes ekleyin (isteğe bağlı)
6. **Save** > **Review release** > **Start rollout to alpha**

## Otomatik Çözüm (Fastlane)

### Ön Gereksinimler

1. **Ruby** kurulu olmalı
2. **Bundler** kurulu olmalı (`gem install bundler`)
3. **Google Play Console API** erişimi

### Kurulum

```bash
cd fastlane
bundle install
```

İlk çalıştırmada Fastlane sizden Google Play Console OAuth2 credentials isteyecek.

### Kullanım

```bash
# Önce AAB build alın (eğer yoksa)
flutter build appbundle --release

# Fastlane ile yükle
cd fastlane
fastlane upload_testing
```

## Otomatik Çözüm (Python Script)

### Ön Gereksinimler

1. **Python 3** kurulu olmalı
2. **Google API kütüphaneleri**:
   ```bash
   pip install google-api-python-client google-auth-httplib2 google-auth-oauthlib
   ```
3. **Service Account Key JSON** dosyası (Google Cloud Console'dan)

### Kullanım

```bash
# Service account key dosyasını belirtin
export GOOGLE_PLAY_SERVICE_ACCOUNT_JSON="service-account-key.json"

# Script'i çalıştırın
python3 scripts/upload_to_play_store.py
```

Detaylı kurulum: `GOOGLE_PLAY_API_SETUP.md`

## Mevcut Build Bilgileri

- **Version:** 1.0.15
- **Version Code:** 110
- **AAB Dosyası:** `build/app/outputs/bundle/release/app-release.aab`
- **Boyut:** ~46 MB
- **Package Name:** `com.higgscloud.azuredevops`

## Önemli Notlar

✅ **Sadece AAB kullanın**, APK kullanmayın  
✅ **Eski release'leri archive edin** (tamamen silmeyin)  
✅ **Her track için ayrı release oluşturun**  
✅ **Version code her zaman artmalı** (110, 111, 112, ...)  
⚠️ **APK/AAB format karıştırmayın** - Tüm release'lerde aynı format kullanın

## Sorun Giderme

### "Version code already exists"
Çözüm: Version code'u artırın (`pubspec.yaml`'da `version: 1.0.15+111`)

### "This APK has no users"
Çözüm: Eski release'leri archive edin, sadece yeni AAB'yi yükleyin

### "No APK or AAB uploaded"
Çözüm: Release oluştururken mutlaka AAB dosyasını yükleyin

## Hangi Yöntemi Seçmeliyim?

1. **Manuel (Web UI)**: En hızlı, hiçbir kurulum gerektirmez ✅ ÖNERİLEN
2. **Fastlane**: Otomasyon için iyi, biraz kurulum gerektirir
3. **Python Script**: Tam kontrol, service account gerektirir

## Kontrol Listesi

- [ ] Closed testing track'indeki eski release'i archive ettim
- [ ] Alpha track'indeki eski release'i archive ettim
- [ ] Yeni release oluşturdum (Closed testing)
- [ ] AAB dosyasını yükledim (version code: 110)
- [ ] Release'i kaydettim ve rollout başlattım
- [ ] Alpha track'i için de aynı işlemi yaptım

