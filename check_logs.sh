#!/bin/bash

# Android Logcat kontrol scripti
# Bu script adb'yi kullanarak uygulama loglarını gösterir

ADB_PATH="$HOME/Library/Android/sdk/platform-tools/adb"

if [ ! -f "$ADB_PATH" ]; then
    echo "❌ adb bulunamadı: $ADB_PATH"
    echo "Lütfen Android SDK'nın doğru kurulduğundan emin olun."
    exit 1
fi

echo "📱 Android cihazlarını kontrol ediliyor..."
$ADB_PATH devices

echo ""
echo "📋 Loglar filtreleniyor (Ctrl+C ile durdur)..."
echo "Filtre: flutter, azuredevops, error, fatal"
echo ""

$ADB_PATH logcat -c  # Önceki logları temizle
$ADB_PATH logcat | grep -iE "flutter|azuredevops|error|fatal|exception|crash" --color=always

