#!/bin/bash
# iOS Build Script

echo "🔨 iOS Build Başlatılıyor..."

# CocoaPods kontrolü
if ! command -v pod &> /dev/null; then
    echo "❌ CocoaPods bulunamadı. Lütfen yükleyin:"
    echo "   sudo gem install cocoapods"
    exit 1
fi

# CocoaPods bağımlılıklarını yükle
echo "📦 CocoaPods bağımlılıkları yükleniyor..."
cd ios
pod install
cd ..

# Flutter build
echo "🏗️  Flutter iOS build başlatılıyor..."
flutter build ios --release --no-codesign

# IPA build (eğer codesigning varsa)
if [ -d "ios/Runner.xcworkspace" ]; then
    echo "📱 IPA build başlatılıyor..."
    flutter build ipa --release || echo "⚠️  IPA build için codesigning gerekli"
fi

echo "✅ Build tamamlandı!"
echo "📦 IPA dosyası: build/ios/ipa/azuredevops_onprem.ipa"
