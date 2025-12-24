# Google Play Store Yükleme Sorun Giderme Rehberi

## Aldığınız Hatalar ve Çözümleri

### Hata 1: "Bu sürüm, mevcut kullanıcıların yeni eklenen uygulama paketlerine geçmelerine izin vermediği için kullanıma sunulamaz"

**Sebep:** 
- APK/AAB paket yapısında değişiklik var
- Mevcut kullanıcılar otomatik güncelleme yapamaz

**Çözüm:**
1. Play Console > Production/Internal testing'e gidin
2. Mevcut yayınlanmış sürümü kontrol edin
3. Version code'unuz mevcut sürümden **daha yüksek** olmalı

### Hata 2: "Bu sürüm hiçbir uygulama paketi eklemiyor veya kaldırmıyor"

**Sebep:**
- Version code mevcut sürümden düşük veya eşit
- Aynı version code ile tekrar yükleme yapılıyor

**Çözüm:**
1. `pubspec.yaml` dosyasındaki version code'u artırın:
   ```yaml
   version: 1.2.0+85  # 84'ten 85'e artırın
   ```
2. Yeni AAB build alın:
   ```bash
   flutter build appbundle --release
   ```
3. Yeni AAB'yi yükleyin

### Hata 3: "Hesabınızda sorunlar olduğu için..."

**Sebep:**
- Hesap doğrulaması eksik
- Ödeme bilgileri eksik/hatalı
- Developer Console hesap durumu sorunlu

**Çözüm:**
1. [Google Play Console](https://play.google.com/console) > Ayarlar > Hesap ayrıntıları
2. Tüm eksik bilgileri tamamlayın:
   - Developer hesabı bilgileri
   - Ödeme profili
   - Hesap doğrulaması
3. Hesap durumunu kontrol edin

## Adım Adım Çözüm

### 1. Mevcut Sürümü Kontrol Edin

Play Console'da:
- **Production** > **Releases** bölümüne gidin
- En son yayınlanan sürümün **Version code** değerini not edin

### 2. Version Code'u Artırın

Eğer mevcut version code 84 veya daha yüksekse:

```bash
# pubspec.yaml dosyasını düzenleyin
version: 1.2.0+85  # Mevcut sürümden 1 fazla yapın
```

### 3. Yeni AAB Build Alın

```bash
cd android
flutter clean
flutter pub get
flutter build appbundle --release
```

### 4. AAB Dosyasını Kontrol Edin

```bash
# AAB dosyasının oluşturulduğunu kontrol edin
ls -lh build/app/outputs/bundle/release/app-release.aab

# AAB içeriğini kontrol edin (opsiyonel)
bundletool build-apks --bundle=app-release.aab --output=test.apks --mode=debug
```

### 5. Play Console'a Yükleyin

1. Play Console > Production/Internal testing
2. **Create new release**
3. Yeni AAB dosyasını yükleyin (`app-release.aab`)
4. Release notlarını ekleyin
5. **Save** ve **Review release** butonlarına tıklayın

## Önemli Notlar

- ✅ Version code **her zaman artırılmalı** (asla azaltılamaz)
- ✅ Version name değiştirilebilir ama genelde artırılır
- ✅ İlk yüklemede version code 1'den başlayabilir
- ❌ Aynı version code ile tekrar yükleme yapılamaz
- ❌ Daha düşük version code ile yükleme yapılamaz

## İlk Yükleme İçin

İlk kez yükleme yapıyorsanız:
1. Version code 1 veya daha yüksek olmalı
2. Tüm hesap bilgileri tamamlanmış olmalı
3. Uygulama içeriği rating'i tamamlanmış olmalı
4. Store listing bilgileri doldurulmuş olmalı

## Hızlı Kontrol Listesi

- [ ] Version code mevcut sürümden yüksek mi?
- [ ] AAB dosyası düzgün oluşturuldu mu?
- [ ] Keystore ile imzalandı mı? (debug değil, release)
- [ ] Play Console hesap bilgileri tamamlandı mı?
- [ ] Uygulama içeriği rating'i yapıldı mı?
- [ ] Store listing bilgileri dolduruldu mu?

