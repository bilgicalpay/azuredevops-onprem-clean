# Uygulama Hata Ayıklama Rehberi

## 1. ADB ile Log Kontrolü

### ADB'yi PATH'e Ekleme (Kalıcı)

Terminal'inize şunu ekleyin (`~/.zshrc` veya `~/.bash_profile`):

```bash
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/tools
```

Sonra terminal'i yeniden başlatın veya:
```bash
source ~/.zshrc
```

### Log Kontrolü İçin Script Kullanımı

Proje dizininde:
```bash
./check_logs.sh
```

### Manuel Log Kontrolü

```bash
# Cihazları listele
~/Library/Android/sdk/platform-tools/adb devices

# Logları temizle ve başlat
~/Library/Android/sdk/platform-tools/adb logcat -c
~/Library/Android/sdk/platform-tools/adb logcat | grep -iE "flutter|azuredevops|error|fatal"

# Sadece uygulama logları
~/Library/Android/sdk/platform-tools/adb logcat | grep -i "com.higgscloud.azuredevops"

# Crash loglarını kontrol et
~/Library/Android/sdk/platform-tools/adb logcat | grep -iE "fatal|crash|exception"
```

## 2. Google Play Console'dan Crash Raporları

### Adımlar:

1. [Google Play Console](https://play.google.com/console) açın
2. Uygulamanızı seçin: **AzureDevOps Mobile**
3. Sol menüden **Quality** > **Crashes & ANRs** seçin
4. Son 24 saat veya 7 günlük crash'leri kontrol edin
5. Crash detayına tıklayın ve stack trace'i inceleyin

### Crash Raporlarını Okuma:

- **ClassNotFoundException**: Bir sınıf bulunamıyor (ProGuard sorunu olabilir)
- **NullPointerException**: Null referans hatası
- **IllegalStateException**: Uygulama beklenmeyen durumda
- **OutOfMemoryError**: Bellek yetersiz

## 3. Yaygın Sorunlar ve Çözümleri

### Sorun 1: Uygulama Açılmıyor (Crash on Launch)

**Olası Nedenler:**
- ProGuard/R8 bazı sınıfları sildi
- Google Fonts yüklenemedi
- Servis başlatma hatası

**Çözüm:**
- Yeni build'i test edin (1.0.1+3)
- Google Fonts artık hata yönetimi ile korunuyor
- Tüm servisler try-catch ile korunuyor

### Sorun 2: ClassNotFoundException

**Olası Neden:**
- ProGuard kuralları eksik

**Çözüm:**
- `proguard-rules.pro` dosyasına ilgili sınıf için `-keep` kuralı ekleyin

### Sorun 3: SecurityService Hatası

**Olası Neden:**
- Root detection servisi hata veriyor

**Çözüm:**
- Yeni build'de SecurityService başlatma hatası yakalanıyor ve uygulama devam ediyor

## 4. Test için Debug APK Oluşturma

Release build'i test etmek yerine debug APK ile test edebilirsiniz:

```bash
flutter build apk --debug
```

Bu APK'yı doğrudan cihaza yükleyip test edin:
```bash
~/Library/Android/sdk/platform-tools/adb install build/app/outputs/flutter-apk/app-debug.apk
```

## 5. Play Console'da Pre-launch Report

1. Play Console > **Release** > **Production**
2. **Pre-launch report** sekmesine bakın
3. Otomatik testler sonuçlarını gösterir
4. Cihaz bazında sorunları görebilirsiniz

## 6. Internal Testing ile Test

1. Play Console > **Testing** > **Internal testing**
2. Yeni bir release oluşturun
3. Test kullanıcılarını ekleyin
4. Test edin ve geri bildirim toplayın

## 7. Hızlı Sorun Giderme Komutları

```bash
# Uygulamayı kaldır
adb uninstall com.higgscloud.azuredevops

# Yeni APK yükle
adb install path/to/app.apk

# Uygulama bilgilerini göster
adb shell dumpsys package com.higgscloud.azuredevops

# Crash loglarını dosyaya kaydet
adb logcat > crash_logs.txt

# Belirli bir hata için logları filtrele
adb logcat | grep -i "classnotfound\|nullpointer\|illegalstate"
```

## 8. Destek ve Kaynaklar

- [Flutter Debugging Guide](https://docs.flutter.dev/testing/debugging)
- [Android Logcat Documentation](https://developer.android.com/studio/command-line/logcat)
- [ProGuard Troubleshooting](https://www.guardsquare.com/manual/configuration/troubleshooting)

