# Google Play Console API Kurulumu ve Kullanımı

## Sorun

Google Play Console'da şu hata alınıyor:
- "Bu sürüm, mevcut kullanıcıların yeni eklenen uygulama paketlerine geçmelerine izin vermediği için kullanıma sunulamaz."
- "Bu APK'nın hiçbir kullanıcısı, bu sürüme eklenen hiçbir yeni APK sürümüne geçemeyecek."

## Çözüm: Google Play Console API ile Yükleme

### 1. Google Cloud Console'da Service Account Oluşturma

1. [Google Cloud Console](https://console.cloud.google.com/)'a gidin
2. Bir proje seçin veya yeni proje oluşturun
3. **APIs & Services** > **Library**'ye gidin
4. **Google Play Android Developer API**'yi arayın ve etkinleştirin
5. **APIs & Services** > **Credentials**'e gidin
6. **Create Credentials** > **Service Account** seçin
7. Service account adı verin ve oluşturun
8. Service account'a tıklayın ve **Keys** sekmesine gidin
9. **Add Key** > **Create new key** > **JSON** seçin
10. JSON dosyasını indirin ve `service-account-key.json` olarak kaydedin

### 2. Google Play Console'da İzin Verme

1. [Google Play Console](https://play.google.com/console/)'a gidin
2. Uygulamanızı seçin
3. **Settings** > **API access**'e gidin
4. **Link service account** butonuna tıklayın
5. Oluşturduğunuz service account'u seçin
6. İzinleri verin:
   - ✅ View app information and download bulk reports
   - ✅ Manage production releases
   - ✅ Manage testing track releases
   - ✅ Manage orders and subscriptions

### 3. Python Kütüphanelerini Yükleme

```bash
pip install google-api-python-client google-auth-httplib2 google-auth-oauthlib
```

### 4. Script'i Çalıştırma

```bash
# Service account key dosyasını belirtin
export GOOGLE_PLAY_SERVICE_ACCOUNT_JSON="path/to/service-account-key.json"

# Script'i çalıştırın
python3 scripts/upload_to_play_store.py
```

Veya direkt olarak:

```bash
GOOGLE_PLAY_SERVICE_ACCOUNT_JSON="service-account-key.json" python3 scripts/upload_to_play_store.py
```

## Manuel Çözüm (Alternatif)

API kullanmak istemiyorsanız, Google Play Console web arayüzünden:

### Adım 1: Mevcut Release'leri Temizle

1. **Testing** > **Closed testing** (veya **Alpha**)'e gidin
2. Mevcut release'i bulun
3. Release'i **Archive** edin veya **Delete** edin
4. **Alpha** track'i için de aynısını yapın

### Adım 2: Yeni Release Oluştur

1. **Testing** > **Closed testing**'e gidin
2. **Create new release** butonuna tıklayın
3. **AAB dosyasını yükleyin**: `build/app/outputs/bundle/release/app-release.aab`
4. Release notes ekleyin (isteğe bağlı)
5. **Save** ve **Review release**'e tıklayın
6. Release'i onaylayın

3. **Alpha** track'i için de aynı işlemi tekrarlayın

## Önemli Notlar

- ✅ **Sadece AAB kullanın**, APK kullanmayın
- ✅ **Eski release'leri archive edin** (tamamen silmeyin)
- ✅ **Her track için ayrı release oluşturun**
- ✅ **Version code her zaman artmalı** (110, 111, 112, ...)

## Mevcut Build

- **Version:** 1.0.15
- **Version Code:** 110
- **AAB Dosyası:** `build/app/outputs/bundle/release/app-release.aab`
- **Boyut:** ~46 MB

## Troubleshooting

### API Hatası: "The project id used to call the Google Play Developer API has not been linked"

Çözüm: Google Play Console'da service account'a izin vermeniz gerekiyor (Adım 2)

### API Hatası: "The caller does not have permission"

Çözüm: Service account'a yeterli izinler verilmiş mi kontrol edin

### API Hatası: "Version code already exists"

Çözüm: Version code'u artırın (`pubspec.yaml`'da `version: 1.0.15+111`)

