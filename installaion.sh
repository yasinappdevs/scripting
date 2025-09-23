#!/bin/bash
set -e

# --- Accept parameters from command line ---
# Usage: bash update_view_options.sh "App Name" "Package Name" "Domain" "Branch" "Icon Path (optional)"
APP_NAME="$1"
PACKAGE_NAME="$2"
MAIN_DOMAIN="$3"
BRANCH_NAME="$4"
ICON_PATH="${5:-assets/logo}"  # default to assets/logo if not provided

# Check if mandatory parameters are provided
if [ -z "$APP_NAME" ] || [ -z "$PACKAGE_NAME" ] || [ -z "$MAIN_DOMAIN" ] || [ -z "$BRANCH_NAME" ]; then
  echo "❌ Usage: bash update_view_options.sh \"App Name\" \"Package Name\" \"Domain\" \"Branch\" [Icon Path]"
  exit 1
fi

echo "🚀 Starting setup for $APP_NAME"

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
