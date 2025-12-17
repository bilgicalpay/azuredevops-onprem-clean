# iOS Cihaza Deploy Etme Kılavuzu

## Yöntem 1: Xcode ile Doğrudan Deploy (Önerilen)

### Gereksinimler
- Xcode yüklü
- Apple ID (ücretsiz)
- iOS cihaz USB ile bağlı
- Cihazda "Developer Mode" aktif

### Adımlar

1. **Build yapın:**
   ```bash
   flutter build ios --release --no-codesign
   ```

2. **Xcode workspace'i açın:**
   ```bash
   cd ios
   open Runner.xcworkspace
   ```

3. **Xcode'da:**
   - Sol üstten cihazınızı seçin (iPhone/iPad)
   - **Product > Destination > Your Device** seçin
   - **Product > Run** (⌘R) ile deploy edin

4. **İlk kez deploy ediyorsanız:**
   - **Xcode > Settings > Accounts** (⌘,)
   - Apple ID'nizi ekleyin
   - **Signing & Capabilities** sekmesine gidin
   - **Automatically manage signing** işaretleyin
   - **Team** seçin (Apple ID'niz)
   - Xcode otomatik olarak provisioning profile oluşturacak

5. **Cihazda:**
   - İlk deploy'da cihazda "Trust This Computer" mesajı çıkacak
   - Cihazda **Settings > General > VPN & Device Management** gidin
   - Developer App'i bulun ve "Trust" yapın

## Yöntem 2: IPA Oluşturup Cihaza Yükleme

### Gereksinimler
- Apple Developer hesabı (ücretsiz veya paid)
- Codesigning sertifikası

### Adımlar

1. **IPA oluşturun:**
   ```bash
   flutter build ipa --release
   ```

2. **IPA dosyası:**
   ```
   build/ios/ipa/azuredevops_onprem.ipa
   ```

3. **Cihaza yükleme seçenekleri:**

   **A) Xcode ile:**
   - Xcode > Window > Devices and Simulators
   - Cihazınızı seçin
   - "+" butonuna tıklayın
   - IPA dosyasını seçin

   **B) Apple Configurator 2 ile:**
   - Apple Configurator 2'yi açın
   - Cihazınızı seçin
   - "Add" > "Apps"
   - IPA dosyasını seçin

   **C) 3uTools / iMazing gibi araçlarla:**
   - Araçları açın
   - Cihazınızı bağlayın
   - IPA dosyasını yükleyin

## Yöntem 3: TestFlight (App Store Connect)

### Gereksinimler
- Apple Developer Program üyeliği ($99/yıl)
- App Store Connect hesabı

### Adımlar

1. **IPA oluşturun:**
   ```bash
   flutter build ipa --release
   ```

2. **App Store Connect'e yükleyin:**
   - https://appstoreconnect.apple.com adresine gidin
   - App'inizi oluşturun
   - TestFlight sekmesine gidin
   - IPA'yı yükleyin

3. **Test kullanıcıları ekleyin:**
   - TestFlight > Internal Testing veya External Testing
   - Kullanıcıları ekleyin
   - Kullanıcılar TestFlight app'i ile yükleyebilir

## Yöntem 4: Ad-Hoc Distribution

### Gereksinimler
- Apple Developer Program üyeliği
- Cihaz UDID'leri

### Adımlar

1. **Cihaz UDID'lerini toplayın:**
   - Xcode > Window > Devices and Simulators
   - Her cihazın Identifier'ını kopyalayın

2. **Provisioning Profile oluşturun:**
   - https://developer.apple.com/account
   - Certificates, Identifiers & Profiles
   - Provisioning Profiles > Ad-Hoc
   - Cihaz UDID'lerini ekleyin

3. **IPA oluşturun:**
   ```bash
   flutter build ipa --release
   ```

4. **IPA'yı dağıtın:**
   - IPA dosyasını paylaşın
   - Kullanıcılar IPA'yı cihazlarına yükleyebilir

## Sorun Giderme

### "No signing certificate found"
- Xcode > Settings > Accounts
- Apple ID'nizi ekleyin
- Team seçin
- "Download Manual Profiles" yapın

### "Device not trusted"
- Cihazda: Settings > General > VPN & Device Management
- Developer App'i bulun ve "Trust" yapın

### "Unable to install app"
- Cihazda Developer Mode aktif olmalı
- Settings > Privacy & Security > Developer Mode

### "Provisioning profile expired"
- Xcode > Settings > Accounts
- "Download Manual Profiles" yapın
- Xcode'u yeniden başlatın

## Notlar

- **Ücretsiz Apple ID:** Geliştirme için yeterli, 7 günlük sertifika
- **Apple Developer Program:** Production deploy için gerekli ($99/yıl)
- **Codesigning:** Production build için zorunlu
- **TestFlight:** Beta test için ideal, Apple Developer Program gerekli

