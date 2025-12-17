#!/bin/bash

# iOS Deploy Script
# Bu script iOS uygulamasını cihaza deploy eder

set -e

echo "📱 iOS Deploy Başlatılıyor..."

# Flutter build
echo "🏗️  Flutter iOS build başlatılıyor..."
flutter build ios --release --no-codesign

# Xcode ile deploy
echo "📲 Xcode ile deploy ediliyor..."
cd ios

# Xcode workspace'i aç ve deploy et
if command -v xcodebuild &> /dev/null; then
    echo "✅ Xcode bulundu"
    echo ""
    echo "📋 Manuel Deploy Adımları:"
    echo "1. Xcode'u açın:"
    echo "   open Runner.xcworkspace"
    echo ""
    echo "2. Xcode'da:"
    echo "   - Sol üstten cihazınızı seçin"
    echo "   - Product > Destination > Your Device seçin"
    echo "   - Product > Run (⌘R) ile deploy edin"
    echo ""
    echo "3. İlk kez deploy ediyorsanız:"
    echo "   - Xcode > Settings > Accounts"
    echo "   - Apple ID'nizi ekleyin"
    echo "   - Signing & Capabilities'de 'Automatically manage signing' işaretleyin"
    echo "   - Team seçin"
    echo ""
    echo "Alternatif: IPA oluşturup cihaza yükleme"
    echo "  flutter build ipa --release"
    echo "  IPA dosyası: build/ios/ipa/azuredevops_onprem.ipa"
else
    echo "❌ Xcode bulunamadı"
    exit 1
fi

cd ..

echo "✅ Deploy hazır!"

