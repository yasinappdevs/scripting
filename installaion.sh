#!/bin/bash
set -e

echo "🚀 Flutter App Auto Setup Script"

# Step 1: Ask for inputs
read -p "Enter App Name: " APP_NAME
read -p "Enter Package Name: " PACKAGE_NAME
read -p "Enter Launcher Icon Folder Path (relative, e.g., assets/logo): " ICON_PATH
read -p "Enter Main Domain: " MAIN_DOMAIN
read -p "Enter Git Branch Name (e.g., version-1.3.0): " BRANCH_NAME

echo ""
echo "✅ Inputs received:"
echo "   App Name    : $APP_NAME"
echo "   Package Name: $PACKAGE_NAME"
echo "   Icon Path   : $ICON_PATH"
echo "   Main Domain : $MAIN_DOMAIN"
echo "   Git Branch  : $BRANCH_NAME"
echo ""

# Step 2: Get Flutter packages
echo "📦 Getting Flutter packages..."
flutter pub get

# Step 3: Rename app
echo "✏️ Renaming app..."
flutter pub run rename_app:main all="$APP_NAME"

# Step 4: Change package name
echo "📦 Changing package name..."
flutter pub run change_app_package_name:main "$PACKAGE_NAME"

# Step 5: Update launcher icons
echo "🎨 Updating launcher icons..."
flutter pub run flutter_launcher_icons --image-path "$ICON_PATH"

# Step 6: Update domain in api_endpoint.dart
API_FILE="lib/backend/services/api_endpoint.dart"
if [ -f "$API_FILE" ]; then
  echo "🌐 Updating mainDomain in $API_FILE..."
  sed -i.bak "s|static const String mainDomain = .*|static const String mainDomain = \"$MAIN_DOMAIN\";|" "$API_FILE"
else
  echo "⚠️ $API_FILE not found!"
fi

# Step 7: Build split APKs
echo "⚒️ Building split APKs..."
flutter build apk --release \
  --target-platform android-arm,android-arm64,android-x64 \
  --split-per-abi

# Step 8: Commit & push
echo "📤 Committing & pushing changes..."
git add .
git commit -m "chore: setup $APP_NAME ($PACKAGE_NAME) with mainDomain $MAIN_DOMAIN"
git push origin "$BRANCH_NAME"

echo "✅ Done! APKs available at: build/app/outputs/flutter-apk/"
ls -lh build/app/outputs/flutter-apk/*.apk
