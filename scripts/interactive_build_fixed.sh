#!/bin/bash

# Interactive Build Script - Hata yakalama ile
# v1.2.0+84 için build ve release işlemleri

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

# Error handler
handle_error() {
    echo -e "${RED}❌ HATA: $1${NC}"
    echo -e "${YELLOW}Devam etmek için Enter'a basın, çıkmak için Ctrl+C${NC}"
    read
}

echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}🚀 Interactive Build & Release - v${VERSION_NAME}+${BUILD_NUMBER}${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

# Step 1: Clean
echo -e "${GREEN}1️⃣  Flutter clean yapılıyor...${NC}"
if ! $FLUTTER_CMD clean; then
    handle_error "Flutter clean başarısız!"
    exit 1
fi
echo -e "${GREEN}✅ Clean tamamlandı${NC}"
echo ""

# Step 2: Pub get
echo -e "${GREEN}2️⃣  Dependencies yükleniyor...${NC}"
if ! $FLUTTER_CMD pub get; then
    handle_error "Pub get başarısız!"
    exit 1
fi
echo -e "${GREEN}✅ Pub get tamamlandı${NC}"
echo ""

# Step 3: Build Android APK
echo -e "${GREEN}3️⃣  Android APK build başlatılıyor...${NC}"
if ! $FLUTTER_CMD build apk --release --build-name=${VERSION_NAME} --build-number=${BUILD_NUMBER}; then
    handle_error "Android APK build başarısız!"
    exit 1
fi

# Check APK location
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
    handle_error "APK dosyası bulunamadı!"
    find build -name "*.apk" 2>/dev/null | head -5
    exit 1
fi
echo ""

# Step 4: Build Android AAB
echo -e "${GREEN}4️⃣  Android AAB build başlatılıyor...${NC}"
if ! $FLUTTER_CMD build appbundle --release --build-name=${VERSION_NAME} --build-number=${BUILD_NUMBER}; then
    handle_error "Android AAB build başarısız!"
    exit 1
fi

if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    AAB_SIZE=$(ls -lh build/app/outputs/bundle/release/app-release.aab | awk '{print $5}')
    echo -e "${GREEN}✅ AAB build tamamlandı! (${AAB_SIZE})${NC}"
else
    handle_error "AAB dosyası bulunamadı!"
    find build -name "*.aab" 2>/dev/null | head -5
    exit 1
fi
echo ""

# Step 5: Build iOS IPA (optional, may fail)
echo -e "${GREEN}5️⃣  iOS IPA build başlatılıyor...${NC}"
if $FLUTTER_CMD build ios --release --build-name=${VERSION_NAME} --build-number=${BUILD_NUMBER} 2>&1; then
    if [ -f "build/ios/ipa/azuredevops.ipa" ]; then
        IPA_SIZE=$(ls -lh build/ios/ipa/azuredevops.ipa | awk '{print $5}')
        echo -e "${GREEN}✅ IPA build tamamlandı! (${IPA_SIZE})${NC}"
    else
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
    echo -e "${YELLOW}⚠️  iOS build başarısız veya atlandı (normal olabilir)${NC}"
fi
echo ""

# Step 6: Generate SBOM
echo -e "${GREEN}6️⃣  SBOM oluşturuluyor...${NC}"
if [ -f "scripts/generate_sbom.sh" ]; then
    if bash scripts/generate_sbom.sh 2>&1; then
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

# Summary
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}📦 Build Özeti${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}✅ Build Dosyaları:${NC}"
ls -lh build/app/outputs/apk/release/azuredevops.apk build/app/outputs/bundle/release/app-release.aab build/ios/ipa/azuredevops.ipa 2>/dev/null | awk '{print "  -", $9, "(" $5 ")"}' || echo "  - Bazı dosyalar bulunamadı"
echo ""

# Git operations (interactive)
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}📝 Git İşlemleri${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

read -p "Git commit yapılsın mı? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
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

    read -p "Git push yapılsın mı? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}8️⃣  Git push yapılıyor...${NC}"
        if git push origin develop; then
            echo -e "${GREEN}✅ Push tamamlandı${NC}"
        else
            handle_error "Push başarısız!"
        fi
        echo ""

        read -p "Git tag oluşturulsun mu? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${GREEN}9️⃣  Git tag oluşturuluyor...${NC}"
            git tag -a v${VERSION_NAME}+${BUILD_NUMBER} -m "Release v${VERSION_NAME}+${BUILD_NUMBER}: RDC referansları temizlendi" 2>/dev/null || echo "Tag zaten var"
            if git push origin v${VERSION_NAME}+${BUILD_NUMBER}; then
                echo -e "${GREEN}✅ Tag push edildi${NC}"
            else
                echo -e "${YELLOW}⚠️  Tag push yapılamadı${NC}"
            fi
            echo ""

            read -p "GitHub Release oluşturulsun mu? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo -e "${GREEN}🔟 GitHub Release oluşturuluyor...${NC}"
                
                # Check GitHub CLI authentication
                if ! gh auth status &>/dev/null; then
                    echo -e "${RED}❌ GitHub CLI authentication gerekli!${NC}"
                    echo -e "${YELLOW}Lütfen 'gh auth login' komutunu çalıştırın${NC}"
                    handle_error "GitHub CLI authentication yok!"
                    exit 1
                fi
                
                # Check if release exists and delete it
                echo -e "${YELLOW}Mevcut release kontrol ediliyor...${NC}"
                gh release delete v${VERSION_NAME}+${BUILD_NUMBER} -y 2>&1 || echo "Release yok veya silinemedi (normal olabilir)"
                
                # Prepare file list
                FILES=()
                if [ -f "build/app/outputs/apk/release/azuredevops.apk" ]; then
                    FILES+=("build/app/outputs/apk/release/azuredevops.apk")
                    echo -e "${GREEN}✅ APK bulundu${NC}"
                else
                    echo -e "${YELLOW}⚠️  APK bulunamadı${NC}"
                fi
                
                if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
                    FILES+=("build/app/outputs/bundle/release/app-release.aab")
                    echo -e "${GREEN}✅ AAB bulundu${NC}"
                else
                    echo -e "${YELLOW}⚠️  AAB bulunamadı${NC}"
                fi
                
                if [ -f "build/ios/ipa/azuredevops.ipa" ]; then
                    FILES+=("build/ios/ipa/azuredevops.ipa")
                    echo -e "${GREEN}✅ IPA bulundu${NC}"
                else
                    echo -e "${YELLOW}⚠️  IPA bulunamadı (opsiyonel)${NC}"
                fi
                
                if [ -f "build/sbom/spdx.json" ]; then
                    FILES+=("build/sbom/spdx.json")
                    echo -e "${GREEN}✅ SBOM JSON bulundu${NC}"
                else
                    echo -e "${YELLOW}⚠️  SBOM JSON bulunamadı${NC}"
                fi
                
                if [ -f "build/sbom/sbom.txt" ]; then
                    FILES+=("build/sbom/sbom.txt")
                    echo -e "${GREEN}✅ SBOM TXT bulundu${NC}"
                else
                    echo -e "${YELLOW}⚠️  SBOM TXT bulunamadı${NC}"
                fi
                
                if [ -f "CHANGELOG.md" ]; then
                    FILES+=("CHANGELOG.md")
                    echo -e "${GREEN}✅ CHANGELOG bulundu${NC}"
                else
                    echo -e "${YELLOW}⚠️  CHANGELOG bulunamadı${NC}"
                fi
                
                if [ ${#FILES[@]} -eq 0 ]; then
                    handle_error "Hiç dosya bulunamadı! Release oluşturulamaz."
                    exit 1
                fi
                
                echo -e "${GREEN}📦 ${#FILES[@]} dosya yüklenecek...${NC}"
                
                # Create release with files
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
                    echo -e "${GREEN}🔗 https://github.com/bilgicalpay/azuredevops-mobile/releases/tag/v${VERSION_NAME}%2B${BUILD_NUMBER}${NC}"
                else
                    echo -e "${RED}❌ GitHub Release oluşturma hatası!${NC}"
                    echo -e "${YELLOW}Detaylı hata için: gh release create --help${NC}"
                    echo -e "${YELLOW}Veya manuel olarak GitHub web arayüzünden oluşturabilirsiniz${NC}"
                    handle_error "GitHub Release oluşturulamadı!"
                fi
            fi
        fi
    fi
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ İŞLEMLER TAMAMLANDI!${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}📦 Versiyon: ${VERSION_NAME}+${BUILD_NUMBER}${NC}"
echo -e "${GREEN}🧹 RDC referansları temizlendi${NC}"
echo ""
echo -e "${GREEN}✅ GitHub Release: https://github.com/bilgicalpay/azuredevops-mobile/releases/tag/v${VERSION_NAME}%2B${BUILD_NUMBER}${NC}"

