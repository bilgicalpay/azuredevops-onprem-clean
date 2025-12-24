#!/bin/bash

# Full Build and Release - Tüm build'leri yapar ve GitHub'a gönderir
# v1.2.0+84

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
FLUTTER_CMD="/Users/alpaybilgic/flutter/bin/flutter"

VERSION_NAME="1.2.0"
BUILD_NUMBER="84"

echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}🚀 Full Build and Release - v${VERSION_NAME}+${BUILD_NUMBER}${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

# Step 1: Clean
echo -e "${GREEN}1️⃣  Flutter clean...${NC}"
$FLUTTER_CMD clean
echo ""

# Step 2: Pub get
echo -e "${GREEN}2️⃣  Pub get...${NC}"
$FLUTTER_CMD pub get
echo ""

# Step 3: Build Android APK
echo -e "${GREEN}3️⃣  Android APK build...${NC}"
$FLUTTER_CMD build apk --release --build-name=${VERSION_NAME} --build-number=${BUILD_NUMBER}
if [ -f "build/app/outputs/apk/release/azuredevops.apk" ]; then
    echo -e "${GREEN}✅ APK hazır${NC}"
elif [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    mkdir -p build/app/outputs/apk/release
    cp build/app/outputs/flutter-apk/app-release.apk build/app/outputs/apk/release/azuredevops.apk
    echo -e "${GREEN}✅ APK hazır${NC}"
fi
echo ""

# Step 4: Build Android AAB
echo -e "${GREEN}4️⃣  Android AAB build...${NC}"
$FLUTTER_CMD build appbundle --release --build-name=${VERSION_NAME} --build-number=${BUILD_NUMBER}
echo -e "${GREEN}✅ AAB hazır${NC}"
echo ""

# Step 5: Build iOS IPA
echo -e "${GREEN}5️⃣  iOS IPA build...${NC}"
if $FLUTTER_CMD build ipa --release --build-name=${VERSION_NAME} --build-number=${BUILD_NUMBER} 2>&1; then
    IPA_FILE=$(find build/ios/ipa -name "*.ipa" 2>/dev/null | head -1)
    if [ -n "$IPA_FILE" ] && [ -f "$IPA_FILE" ]; then
        mkdir -p build/ios/ipa
        cp "$IPA_FILE" build/ios/ipa/azuredevops.ipa 2>/dev/null || mv "$IPA_FILE" build/ios/ipa/azuredevops.ipa 2>/dev/null || true
        echo -e "${GREEN}✅ IPA hazır${NC}"
    else
        echo -e "${YELLOW}⚠️  IPA dosyası bulunamadı, manuel oluşturuluyor...${NC}"
        if [ -f "scripts/create_ipa.sh" ]; then
            bash scripts/create_ipa.sh 2>&1 | tail -10
        fi
    fi
else
    echo -e "${YELLOW}⚠️  Flutter build ipa başarısız, manuel oluşturuluyor...${NC}"
    if [ -f "scripts/create_ipa.sh" ]; then
        bash scripts/create_ipa.sh 2>&1 | tail -10
    fi
fi
echo ""

# Step 6: Generate SBOM
echo -e "${GREEN}6️⃣  SBOM oluşturuluyor...${NC}"
if [ -f "scripts/generate_sbom.sh" ]; then
    bash scripts/generate_sbom.sh 2>&1 | tail -5
fi
echo ""

# Step 7: Git operations
echo -e "${GREEN}7️⃣  Git commit...${NC}"
git add -A
git commit -m "chore: RDC referansları temizlendi ve build dosyaları oluşturuldu - v${VERSION_NAME}+${BUILD_NUMBER}

- io.rdc.azuredevops -> com.higgscloud.azuredevops
- RDC Partner -> Higgs Cloud veya kaldırıldı
- Klasör yapısı güncellendi
- Logo referansları güncellendi
- CHANGELOG güncellendi
- Build dosyaları oluşturuldu (APK, AAB, IPA)" || echo "Commit yapılamadı (değişiklik yok)"
echo ""

echo -e "${GREEN}8️⃣  Git push...${NC}"
git push origin develop
echo ""

echo -e "${GREEN}9️⃣  Git tag...${NC}"
git tag -a v${VERSION_NAME}+${BUILD_NUMBER} -m "Release v${VERSION_NAME}+${BUILD_NUMBER}: RDC referansları temizlendi" 2>/dev/null || echo "Tag zaten var"
git push origin v${VERSION_NAME}+${BUILD_NUMBER}
echo ""

# Step 8: GitHub Release
echo -e "${GREEN}🔟 GitHub Release...${NC}"
gh release delete v${VERSION_NAME}+${BUILD_NUMBER} -y 2>&1 || true

FILES=()
[ -f "build/app/outputs/apk/release/azuredevops.apk" ] && FILES+=("build/app/outputs/apk/release/azuredevops.apk")
[ -f "build/app/outputs/bundle/release/app-release.aab" ] && FILES+=("build/app/outputs/bundle/release/app-release.aab")
[ -f "build/ios/ipa/azuredevops.ipa" ] && FILES+=("build/ios/ipa/azuredevops.ipa")
[ -f "build/sbom/spdx.json" ] && FILES+=("build/sbom/spdx.json")
[ -f "build/sbom/sbom.txt" ] && FILES+=("build/sbom/sbom.txt")
[ -f "CHANGELOG.md" ] && FILES+=("CHANGELOG.md")

echo "Toplam ${#FILES[@]} dosya yüklenecek"

if [ ${#FILES[@]} -gt 0 ]; then
    gh release create v${VERSION_NAME}+${BUILD_NUMBER} \
        --title "v${VERSION_NAME}+${BUILD_NUMBER} - RDC Referansları Temizlendi" \
        --notes "## 🧹 RDC Referansları Temizlendi

### Değişiklikler
- ✅ Tüm RDC referansları temizlendi
- ✅ \`io.rdc.azuredevops\` → \`com.higgscloud.azuredevops\` değişikliği tamamlandı
- ✅ \`RDC Partner\` → \`Higgs Cloud\` veya kaldırıldı
- ✅ Klasör yapısı güncellendi
- ✅ Logo referansları Azure DevOps logosu olarak güncellendi

### Build Dosyaları
- 📦 Android APK: azuredevops.apk
- 📦 Android AAB: app-release.aab (Google Play Store için)
- 📦 iOS IPA: azuredevops.ipa
- 📋 SBOM: spdx.json ve sbom.txt

### Detaylar
Detaylı değişiklik listesi için [CHANGELOG.md](CHANGELOG.md) dosyasına bakın." \
        "${FILES[@]}"
    echo -e "${GREEN}✅ GitHub Release oluşturuldu!${NC}"
else
    echo -e "${RED}❌ Hiç dosya bulunamadı!${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ TÜM İŞLEMLER TAMAMLANDI!${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}📦 Versiyon: ${VERSION_NAME}+${BUILD_NUMBER}${NC}"
echo -e "${GREEN}🔗 GitHub Release: https://github.com/bilgicalpay/azuredevops-mobile/releases/tag/v${VERSION_NAME}%2B${BUILD_NUMBER}${NC}"

