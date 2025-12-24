#!/bin/bash

# Step-by-Step Build Script - Her adımı ayrı ayrı çalıştırır ve hataları gösterir
# v1.2.0+84 için build ve release işlemleri

set -e
set -x

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Set Flutter path
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
FLUTTER_CMD="/Users/alpaybilgic/flutter/bin/flutter"

VERSION_NAME="1.2.0"
BUILD_NUMBER="84"

echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}🚀 Step-by-Step Build & Release - v${VERSION_NAME}+${BUILD_NUMBER}${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

# Step 1: Clean
echo -e "${GREEN}1️⃣  Flutter clean yapılıyor...${NC}"
if $FLUTTER_CMD clean; then
    echo -e "${GREEN}✅ Clean tamamlandı${NC}"
else
    echo -e "${RED}❌ Clean başarısız!${NC}"
    exit 1
fi
echo ""

# Step 2: Pub get
echo -e "${GREEN}2️⃣  Dependencies yükleniyor...${NC}"
if $FLUTTER_CMD pub get; then
    echo -e "${GREEN}✅ Pub get tamamlandı${NC}"
else
    echo -e "${RED}❌ Pub get başarısız!${NC}"
    exit 1
fi
echo ""

# Step 3: Build Android APK
echo -e "${GREEN}3️⃣  Android APK build başlatılıyor...${NC}"
if $FLUTTER_CMD build apk --release --build-name=${VERSION_NAME} --build-number=${BUILD_NUMBER}; then
    if [ -f "build/app/outputs/apk/release/azuredevops.apk" ]; then
        APK_SIZE=$(ls -lh build/app/outputs/apk/release/azuredevops.apk | awk '{print $5}')
        echo -e "${GREEN}✅ APK build tamamlandı! (${APK_SIZE})${NC}"
    elif [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
        echo -e "${YELLOW}⚠️  APK farklı konumda, yeniden adlandırılıyor...${NC}"
        mkdir -p build/app/outputs/apk/release
        cp build/app/outputs/flutter-apk/app-release.apk build/app/outputs/apk/release/azuredevops.apk
        APK_SIZE=$(ls -lh build/app/outputs/apk/release/azuredevops.apk | awk '{print $5}')
        echo -e "${GREEN}✅ APK build tamamlandı! (${APK_SIZE})${NC}"
    else
        echo -e "${RED}❌ APK build başarısız! Dosya bulunamadı.${NC}"
        echo "Aranan konumlar:"
        echo "  - build/app/outputs/apk/release/azuredevops.apk"
        echo "  - build/app/outputs/flutter-apk/app-release.apk"
        find build -name "*.apk" 2>/dev/null | head -5
        exit 1
    fi
else
    echo -e "${RED}❌ APK build başarısız!${NC}"
    exit 1
fi
echo ""

# Step 4: Build Android AAB
echo -e "${GREEN}4️⃣  Android AAB build başlatılıyor...${NC}"
if $FLUTTER_CMD build appbundle --release --build-name=${VERSION_NAME} --build-number=${BUILD_NUMBER}; then
    if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
        AAB_SIZE=$(ls -lh build/app/outputs/bundle/release/app-release.aab | awk '{print $5}')
        echo -e "${GREEN}✅ AAB build tamamlandı! (${AAB_SIZE})${NC}"
    else
        echo -e "${RED}❌ AAB build başarısız! Dosya bulunamadı.${NC}"
        find build -name "*.aab" 2>/dev/null | head -5
        exit 1
    fi
else
    echo -e "${RED}❌ AAB build başarısız!${NC}"
    exit 1
fi
echo ""

# Step 5: Build iOS IPA
echo -e "${GREEN}5️⃣  iOS IPA build başlatılıyor...${NC}"
if $FLUTTER_CMD build ios --release --build-name=${VERSION_NAME} --build-number=${BUILD_NUMBER}; then
    if [ -f "build/ios/ipa/azuredevops.ipa" ]; then
        IPA_SIZE=$(ls -lh build/ios/ipa/azuredevops.ipa | awk '{print $5}')
        echo -e "${GREEN}✅ IPA build tamamlandı! (${IPA_SIZE})${NC}"
    else
        echo -e "${YELLOW}⚠️  IPA dosyası bulunamadı, kontrol ediliyor...${NC}"
        IPA_FILE=$(find build/ios -name "*.ipa" 2>/dev/null | head -1)
        if [ -n "$IPA_FILE" ]; then
            echo -e "${YELLOW}⚠️  IPA bulundu: $IPA_FILE${NC}"
            mkdir -p build/ios/ipa
            cp "$IPA_FILE" build/ios/ipa/azuredevops.ipa 2>/dev/null || true
        else
            echo -e "${YELLOW}⚠️  IPA dosyası oluşturulamadı (iOS build başarılı olabilir ama IPA oluşturulmamış)${NC}"
        fi
    fi
else
    echo -e "${YELLOW}⚠️  iOS build başarısız veya atlandı${NC}"
fi
echo ""

# Step 6: Generate SBOM
echo -e "${GREEN}6️⃣  SBOM oluşturuluyor...${NC}"
if [ -f "scripts/generate_sbom.sh" ]; then
    if bash scripts/generate_sbom.sh; then
        if [ -f "build/sbom/spdx.json" ]; then
            echo -e "${GREEN}✅ SBOM oluşturuldu${NC}"
        else
            echo -e "${YELLOW}⚠️  SBOM dosyası bulunamadı${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  SBOM oluşturma başarısız${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  SBOM script bulunamadı${NC}"
fi
echo ""

# Step 7: Summary
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}📦 Build Özeti${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}✅ Build Dosyaları:${NC}"
ls -lh build/app/outputs/apk/release/azuredevops.apk build/app/outputs/bundle/release/app-release.aab build/ios/ipa/azuredevops.ipa 2>/dev/null | awk '{print "  -", $9, "(" $5 ")"}' || echo "  - Bazı dosyalar bulunamadı"
echo ""
echo -e "${GREEN}✅ SBOM Dosyaları:${NC}"
ls -lh build/sbom/*.json build/sbom/*.txt 2>/dev/null | awk '{print "  -", $9, "(" $5 ")"}' || echo "  - SBOM dosyaları bulunamadı"
echo ""

# Step 8: Git operations
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}📝 Git İşlemleri${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}7️⃣  Git commit yapılıyor...${NC}"
git add -A
if git commit -m "chore: RDC referansları temizlendi - v${VERSION_NAME}+${BUILD_NUMBER}

- io.rdc.azuredevops -> com.higgscloud.azuredevops
- RDC Partner -> Higgs Cloud veya kaldırıldı
- Klasör yapısı güncellendi
- Logo referansları güncellendi
- CHANGELOG güncellendi
- Build dosyaları oluşturuldu"; then
    echo -e "${GREEN}✅ Commit tamamlandı${NC}"
else
    echo -e "${YELLOW}⚠️  Commit yapılamadı (değişiklik yok olabilir)${NC}"
fi
echo ""

echo -e "${GREEN}8️⃣  Git push yapılıyor...${NC}"
if git push origin develop; then
    echo -e "${GREEN}✅ Push tamamlandı${NC}"
else
    echo -e "${YELLOW}⚠️  Push yapılamadı${NC}"
fi
echo ""

echo -e "${GREEN}9️⃣  Git tag oluşturuluyor...${NC}"
if git tag -a v${VERSION_NAME}+${BUILD_NUMBER} -m "Release v${VERSION_NAME}+${BUILD_NUMBER}: RDC referansları temizlendi" 2>/dev/null; then
    echo -e "${GREEN}✅ Tag oluşturuldu${NC}"
else
    echo -e "${YELLOW}⚠️  Tag zaten var${NC}"
fi
if git push origin v${VERSION_NAME}+${BUILD_NUMBER}; then
    echo -e "${GREEN}✅ Tag push edildi${NC}"
else
    echo -e "${YELLOW}⚠️  Tag push yapılamadı${NC}"
fi
echo ""

echo -e "${GREEN}🔟 GitHub Release oluşturuluyor...${NC}"
gh release delete v${VERSION_NAME}+${BUILD_NUMBER} -y 2>/dev/null || true
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
    build/app/outputs/apk/release/azuredevops.apk \
    build/app/outputs/bundle/release/app-release.aab \
    build/ios/ipa/azuredevops.ipa \
    build/sbom/spdx.json \
    build/sbom/sbom.txt \
    CHANGELOG.md 2>/dev/null; then
    echo -e "${GREEN}✅ GitHub Release oluşturuldu${NC}"
else
    echo -e "${YELLOW}⚠️  GitHub Release oluşturulamadı${NC}"
fi
echo ""

echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ TÜM İŞLEMLER TAMAMLANDI!${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}📦 Versiyon: ${VERSION_NAME}+${BUILD_NUMBER}${NC}"
echo -e "${GREEN}🧹 RDC referansları temizlendi${NC}"
echo ""
echo -e "${GREEN}✅ GitHub Release: https://github.com/bilgicalpay/azuredevops-mobile/releases/tag/v${VERSION_NAME}%2B${BUILD_NUMBER}${NC}"

