#!/bin/bash
set -e

echo "🚀 Flutter App Setup Script (Interactive Mode)"
echo "This script fetches latest updates dynamically from GitHub."

# 1️⃣ App Name
APP_NAME=""
while [ -z "$APP_NAME" ]; do
  echo -n "Enter App Name: "
  read APP_NAME </dev/tty
  if [ -z "$APP_NAME" ]; then
    echo "❌ App Name is required!"
  fi
done

# 2️⃣ Package Name
PACKAGE_NAME=""
while [ -z "$PACKAGE_NAME" ]; do
  echo -n "Enter Package Name: "
  read PACKAGE_NAME </dev/tty
  if [ -z "$PACKAGE_NAME" ]; then
    echo "❌ Package Name is required!"
  fi
done

# 3️⃣ Main Domain
MAIN_DOMAIN=""
while [ -z "$MAIN_DOMAIN" ]; do
  echo -n "Enter Main Domain: "
  read MAIN_DOMAIN </dev/tty
  if [ -z "$MAIN_DOMAIN" ]; then
    echo "❌ Main Domain is required!"
  fi
done

# 4️⃣ Optional Icon Path
echo -n "Enter Launcher Icon Path (default: assets/logo): "
read ICON_PATH </dev/tty
ICON_PATH=${ICON_PATH:-assets/logo}

# 5️⃣ Git Branch (default: current branch)
echo -n "Enter Git Branch Name (default: current branch): "
read BRANCH_NAME </dev/tty
BRANCH_NAME=${BRANCH_NAME:-$(git branch --show-current)}

echo ""
echo "✅ Inputs received:"
echo "   App Name    : $APP_NAME"
echo "   Package Name: $PACKAGE_NAME"
echo "   Main Domain : $MAIN_DOMAIN"
echo "   Icon Path   : $ICON_PATH"
echo "   Git Branch  : $BRANCH_NAME"
echo ""

# Fetch latest update of the script from GitHub (dynamic)
echo "🌐 Fetching latest script updates..."
curl -sSL https://raw.githubusercontent.com/yasinappdevs/scripting/main/installaion.sh -o .latest_installaion.sh
chmod +x .latest_installaion.sh
# Optionally source latest functions if needed
# source .latest_installaion.sh

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
