# Release Signing Setup for Google Play Store

Bu dosya, Google Play Store'a yüklemek için release modunda imzalanmış AAB oluşturma adımlarını içerir.

## Adım 1: Keystore Oluşturma

Eğer daha önce bir keystore oluşturmadıysanız, aşağıdaki komutu çalıştırın:

```bash
cd android/app
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Bu komut sizden şunları isteyecek:
- Keystore password (şifre)
- Key password (genellikle keystore password ile aynı olabilir)
- Ad, şirket bilgileri vb.

**ÖNEMLİ:** Bu keystore dosyasını ve şifrelerini güvenli bir yerde saklayın! Bu dosya olmadan uygulamanızı güncelleyemezsiniz.

## Adım 2: Keystore Properties Dosyası Oluşturma

1. `keystore.properties.template` dosyasını `keystore.properties` olarak kopyalayın:

```bash
cd android
cp keystore.properties.template keystore.properties
```

2. `keystore.properties` dosyasını açın ve şifrelerinizi girin:

```properties
storeFile=../app/upload-keystore.jks
keyAlias=upload
keyPassword=YOUR_KEY_PASSWORD
storePassword=YOUR_STORE_PASSWORD
```

## Adım 3: Release AAB Oluşturma

Release modunda imzalanmış AAB oluşturmak için:

```bash
cd ../..  # Proje root dizinine dönün
flutter build appbundle --release
```

Oluşturulan AAB dosyası şu konumda olacaktır:
`build/app/outputs/bundle/release/app-release.aab`

## Adım 4: Google Play Store'a Yükleme

1. Google Play Console'a giriş yapın
2. Uygulamanızı seçin
3. "Production" veya "Internal testing" bölümüne gidin
4. "Create new release" butonuna tıklayın
5. Oluşturduğunuz `app-release.aab` dosyasını yükleyin

## Sorun Giderme

### "Keystore file not found" hatası alıyorsanız:
- `keystore.properties` dosyasının `android/` dizininde olduğundan emin olun
- `storeFile` yolunun doğru olduğundan emin olun

### "Signing config not found" hatası alıyorsanız:
- `keystore.properties` dosyasındaki tüm değerlerin doğru olduğundan emin olun
- Keystore dosyasının belirtilen konumda olduğundan emin olun

### Mevcut bir keystore kullanıyorsanız:
- `keystore.properties` dosyasında mevcut keystore dosyanızın yolunu ve bilgilerini güncelleyin

