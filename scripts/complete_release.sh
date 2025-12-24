#!/bin/bash

# Complete Release Script - IPA oluşturur ve GitHub'a gönderir
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
echo -e "${BLUE}🚀 Complete Release - v${VERSION_NAME}+${BUILD_NUMBER}${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

# Step 1: Create IPA
echo -e "${GREEN}1️⃣  IPA oluşturuluyor...${NC}"
if [ -f "scripts/create_ipa.sh" ]; then
    bash scripts/create_ipa.sh
else
    echo -e "${YELLOW}⚠️  create_ipa.sh bulunamadı, Flutter build ipa deneniyor...${NC}"
    $FLUTTER_CMD build ipa --release --build-name=${VERSION_NAME} --build-number=${BUILD_NUMBER} 2>&1 | tail -20 || true
    IPA_FILE=$(find build/ios/ipa -name "*.ipa" 2>/dev/null | head -1)
    if [ -n "$IPA_FILE" ] && [ -f "$IPA_FILE" ]; then
        mkdir -p build/ios/ipa
        cp "$IPA_FILE" build/ios/ipa/azuredevops.ipa 2>/dev/null || mv "$IPA_FILE" build/ios/ipa/azuredevops.ipa 2>/dev/null || true
    fi
fi

if [ -f "build/ios/ipa/azuredevops.ipa" ]; then
    IPA_SIZE=$(ls -lh build/ios/ipa/azuredevops.ipa | awk '{print $5}')
    echo -e "${GREEN}✅ IPA oluşturuldu! (${IPA_SIZE})${NC}"
else
    echo -e "${YELLOW}⚠️  IPA oluşturulamadı (opsiyonel)${NC}"
fi
echo ""

# Step 2: Git operations
echo -e "${GREEN}2️⃣  Git commit yapılıyor...${NC}"
git add -A
if git commit -m "chore: RDC referansları temizlendi ve build dosyaları oluşturuldu - v${VERSION_NAME}+${BUILD_NUMBER}

- io.rdc.azuredevops -> com.higgscloud.azuredevops
- RDC Partner -> Higgs Cloud veya kaldırıldı
- Klasör yapısı güncellendi
- Logo referansları güncellendi
- CHANGELOG güncellendi
- Build dosyaları oluşturuldu (APK, AAB, IPA)"; then
    echo -e "${GREEN}✅ Commit tamamlandı${NC}"
else
    echo -e "${YELLOW}⚠️  Commit yapılamadı (değişiklik yok olabilir)${NC}"
fi
echo ""

echo -e "${GREEN}3️⃣  Git push yapılıyor...${NC}"
if git push origin develop; then
    echo -e "${GREEN}✅ Push tamamlandı${NC}"
else
    echo -e "${RED}❌ Push başarısız!${NC}"
    exit 1
fi
echo ""

echo -e "${GREEN}4️⃣  Git tag oluşturuluyor...${NC}"
git tag -a v${VERSION_NAME}+${BUILD_NUMBER} -m "Release v${VERSION_NAME}+${BUILD_NUMBER}: RDC referansları temizlendi" 2>/dev/null || echo "Tag zaten var"
if git push origin v${VERSION_NAME}+${BUILD_NUMBER}; then
    echo -e "${GREEN}✅ Tag push edildi${NC}"
else
    echo -e "${YELLOW}⚠️  Tag push yapılamadı${NC}"
fi
echo ""

# Step 3: GitHub Release
echo -e "${GREEN}5️⃣  GitHub Release oluşturuluyor...${NC}"
gh release delete v${VERSION_NAME}+${BUILD_NUMBER} -y 2>&1 || true

FILES=()
[ -f "build/app/outputs/apk/release/azuredevops.apk" ] && FILES+=("build/app/outputs/apk/release/azuredevops.apk") && echo "✅ APK eklendi"
[ -f "build/app/outputs/bundle/release/app-release.aab" ] && FILES+=("build/app/outputs/bundle/release/app-release.aab") && echo "✅ AAB eklendi"
[ -f "build/ios/ipa/azuredevops.ipa" ] && FILES+=("build/ios/ipa/azuredevops.ipa") && echo "✅ IPA eklendi"
[ -f "build/sbom/spdx.json" ] && FILES+=("build/sbom/spdx.json") && echo "✅ SBOM JSON eklendi"
[ -f "build/sbom/sbom.txt" ] && FILES+=("build/sbom/sbom.txt") && echo "✅ SBOM TXT eklendi"
[ -f "CHANGELOG.md" ] && FILES+=("CHANGELOG.md") && echo "✅ CHANGELOG eklendi"

echo ""
echo "Toplam ${#FILES[@]} dosya yüklenecek"

if [ ${#FILES[@]} -gt 0 ]; then
    if gh release create v${VERSION_NAME}+${BUILD_NUMBER} \
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
        "${FILES[@]}"; then
        echo -e "${GREEN}✅ GitHub Release oluşturuldu!${NC}"
    else
        echo -e "${RED}❌ GitHub Release oluşturulamadı!${NC}"
        exit 1
    fi
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

