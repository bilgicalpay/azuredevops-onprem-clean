# Release Deployment Instructions

Bu dokümantasyon, yeni bir release oluşturma, imzalama, SBOM oluşturma, tag'leme ve GitHub release oluşturma sürecini açıklar.

## 📋 Release Öncesi Hazırlık

### 1. Versiyon Güncelleme

```bash
# Versiyonu güncelle (pubspec.yaml)
# Örnek: 1.0.25+31 → 1.0.26+32
# - Major.Minor.Patch (1.0.26)
# - Build number (+32)

# Script ile otomatik versiyon artırma
./scripts/bump_version.sh
```

### 2. Build ve Test

```bash
# Android APK build
flutter build apk --release

# iOS IPA build (codesign gerekli)
flutter build ipa --release

# Test et
flutter test
```

## 🔐 İmzalama (Sigstore)

### Artifact İmzalama

```bash
# APK imzalama
./scripts/sign_artifact.sh build/app/outputs/flutter-apk/app-release.apk

# IPA imzalama
./scripts/sign_artifact.sh build/ios/ipa/azuredevops_onprem.ipa

# İmza dosyaları oluşturulur:
# - app-release.apk.sigstore
# - azuredevops_onprem.ipa.sigstore
```

**Not:** Sigstore imzalama için `cosign` kurulu olmalıdır:
```bash
# macOS
brew install sigstore/tap/cosign

# veya
go install github.com/sigstore/cosign/v2/cmd/cosign@latest
```

## 📦 SBOM (Software Bill of Materials) Oluşturma

### SBOM Oluşturma

```bash
# SBOM oluştur
./scripts/generate_sbom.sh

# SBOM dosyaları oluşturulur:
# - build/sbom/spdx.json (SPDX format)
# - build/sbom/sbom.txt (Text format)
```

### SBOM İçeriği

- Paket adı ve versiyonu
- Tüm bağımlılıklar (dependencies)
- Build bilgileri (Flutter/Dart SDK versiyonları)
- Oluşturulma tarihi

## 🏷️ Git Tag Oluşturma

### Tag Oluşturma

```bash
# Versiyonu kontrol et
VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | tr -d ' ' | cut -d'+' -f1)
echo "Creating tag: v$VERSION"

# Tag oluştur
git tag -a "v$VERSION" -m "Release v$VERSION"

# Tag'i push et
git push origin "v$VERSION"
```

### Tag Formatı

- Format: `v{Major}.{Minor}.{Patch}`
- Örnek: `v1.0.26`

## 📁 Release Dosyalarını Hazırlama

### Release Dosyaları Dizini

```bash
# Release dosyaları dizinini oluştur
mkdir -p release-files

# Dosyaları kopyala
cp build/app/outputs/flutter-apk/app-release.apk release-files/azuredevops-${VERSION}.apk
cp build/ios/ipa/azuredevops_onprem.ipa release-files/azuredevops-${VERSION}.ipa
cp build/app/outputs/flutter-apk/app-release.apk.sigstore release-files/azuredevops-${VERSION}.apk.sigstore
cp build/ios/ipa/azuredevops_onprem.ipa.sigstore release-files/azuredevops-${VERSION}.ipa.sigstore
cp build/sbom/spdx.json release-files/
cp build/sbom/sbom.txt release-files/
```

### Önceki Release'teki Belgeleri Kopyalama

```bash
# Önceki release'teki belgeleri yeni release'e kopyala
PREVIOUS_VERSION="1.0.25"  # Önceki versiyon
CURRENT_VERSION="1.0.26"  # Yeni versiyon

# Güvenlik raporlarını kopyala
cp release-files/security_report.md release-files/
cp release-files/security_audit.md release-files/
cp release-files/comprehensive_audit.md release-files/
cp release-files/security_implementation_report.md release-files/
cp release-files/SECURITY_FEATURES.md release-files/
cp release-files/dependency_update_report.md release-files/

# RELEASE_NOTES.md'yi güncelle
# (Manuel olarak yeni değişiklikleri ekleyin)
```

### Release Notları Oluşturma

```bash
# RELEASE_NOTES.md oluştur/güncelle
cat > release-files/RELEASE_NOTES.md <<EOF
# Release v${VERSION}

## 🎉 Yeni Özellikler

- [Yeni özellikler buraya]

## 🐛 Hata Düzeltmeleri

- [Hata düzeltmeleri buraya]

## 🔒 Güvenlik

- [Güvenlik güncellemeleri buraya]

## 📦 Teknik Detaylar

- **Versiyon:** ${VERSION}
- **Build Number:** [BUILD_NUMBER]
- **Flutter SDK:** [FLUTTER_VERSION]
- **Dart SDK:** [DART_VERSION]

## 📥 İndirme

- **Android APK:** [APK_LINK]
- **iOS IPA:** [IPA_LINK]

## 🔐 İmzalama

Tüm artifact'lar Sigstore ile imzalanmıştır:
- APK: `azuredevops-${VERSION}.apk.sigstore`
- IPA: `azuredevops-${VERSION}.ipa.sigstore`

## 📋 SBOM

Software Bill of Materials:
- SPDX Format: `spdx.json`
- Text Format: `sbom.txt`

## 📚 Dokümantasyon

- [Güvenlik Raporu](security_report.md)
- [Güvenlik Denetimi](security_audit.md)
- [Kapsamlı Denetim](comprehensive_audit.md)
- [Güvenlik Uygulama Raporu](security_implementation_report.md)
EOF
```

## 🚀 GitHub Release Oluşturma

### Option 1: GitHub Web Interface

1. **GitHub Repository'ye gidin:**
   - https://github.com/bilgicalpay/azuredevops-server-mobile/releases/new

2. **Release bilgilerini girin:**
   - **Tag:** `v{VERSION}` (örn: `v1.0.26`)
   - **Title:** `Release v{VERSION} - [Kısa Açıklama]`
   - **Description:** `RELEASE_NOTES.md` içeriğini kopyalayın

3. **Dosyaları yükleyin:**
   - `azuredevops-${VERSION}.apk`
   - `azuredevops-${VERSION}.ipa`
   - `azuredevops-${VERSION}.apk.sigstore`
   - `azuredevops-${VERSION}.ipa.sigstore`
   - `spdx.json`
   - `sbom.txt`
   - `RELEASE_NOTES.md`
   - `security_report.md`
   - `security_audit.md`
   - `comprehensive_audit.md`
   - `security_implementation_report.md`
   - `SECURITY_FEATURES.md`
   - `dependency_update_report.md`

4. **"Publish release" butonuna tıklayın**

### Option 2: GitHub CLI

```bash
# GitHub CLI ile authentication
gh auth login

# Release oluştur
VERSION="1.0.26"  # Versiyonu güncelleyin

gh release create "v${VERSION}" \
  --title "Release v${VERSION} - [Kısa Açıklama]" \
  --notes-file release-files/RELEASE_NOTES.md \
  release-files/azuredevops-${VERSION}.apk \
  release-files/azuredevops-${VERSION}.ipa \
  release-files/azuredevops-${VERSION}.apk.sigstore \
  release-files/azuredevops-${VERSION}.ipa.sigstore \
  release-files/spdx.json \
  release-files/sbom.txt \
  release-files/RELEASE_NOTES.md \
  release-files/security_report.md \
  release-files/security_audit.md \
  release-files/comprehensive_audit.md \
  release-files/security_implementation_report.md \
  release-files/SECURITY_FEATURES.md \
  release-files/dependency_update_report.md
```

## ✅ Release Sonrası Doğrulama

Release oluşturulduktan sonra kontrol edin:

- [ ] APK dosyası yüklendi
- [ ] IPA dosyası yüklendi (varsa)
- [ ] İmza dosyaları (.sigstore) yüklendi
- [ ] SBOM dosyaları (spdx.json, sbom.txt) yüklendi
- [ ] Release notları görünür
- [ ] Güvenlik raporları yüklendi
- [ ] Tag `v{VERSION}` oluşturuldu
- [ ] Release public olarak görünüyor

## 🔗 Release URL

Release oluşturulduktan sonra şu adreste görüntülenebilir:
```
https://github.com/bilgicalpay/azuredevops-server-mobile/releases/tag/v{VERSION}
```

## 📝 Örnek Release Süreci

```bash
# 1. Versiyonu güncelle
./scripts/bump_version.sh

# 2. Build et
flutter build apk --release
flutter build ipa --release

# 3. İmzala
./scripts/sign_artifact.sh build/app/outputs/flutter-apk/app-release.apk
./scripts/sign_artifact.sh build/ios/ipa/azuredevops_onprem.ipa

# 4. SBOM oluştur
./scripts/generate_sbom.sh

# 5. Release dosyalarını hazırla
VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | tr -d ' ' | cut -d'+' -f1)
mkdir -p release-files
cp build/app/outputs/flutter-apk/app-release.apk release-files/azuredevops-${VERSION}.apk
cp build/app/outputs/flutter-apk/app-release.apk.sigstore release-files/azuredevops-${VERSION}.apk.sigstore
cp build/ios/ipa/azuredevops_onprem.ipa release-files/azuredevops-${VERSION}.ipa
cp build/ios/ipa/azuredevops_onprem.ipa.sigstore release-files/azuredevops-${VERSION}.ipa.sigstore
cp build/sbom/* release-files/
# Önceki release'teki belgeleri kopyala
cp release-files/security_*.md release-files/
cp release-files/SECURITY_FEATURES.md release-files/
cp release-files/dependency_update_report.md release-files/

# 6. RELEASE_NOTES.md oluştur (manuel)

# 7. Git tag oluştur
git tag -a "v${VERSION}" -m "Release v${VERSION}"
git push origin "v${VERSION}"

# 8. GitHub release oluştur
gh release create "v${VERSION}" \
  --title "Release v${VERSION}" \
  --notes-file release-files/RELEASE_NOTES.md \
  release-files/*
```

## 📚 İlgili Dokümantasyon

- [Güvenlik Dokümantasyonu](docs/SECURITY.md)
- [Altyapı Dokümantasyonu](docs/INFRASTRUCTURE.md)
- [MDM Entegrasyon Kılavuzu](docs/MDM_INTEGRATION.md)
- [Market Özelliği Kullanımı](docs/README.md#market-özelliği-ile-dağıtım)

---

**Son Güncelleme:** 2025  
**Dokümantasyon Versiyonu:** 1.0
