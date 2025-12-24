# Fastlane ile Google Play Store'a Yükleme

Fastlane, Google Play Console API'sini otomatik olarak yönetir ve daha kolay kullanım sağlar.

## Kurulum

### 1. Ruby ve Bundler Kurulumu

```bash
# Ruby kontrolü
ruby --version

# Bundler kurulumu (eğer yoksa)
gem install bundler
```

### 2. Fastlane Kurulumu

```bash
cd fastlane
bundle install
```

### 3. Google Play Console API İzinleri

Fastlane, Google Play Console API'sini kullanır. Service account yerine OAuth2 kullanır:

1. [Google Cloud Console](https://console.cloud.google.com/)'a gidin
2. Bir proje seçin
3. **APIs & Services** > **Credentials**'e gidin
4. **Create Credentials** > **OAuth client ID** seçin
5. Application type: **Desktop app**
6. OAuth client oluşturun
7. JSON dosyasını indirin

### 4. Fastlane İlk Kurulum

```bash
cd fastlane
fastlane fastlane init
```

İlk çalıştırmada Fastlane sizden OAuth2 credentials isteyecek.

## Kullanım

### Alpha ve Closed Testing Track'lerine Yükleme

```bash
# Önce AAB build alın
flutter build appbundle --release

# Fastlane ile yükle
cd fastlane
fastlane upload_testing

# Veya direkt AAB path belirterek
fastlane upload_testing aab:../build/app/outputs/bundle/release/app-release.aab
```

## Manuel Yükleme (Alternatif - Daha Hızlı)

Eğer Fastlane kurulumu zaman alıyorsa, Google Play Console web arayüzünden:

### Adım 1: Mevcut Release'leri Temizle

1. [Google Play Console](https://play.google.com/console/) > **Testing** > **Closed testing**
2. Mevcut release'i bulun
3. **Archive** butonuna tıklayın (veya **Delete** edin)
4. **Testing** > **Alpha** için de aynısını yapın

### Adım 2: Yeni Release Oluştur - Closed Testing

1. **Testing** > **Closed testing**'e gidin
2. **Create new release** butonuna tıklayın
3. **AAB dosyasını yükleyin**: `build/app/outputs/bundle/release/app-release.aab`
4. Release notes ekleyin (isteğe bağlı):
   ```
   Release v1.0.15
   - Release Management özellikleri
   - Build stage log görüntüleme
   - Boards ve Work Items iyileştirmeleri
   ```
5. **Save** butonuna tıklayın
6. **Review release** > **Start rollout to closed testing**

### Adım 3: Yeni Release Oluştur - Alpha

1. **Testing** > **Alpha**'ya gidin
2. **Create new release** butonuna tıklayın
3. **AAB dosyasını yükleyin**: `build/app/outputs/bundle/release/app-release.aab`
4. Release notes ekleyin (isteğe bağlı)
5. **Save** butonuna tıklayın
6. **Review release** > **Start rollout to alpha**

## Önemli Notlar

- ✅ **Sadece AAB kullanın**, APK kullanmayın
- ✅ **Eski release'leri archive edin** (tamamen silmeyin)
- ✅ **Her track için ayrı release oluşturun**
- ✅ **Version code her zaman artmalı** (110, 111, 112, ...)

## Troubleshooting

### "You need to have at least one APK or AAB uploaded"

Çözüm: Release oluştururken mutlaka AAB dosyasını yükleyin

### "Version code already exists"

Çözüm: Version code'u artırın (`pubspec.yaml`'da `version: 1.0.15+111`)

### "This version cannot be released because it doesn't allow migration"

Çözüm: Eski release'leri archive edin, sadece AAB kullanın

