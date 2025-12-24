#!/bin/bash

# Interactive Build Script - Tüm build işlemlerini adım adım yapar
# v1.2.0+84 için build ve release işlemleri

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

# Set Flutter path
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
FLUTTER_CMD="/Users/alpaybilgic/flutter/bin/flutter"

VERSION_NAME="1.2.0"
BUILD_NUMBER="84"

echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}🚀 Interactive Build & Release - v${VERSION_NAME}+${BUILD_NUMBER}${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

# Step 1: Clean
echo -e "${GREEN}1️⃣  Flutter clean yapılıyor...${NC}"
$FLUTTER_CMD clean
echo -e "${GREEN}✅ Clean tamamlandı${NC}"
echo ""

# Step 2: Pub get
echo -e "${GREEN}2️⃣  Dependencies yükleniyor...${NC}"
$FLUTTER_CMD pub get
echo -e "${GREEN}✅ Pub get tamamlandı${NC}"
echo ""

# Step 3: Build Android APK
echo -e "${GREEN}3️⃣  Android APK build başlatılıyor...${NC}"
$FLUTTER_CMD build apk --release --build-name=${VERSION_NAME} --build-number=${BUILD_NUMBER}
if [ -f "build/app/outputs/apk/release/azuredevops.apk" ]; then
    APK_SIZE=$(ls -lh build/app/outputs/apk/release/azuredevops.apk | awk '{print $5}')
    echo -e "${GREEN}✅ APK build tamamlandı! (${APK_SIZE})${NC}"
else
    echo -e "${RED}❌ APK build başarısız!${NC}"
    exit 1
fi
echo ""

# Step 4: Build Android AAB
echo -e "${GREEN}4️⃣  Android AAB build başlatılıyor...${NC}"
$FLUTTER_CMD build appbundle --release --build-name=${VERSION_NAME} --build-number=${BUILD_NUMBER}
if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    AAB_SIZE=$(ls -lh build/app/outputs/bundle/release/app-release.aab | awk '{print $5}')
    echo -e "${GREEN}✅ AAB build tamamlandı! (${AAB_SIZE})${NC}"
else
    echo -e "${RED}❌ AAB build başarısız!${NC}"
    exit 1
fi
echo ""

# Step 5: Build iOS IPA
echo -e "${GREEN}5️⃣  iOS IPA build başlatılıyor...${NC}"
$FLUTTER_CMD build ios --release --build-name=${VERSION_NAME} --build-number=${BUILD_NUMBER}
if [ -f "build/ios/ipa/azuredevops.ipa" ]; then
    IPA_SIZE=$(ls -lh build/ios/ipa/azuredevops.ipa | awk '{print $5}')
    echo -e "${GREEN}✅ IPA build tamamlandı! (${IPA_SIZE})${NC}"
else
    echo -e "${YELLOW}⚠️  IPA dosyası bulunamadı, kontrol ediliyor...${NC}"
    find build/ios -name "*.ipa" 2>/dev/null | head -1
fi
echo ""

# Step 6: Generate SBOM
echo -e "${GREEN}6️⃣  SBOM oluşturuluyor...${NC}"
if [ -f "scripts/generate_sbom.sh" ]; then
    bash scripts/generate_sbom.sh
    if [ -f "build/sbom/spdx.json" ]; then
        echo -e "${GREEN}✅ SBOM oluşturuldu${NC}"
    else
        echo -e "${YELLOW}⚠️  SBOM dosyası bulunamadı${NC}"
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
ls -lh build/app/outputs/apk/release/azuredevops.apk build/app/outputs/bundle/release/app-release.aab build/ios/ipa/azuredevops.ipa 2>/dev/null | awk '{print "  -", $9, "(" $5 ")"}'
echo ""
echo -e "${GREEN}✅ SBOM Dosyaları:${NC}"
ls -lh build/sbom/*.json build/sbom/*.txt 2>/dev/null | awk '{print "  -", $9, "(" $5 ")"}' || echo "  - SBOM dosyaları bulunamadı"
echo ""

# Step 8: Git operations
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}📝 Git İşlemleri${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}7️⃣  Git status kontrol ediliyor...${NC}"
git status --short | head -10
echo ""

read -p "Git commit yapılsın mı? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}8️⃣  Git commit yapılıyor...${NC}"
    git add -A
    git commit -m "chore: RDC referansları temizlendi - v${VERSION_NAME}+${BUILD_NUMBER}

- io.rdc.azuredevops -> com.higgscloud.azuredevops
- RDC Partner -> Higgs Cloud veya kaldırıldı
- Klasör yapısı güncellendi
- Logo referansları güncellendi
- CHANGELOG güncellendi
- Build dosyaları oluşturuldu"
    echo -e "${GREEN}✅ Commit tamamlandı${NC}"
    echo ""
    
    read -p "Git push yapılsın mı? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}9️⃣  Git push yapılıyor...${NC}"
        git push origin develop
        echo -e "${GREEN}✅ Push tamamlandı${NC}"
        echo ""
        
        read -p "Git tag oluşturulsun mu? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${GREEN}🔟 Git tag oluşturuluyor...${NC}"
            git tag -a v${VERSION_NAME}+${BUILD_NUMBER} -m "Release v${VERSION_NAME}+${BUILD_NUMBER}: RDC referansları temizlendi"
            git push origin v${VERSION_NAME}+${BUILD_NUMBER}
            echo -e "${GREEN}✅ Tag oluşturuldu ve push edildi${NC}"
            echo ""
            
            read -p "GitHub Release oluşturulsun mu? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo -e "${GREEN}1️⃣1️⃣ GitHub Release oluşturuluyor...${NC}"
                gh release delete v${VERSION_NAME}+${BUILD_NUMBER} -y 2>&1 || true
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
                    build/app/outputs/apk/release/azuredevops.apk \
                    build/app/outputs/bundle/release/app-release.aab \
                    build/ios/ipa/azuredevops.ipa \
                    build/sbom/spdx.json \
                    build/sbom/sbom.txt \
                    CHANGELOG.md 2>&1
                echo -e "${GREEN}✅ GitHub Release oluşturuldu${NC}"
            fi
        fi
    fi
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

