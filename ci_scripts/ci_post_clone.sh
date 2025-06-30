#!/bin/bash

# エラー発生時に停止
set -e

echo "🔄 Xcode Cloud CI/CD Post-Clone Script Started"

# Flutterのパスが通っているか確認
if command -v flutter &> /dev/null
then
    echo "✅ Flutter is installed and available"
else
    echo "❌ Flutter command not found. Please make sure Flutter is installed on the CI environment."
    exit 1
fi

# Flutterバージョン表示
echo "📋 Flutter Version Information:"
flutter --version

# Flutter依存関係の解決
echo "📦 Installing Flutter dependencies..."
flutter pub get

# CocoaPodsがインストールされているか確認
if command -v pod &> /dev/null
then
    echo "✅ CocoaPods is installed and available"
else
    echo "❌ CocoaPods command not found. Installing CocoaPods..."
    sudo gem install cocoapods
fi

# iOS向け依存関係の解決
echo "🍎 Installing iOS dependencies..."
cd ios
pod install --repo-update
cd ..

echo "✅ Xcode Cloud CI/CD Post-Clone Script Completed Successfully"
