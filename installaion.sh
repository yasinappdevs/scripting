#!/bin/bash
set -e

echo "🚀 Flutter App Setup Script (Interactive Mode)"

# Step 1: Ask for App Name
read -p "Enter App Name: " APP_NAME
if [ -z "$APP_NAME" ]; then
  echo "❌ App Name is required!"
  exit 1
fi

# Step 2: Ask for Package Name
read -p "Enter Package Name: " PACKAGE_NAME
if [ -z "$PACKAGE_NAME" ]; then
  echo "❌ Package Name is required!"
  exit 1
fi

# Step 3: Ask for Main Domain
read -p "Enter Main Domain: " MAIN_DOMAIN
if [ -z "$MAIN_DOMAIN" ]; then
  echo "❌ Main Domain is required!"
  exit 1
fi

# Step 4: Optional Icon Path
read -p "Enter Launcher Icon Path (default: assets/logo): " ICON_PATH
ICON_PATH=${ICON_PATH:-assets/logo}

# Step 5: Git Branch
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

# Step 6: Flutter packages
echo "📦 Getting Flutter packages..."
flutter pub get

# Step 7: Rename app
echo "✏️ Renaming app..."
flutter pub run rename_app:main all="$APP_NAME"

# Step 8: Change package name
echo "📦 Changing package name..."
flutter pub run change_app_package_name:main "$PACKAGE_NAME"

# Step 9: Update launcher icons
echo "🎨 Updating launcher icons..."
flutter pub run flutter_launcher_icons --image-path "$ICON_PATH"

# Step 10: Update domain in api_endpoint.dart
API_FILE="lib/backend/services/api_endpoint.dart"
if [ -f "$API_FILE" ]; then
  echo "🌐 Updating mainDomain in $API_FILE..."
  sed -i.bak "s|static const String mainDomain = .*|static const String mainDomain = \"$MAIN_DOMAIN\";|" "$API_FILE"
else
  echo "⚠️ $API_FILE not found!"
fi

# Step 11: Build APKs (split per ABI)
echo "⚒️ Building split APKs..."
flutter build apk --release \
  --target-platform android-arm,android-arm64,android-x64 \
  --split-per-abi

# Step 12: Commit & push
echo "📤 Committing & pushing changes..."
git add .
git commit -m "chore: setup $APP_NAME ($PACKAGE_NAME) with mainDomain $MAIN_DOMAIN"
git push origin "$BRANCH_NAME"

echo "✅ Done! APKs available at: build/app/outputs/flutter-apk/"
ls -lh build/app/outputs/flutter-apk/*.apk
