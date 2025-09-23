#!/bin/bash
set -e

echo "🚀 Flutter App Setup Script (Interactive Mode)"

# 1️⃣ App Name
while [ -z "$APP_NAME" ]; do
  read -p "Enter App Name: " APP_NAME
  if [ -z "$APP_NAME" ]; then
    echo "❌ App Name is required!"
  fi
done

# 2️⃣ Package Name
while [ -z "$PACKAGE_NAME" ]; do
  read -p "Enter Package Name: " PACKAGE_NAME
  if [ -z "$PACKAGE_NAME" ]; then
    echo "❌ Package Name is required!"
  fi
done

# 3️⃣ Main Domain
while [ -z "$MAIN_DOMAIN" ]; do
  read -p "Enter Main Domain: " MAIN_DOMAIN
  if [ -z "$MAIN_DOMAIN" ]; then
    echo "❌ Main Domain is required!"
  fi
done

# 4️⃣ Optional Icon Path
read -p "Enter Launcher Icon Path (default: assets/logo): " ICON_PATH
ICON_PATH=${ICON_PATH:-assets/logo}

# 5️⃣ Git Branch (default: current branch)
read -p "Enter Git Branch Name (default: current branch): " BRANCH_NAME
BRANCH_NAME=${BRANCH_NAME:-$(git branch --show-current)}

echo ""
echo "✅ Inputs received:"
echo "   App Name    : $APP_NAME"
echo "   Package Name: $PACKAGE_NAME"
echo "   Main Domain : $MAIN_DOMAIN"
echo "   Icon Path   : $ICON_PATH"
echo "   Git Branch  : $BRANCH_NAME"
echo ""

# Flutter packages
echo "📦 Getting Flutter packages..."
flutter pub get

# Rename app
echo "✏️ Renaming app..."
flutter pub run rename_app:main all="$APP_NAME"

# Change package name
echo "📦 Changing package name..."
flutter pub run change_app_package_name:main "$PACKAGE_NAME"

# Update launcher icons
echo "🎨 Updating launcher icons..."
flutter pub run flutter_launcher_icons --image-path "$ICON_PATH"

# Update domain in api_endpoint.dart
API_FILE="lib/backend/services/api_endpoint.dart"
if [ -f "$API_FILE" ]; then
  echo "🌐 Updating mainDomain in $API_FILE..."
  sed -i.bak "s|static const String mainDomain = .*|static const String mainDomain = \"$MAIN_DOMAIN\";|" "$API_FILE"
else
  echo "⚠️ $API_FILE not found!"
fi

# Build APKs (split per ABI)
echo "⚒️ Building split APKs..."
flutter build apk --release \
  --target-platform android-arm,android-arm64,android-x64 \
  --split-per-abi

# Git commit + push
echo "📤 Committing & pushing changes..."
git add .
git commit -m "chore: setup $APP_NAME ($PACKAGE_NAME) with mainDomain $MAIN_DOMAIN"
git push origin "$BRANCH_NAME"

echo "✅ Done! APKs available at: build/app/outputs/flutter-apk/"
ls -lh build/app/outputs/flutter-apk/*.apk
