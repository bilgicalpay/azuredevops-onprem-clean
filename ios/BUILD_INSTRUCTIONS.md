# iOS Build Talimatları

## Gereksinimler

1. **Xcode** (App Store'dan yükleyin)
2. **CocoaPods** (iOS bağımlılık yöneticisi)
3. **Flutter SDK** (zaten yüklü)

## Kurulum Adımları

### 1. CocoaPods Kurulumu

```bash
sudo gem install cocoapods
```

### 2. CocoaPods Bağımlılıklarını Yükle

```bash
cd ios
pod install
cd ..
```

### 3. iOS Build

#### Development Build (Codesign olmadan)
```bash
flutter build ios --release --no-codesign
```

#### IPA Build (TestFlight/App Store için)
```bash
flutter build ipa --release
```

IPA dosyası şu konumda oluşturulur:
```
build/ios/ipa/azuredevops_onprem.ipa
```

## Fastlane ile Build

```bash
# IPA build
fastlane ios build_ipa

# Beta (TestFlight)
fastlane ios beta

# Production (App Store)
fastlane ios release
```

## Notlar

- **Codesigning**: Production build için Apple Developer hesabı ve signing certificates gerekir
- **TestFlight**: TestFlight'a yüklemek için App Store Connect API key gerekir
- **MDM**: Enterprise dağıtım için MDM sertifikası gerekir

## Sorun Giderme

### CocoaPods Hatası
```bash
# CocoaPods'u güncelle
sudo gem update cocoapods

# Pod cache'i temizle
pod cache clean --all
cd ios
pod deintegrate
pod install
```

### Xcode Command Line Tools
```bash
xcode-select --install
```

### Flutter iOS Setup
```bash
flutter doctor -v
flutter doctor --ios-licenses
```

