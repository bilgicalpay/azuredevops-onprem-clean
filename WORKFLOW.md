# Development Workflow - Azure DevOps Mobile App

**Proje:** Azure DevOps Server 2022 Mobile App (Flutter)  
**Geliştirici:** Alpay Bilgiç  
**Bu doküman AI asistanı için zorunlu workflow kılavuzudur.**

## 🎯 Proje Özeti

Azure DevOps Server 2022 on-premise kurulumları için Flutter ile geliştirilmiş mobil uygulama. Work item yönetimi, query çalıştırma, wiki görüntüleme, push notification ve market özellikleri sunar.

## 📋 ZORUNLU WORKFLOW - HER ZAMAN UYGULA

### 1. Her Kod Değişikliği Sonrası (Otomatik)

**Her değişiklik yaptıktan sonra MUTLAKA:**

#### 1.1 DevSecOps - Pre-Commit Security Checks
```bash
# Güvenlik taraması yap
./scripts/security_scan.sh

# Dependency güvenlik kontrolleri
./scripts/security_checks.sh

# Eğer kritik güvenlik sorunları varsa, commit öncesi düzelt
```

#### 1.2 Git Commit ve Push
```bash
# 1. Tüm değişiklikleri stage'e ekle
git add -A

# 2. Commit yap (anlamlı mesaj ile)
git commit -m "feat: [kısa açıklama] veya fix: [kısa açıklama]"

# 3. Develop branch'ına push et
git push origin develop
```

**ÖNEMLİ:** Bu adımlar SORULMADAN her değişiklik sonrası otomatik yapılmalı.

---

### 2. Fonksiyonel Değişiklik Sonrası (Test Öncesi)

**Fonksiyonel bir özellik eklendiğinde/düzeltildiğinde:**

#### 2.1 Semantic Version Artır
- `pubspec.yaml` dosyasında versiyonu artır
- Format: `MAJOR.MINOR.PATCH+BUILD`
- Örnek: `1.1.3+41` → `1.1.4+42` (minor feature için)
- Örnek: `1.1.3+41` → `1.2.0+42` (major feature için)
- Örnek: `1.1.3+41` → `1.1.4+42` (patch/bug fix için)

#### 2.2 README.md Güncelle
- **Özellikler** bölümüne yeni özelliği ekle
- Versiyon bilgisini güncelle (başta ve sonda)
- Tarih bilgisini güncelle

#### 2.3 CHANGELOG.md Güncelle
- En üste yeni versiyon için bölüm ekle
- Format:
  ```markdown
  ## [X.Y.Z] - YYYY-MM-DD
  
  ### 🆕 Yeni Özellikler (veya 🔧 İyileştirmeler veya 🐛 Hata Düzeltmeleri)
  - [Açıklama]
  ```

#### 2.4 Commit ve Push
```bash
git add pubspec.yaml README.md CHANGELOG.md
git commit -m "chore(release): Bump version to X.Y.Z+BUILD"
git push origin develop
```

---

### 3. Build ve Deploy (Test İçin)

**Her fonksiyonel değişiklik sonrası test için:**

#### 3.0 DevSecOps - Pre-Build Security
```bash
# SBOM (Software Bill of Materials) oluştur
./scripts/generate_sbom.sh

# Güvenlik taraması (dependency vulnerabilities)
./scripts/security_scan.sh

# Security checks (code analysis)
./scripts/security_checks.sh

# SBOM dosyalarını kontrol et
ls -lh build/sbom/
```

#### 3.1 Android Build ve Deploy
```bash
# Build
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
/Users/alpaybilgic/flutter/bin/flutter build apk --release --build-name=X.Y.Z --build-number=BUILD

# Deploy (ADB ile)
/Users/alpaybilgic/Library/Android/sdk/platform-tools/adb install -r build/app/outputs/flutter-apk/app-release.apk
/Users/alpaybilgic/Library/Android/sdk/platform-tools/adb shell am start -n io.rdc.azuredevops/io.rdc.azuredevops.MainActivity
```

#### 3.2 iOS Build ve Deploy
```bash
# Build (Simulator için)
/Users/alpaybilgic/flutter/bin/flutter build ios --simulator --build-name=X.Y.Z --build-number=BUILD

# Deploy (Simulator'a)
BOOTED_SIM=$(xcrun simctl list devices | grep "Booted" | head -1 | sed 's/.*(\(.*\))/\1/' | tr -d ' ')
xcrun simctl install "$BOOTED_SIM" build/ios/iphonesimulator/Runner.app
xcrun simctl launch "$BOOTED_SIM" io.rdc.azuredevops
```

**VEYA script kullan:**
```bash
./scripts/build_and_deploy_all.sh
```

---

### 4. Test Sonrası - Release Süreci

**Test başarılı ise (kullanıcı "Test OK" dediğinde):**

#### 4.1 DevSecOps - Pre-Release Security
```bash
# Son güvenlik taraması
./scripts/security_scan.sh
./scripts/security_checks.sh

# SBOM oluştur (release için)
./scripts/generate_sbom.sh

# Security audit raporu oluştur (eğer script varsa)
# ./scripts/security_audit.sh
```

#### 4.2 Release Dosyalarını Hazırla
```bash
# Release klasörü oluştur
mkdir -p release_assets/vX.Y.Z

# APK'yı kopyala
cp build/app/outputs/flutter-apk/app-release.apk release_assets/vX.Y.Z/azuredevops-X.Y.Z.apk

# APK'yı imzala (Sigstore)
./scripts/sign_artifact.sh release_assets/vX.Y.Z/azuredevops-X.Y.Z.apk

# iOS IPA build (eğer gerekiyorsa)
# flutter build ipa --build-name=X.Y.Z --build-number=BUILD
# IPA'yı kopyala ve imzala (eğer varsa)
# cp build/ios/ipa/*.ipa release_assets/vX.Y.Z/azuredevops-X.Y.Z.ipa
# ./scripts/sign_artifact.sh release_assets/vX.Y.Z/azuredevops-X.Y.Z.ipa

# SBOM dosyalarını kopyala
cp -r build/sbom release_assets/vX.Y.Z/
```

#### 4.3 RELEASE_NOTES.md Oluştur/Güncelle
- Yeni versiyon için detaylı release notes oluştur
- Tüm değişiklikleri, özellikleri, düzeltmeleri listele
- Platform desteği, migration notes, vb. ekle

#### 4.4 Main Branch'a Merge
```bash
# Develop'dan main'e merge
git checkout main
git merge develop
git push origin main
```

#### 4.5 GitHub Release Oluştur
```bash
# Tag oluştur
git tag -a vX.Y.Z -m "Release vX.Y.Z"
git push origin vX.Y.Z

# GitHub CLI ile release oluştur (veya manuel)
gh release create vX.Y.Z \
  --title "vX.Y.Z Release" \
  --notes-file RELEASE_NOTES.md \
  release_assets/vX.Y.Z/azuredevops-X.Y.Z.apk \
  release_assets/vX.Y.Z/azuredevops-X.Y.Z.apk.sigstore \
  release_assets/vX.Y.Z/azuredevops-X.Y.Z.ipa \
  release_assets/vX.Y.Z/azuredevops-X.Y.Z.ipa.sigstore \
  release_assets/vX.Y.Z/sbom/spdx.json \
  release_assets/vX.Y.Z/sbom/sbom.txt
```

**DevSecOps - Release Assets:**
- ✅ APK (imzalı)
- ✅ APK.sigstore (imza)
- ✅ IPA (imzalı, eğer varsa)
- ✅ IPA.sigstore (imza, eğer varsa)
- ✅ SBOM (SPDX format)
- ✅ SBOM (Text format)
- ✅ RELEASE_NOTES.md

**VEYA GitHub web interface'den:**
1. Releases → Draft a new release
2. Tag: `vX.Y.Z`
3. Title: `vX.Y.Z Release`
4. Description: RELEASE_NOTES.md içeriğini yapıştır
5. APK ve IPA dosyalarını upload et
6. Publish release

---

## 🔄 Günlük Çalışma Akışı

### Senaryo 1: Küçük Değişiklik (Bug Fix, Refactor)
1. ✅ Kod değişikliği yap
2. ✅ **DevSecOps:** Security scan ve checks çalıştır
3. ✅ `git add -A && git commit -m "fix: ..." && git push origin develop`
4. ✅ Test et (build ve deploy)
5. ✅ Test OK ise → Release sürecine geç

### Senaryo 2: Fonksiyonel Özellik Ekleme
1. ✅ Kod değişikliği yap
2. ✅ **DevSecOps:** Security scan ve checks çalıştır
3. ✅ Versiyon artır (semantic versioning)
4. ✅ README.md güncelle (özellikler listesine ekle)
5. ✅ CHANGELOG.md güncelle
6. ✅ `git add -A && git commit -m "feat: ..." && git push origin develop`
7. ✅ **DevSecOps:** SBOM oluştur
8. ✅ Build ve deploy (Android + iOS)
9. ✅ Test et
10. ✅ Test OK ise → Release sürecine geç

### Senaryo 3: Release Hazırlığı
1. ✅ **DevSecOps:** Final security scan ve audit
2. ✅ **DevSecOps:** SBOM oluştur (release için)
3. ✅ RELEASE_NOTES.md oluştur
4. ✅ Release dosyalarını hazırla (APK, IPA)
5. ✅ **DevSecOps:** Artifact'ları imzala (Sigstore)
6. ✅ Main branch'a merge
7. ✅ GitHub release oluştur
8. ✅ APK, IPA, SBOM ve imzaları release'e ekle

---

## 📝 Dokümantasyon Güncelleme Kuralları

### README.md
- **Her fonksiyonel değişiklikte** Özellikler bölümüne ekle
- Versiyon bilgisini güncelle (başta ve sonda)
- Tarih bilgisini güncelle

### CHANGELOG.md
- **Her versiyon değişikliğinde** en üste yeni bölüm ekle
- Kategoriler: 🆕 Yeni Özellikler, 🔧 İyileştirmeler, 🐛 Hata Düzeltmeleri
- Tarih formatı: YYYY-MM-DD

### RELEASE_NOTES.md
- **Her release'te** yeni dosya oluştur veya güncelle
- Detaylı açıklamalar, migration notes, platform desteği
- GitHub release description olarak kullanılır

---

## 🚫 YAPILMAMASI GEREKENLER

- ❌ Değişiklik yapıp commit etmeden bırakmak
- ❌ Security scan yapmadan commit etmek
- ❌ Fonksiyonel değişiklik yapıp versiyon artırmamak
- ❌ README ve CHANGELOG'u güncellemeden release yapmak
- ❌ SBOM oluşturmadan release yapmak
- ❌ Artifact'ları imzalamadan release yapmak
- ❌ Test etmeden release yapmak
- ❌ APK/IPA/SBOM/Signatures'ı release'e eklemeden release yayınlamak
- ❌ Develop branch'a push etmeden main'e merge etmek
- ❌ Kritik güvenlik sorunları varken release yapmak

---

## 🔒 DevSecOps Adımları (Zorunlu)

### Pre-Commit (Her Değişiklik Öncesi)
- ✅ Security scan çalıştır (`security_scan.sh`)
- ✅ Security checks çalıştır (`security_checks.sh`)
- ✅ Dependency vulnerability kontrolü
- ✅ Kritik güvenlik sorunları varsa düzelt

### Pre-Build (Build Öncesi)
- ✅ SBOM oluştur (`generate_sbom.sh`)
- ✅ Security scan (dependency vulnerabilities)
- ✅ Security checks (code analysis)
- ✅ SBOM dosyalarını kontrol et

### Pre-Release (Release Öncesi)
- ✅ Final security scan ve audit
- ✅ SBOM oluştur (release versiyonu için)
- ✅ Artifact'ları imzala (Sigstore - `sign_artifact.sh`)
- ✅ Security documentation güncelle

### Release Assets (GitHub Release'e Eklenecek)
- ✅ APK (imzalı)
- ✅ APK.sigstore (imza dosyası)
- ✅ IPA (imzalı, eğer varsa)
- ✅ IPA.sigstore (imza dosyası, eğer varsa)
- ✅ SBOM (SPDX format - `build/sbom/spdx.json`)
- ✅ SBOM (Text format - `build/sbom/sbom.txt`)
- ✅ RELEASE_NOTES.md
- ✅ Security audit raporu (eğer varsa)

### Security Script'leri
- `scripts/security_scan.sh` - Dependency ve kod güvenlik taraması
- `scripts/security_checks.sh` - Güvenlik kontrolleri
- `scripts/generate_sbom.sh` - SBOM oluşturma
- `scripts/sign_artifact.sh` - Artifact imzalama (Sigstore)

---

## ✅ HER ZAMAN HATIRLA

1. **Her değişiklik = Security scan + Git commit + push to develop**
2. **Fonksiyonel değişiklik = Version bump + README + CHANGELOG + SBOM**
3. **Test öncesi = Security checks + Build + Deploy (Android + iOS)**
4. **Test OK = Security audit + Release hazırlığı + Artifact signing + Main merge + GitHub release**
5. **Release = APK + IPA + Signatures + SBOM + RELEASE_NOTES + GitHub release**

**Bu workflow SORULMADAN otomatik uygulanmalıdır.**

---

**Son Güncelleme:** 21-12-2025  
**Versiyon:** 1.0

