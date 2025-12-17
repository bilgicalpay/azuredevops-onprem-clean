# iOS Build için Gerekli Kurulumlar

## Durum

iOS build yapmak için aşağıdaki kurulumlar gereklidir:

### ✅ Tamamlanan
- ✅ CocoaPods yüklendi (Ruby 3.4.8 ile)
- ✅ Podfile oluşturuldu
- ✅ CocoaPods bağımlılıkları yüklendi

### ❌ Eksik
- ❌ Xcode (App Store'dan yüklenmeli)
- ❌ Xcode Command Line Tools

## Kurulum Adımları

### 1. Xcode Kurulumu

1. **App Store**'u açın
2. **Xcode**'u arayın
3. **Yükle** butonuna tıklayın (yaklaşık 10-15 GB)
4. Yükleme tamamlandıktan sonra Xcode'u açın
5. Lisans sözleşmesini kabul edin

### 2. Xcode Command Line Tools

Terminal'de şu komutu çalıştırın:
```bash
xcode-select --install
```

Veya Xcode içinden:
1. Xcode > Settings > Locations
2. Command Line Tools'u seçin

### 3. Xcode Lisansını Kabul Et

```bash
sudo xcodebuild -license accept
```

### 4. Flutter iOS Setup

```bash
flutter doctor -v
flutter doctor --ios-licenses
```

## Build Komutları

Kurulum tamamlandıktan sonra:

### Development Build (Codesign olmadan)
```bash
cd ios
export PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/3.4.0/bin:$PATH"
pod install
cd ..
flutter build ios --release --no-codesign
```

### IPA Build (Codesign gerekli)
```bash
flutter build ipa --release
```

IPA dosyası şu konumda oluşur:
```
build/ios/ipa/azuredevops_onprem.ipa
```

## Alternatif: GitHub Actions

Xcode kurulumu yapmadan iOS build için GitHub Actions kullanabilirsiniz:

1. GitHub repository'nize gidin
2. Actions sekmesine tıklayın
3. "iOS Build and Release" workflow'unu seçin
4. "Run workflow" butonuna tıklayın

GitHub Actions macOS runner'ında otomatik olarak:
- Xcode yüklü
- CocoaPods yüklü
- Build yapılır
- IPA oluşturulur
- Release'e eklenir

## Notlar

- **Xcode boyutu**: ~10-15 GB
- **Kurulum süresi**: İnternet hızına bağlı olarak 1-2 saat
- **Codesigning**: Production build için Apple Developer hesabı gerekir
- **TestFlight**: TestFlight'a yüklemek için App Store Connect API key gerekir

