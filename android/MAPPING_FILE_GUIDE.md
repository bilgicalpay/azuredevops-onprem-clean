# ProGuard/R8 Mapping Dosyası Rehberi

## Mapping Dosyası Nedir?

ProGuard/R8 kod küçültme (minify) işlemi sırasında sınıf, metod ve değişken isimlerini kısaltır. Mapping dosyası, bu kısaltılmış isimlerle orijinal isimler arasındaki ilişkiyi tutar.

**Önemli:** Kilitlenme raporlarını okumak ve hata ayıklama yapmak için mapping dosyası gereklidir!

## Mapping Dosyasının Konumu

Build sonrası mapping dosyası şu konumda oluşur:

```
android/app/build/outputs/mapping/release/mapping.txt
```

## Yeni Build Alma

Minify aktif olduğu için yeni bir build alın:

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

## Google Play Console'a Mapping Dosyası Yükleme

### Yöntem 1: AAB ile Birlikte Yükleme

1. Google Play Console'a giriş yapın
2. Uygulamanızı seçin
3. **Release** > **Production** (veya **Internal testing**) > **Releases**
4. Yeni bir release oluşturun veya mevcut release'i düzenleyin
5. AAB dosyasını yükleyin
6. **App bundles and APKs** bölümünde, yüklediğiniz AAB'nin yanında **"Upload mapping file"** linkini göreceksiniz
7. `android/app/build/outputs/mapping/release/mapping.txt` dosyasını yükleyin

### Yöntem 2: Mevcut Release'e Mapping Dosyası Ekleme

1. Google Play Console > **Release** > **Production** (veya **Internal testing**)
2. Yüklü olan release'i bulun
3. AAB'nin yanında **"Upload mapping file"** veya **"Manage mapping file"** linkine tıklayın
4. Mapping dosyasını yükleyin

## Mapping Dosyasını Kaydetme

**ÖNEMLİ:** Her build için mapping dosyasını mutlaka kaydedin! Aynı AAB için farklı bir mapping dosyası oluşturulamaz.

Önerilen yöntem:

```bash
# Build sonrası mapping dosyasını versiyon numarasıyla birlikte kaydedin
mkdir -p release-mappings
cp android/app/build/outputs/mapping/release/mapping.txt release-mappings/mapping-1.0.0-1.txt
```

Veya version bilgisini içeren bir script kullanın:

```bash
VERSION=$(grep '^version:' ../pubspec.yaml | sed 's/version: //' | tr -d ' ')
cp android/app/build/outputs/mapping/release/mapping.txt "release-mappings/mapping-${VERSION}.txt"
```

## Mapping Dosyası Olmadan Sorunlar

Mapping dosyası olmadan:
- ❌ Kilitlenme raporları okunamaz
- ❌ Hata ayıklama yapılamaz
- ❌ Stack trace'ler anlaşılmaz
- ❌ ANR (Application Not Responding) analizi zorlaşır

## Otomatik Mapping Dosyası Kaydetme

Build script'inize mapping dosyası kaydetme adımı ekleyebilirsiniz:

```bash
# Build sonrası
if [ -f "android/app/build/outputs/mapping/release/mapping.txt" ]; then
    VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | tr -d ' ')
    mkdir -p release-mappings
    cp android/app/build/outputs/mapping/release/mapping.txt "release-mappings/mapping-${VERSION}.txt"
    echo "✅ Mapping dosyası kaydedildi: release-mappings/mapping-${VERSION}.txt"
fi
```

## Build Optimizasyonları

Minify ve shrink resources aktif olduğunda:
- ✅ Uygulama boyutu %30-60 küçülür
- ✅ APK/AAB boyutu azalır
- ✅ Performans artar
- ✅ Güvenlik artar (kod gizlenir)

## Sorun Giderme

### Mapping dosyası oluşmuyor

1. `isMinifyEnabled = true` olduğundan emin olun
2. `build.gradle.kts` dosyasında ProGuard rules tanımlı olduğundan emin olun
3. Clean build yapın: `flutter clean && flutter build appbundle --release`

### Mapping dosyası Play Console'da görünmüyor

1. AAB ile aynı version code'a sahip mapping dosyasını yüklediğinizden emin olun
2. Mapping dosyasını yükledikten sonra release'i kaydedin
3. Birkaç dakika bekleyin (işleme süresi gerekebilir)

