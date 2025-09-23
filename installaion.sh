#!/bin/bash
set -e

echo "Flutter App Setup Script (Interactive Mode)"

# 1️⃣ App Name
APP_NAME=""
while [ -z "$APP_NAME" ]; do
  echo -n "Enter App Name: "
  read APP_NAME </dev/tty
  if [ -z "$APP_NAME" ]; then
    echo "App Name is required!"
  fi
done

# 2️⃣ Package Name
PACKAGE_NAME=""
while [ -z "$PACKAGE_NAME" ]; do
  echo -n "Enter Package Name: "
  read PACKAGE_NAME </dev/tty
  if [ -z "$PACKAGE_NAME" ]; then
    echo "Package Name is required!"
  fi
done

# 3️⃣ Main Domain
MAIN_DOMAIN=""
while [ -z "$MAIN_DOMAIN" ]; do
  echo -n "Enter Main Domain: "
  read MAIN_DOMAIN </dev/tty
  if [ -z "$MAIN_DOMAIN" ]; then
    echo "Main Domain is required!"
  fi
done

# Optional Git Branch
echo -n "Enter Git Branch Name (default: current branch): "
read BRANCH_NAME </dev/tty
BRANCH_NAME=${BRANCH_NAME:-$(git branch --show-current)}

echo ""
echo "Inputs received:"
echo "   App Name    : $APP_NAME"
echo "   Package Name: $PACKAGE_NAME"
echo "   Main Domain : $MAIN_DOMAIN"
echo "   Git Branch  : $BRANCH_NAME"
echo ""

# Flutter packages
echo "Getting Flutter packages..."
flutter pub get

# Rename app
echo "Renaming app..."
flutter pub run rename_app:main all="$APP_NAME"

# -------------------------------
# Update Android package name
# -------------------------------
echo "Updating Android package name..."

# build.gradle
BUILD_GRADLE="android/app/build.gradle"
if [ -f "$BUILD_GRADLE" ]; then
  sed -i.bak "s|applicationId \".*\"|applicationId \"$PACKAGE_NAME\"|" "$BUILD_GRADLE"
  sed -i.bak "s|namespace \".*\"|namespace \"$PACKAGE_NAME\"|" "$BUILD_GRADLE"
else
  echo "⚠️ $BUILD_GRADLE not found!"
fi

# AndroidManifest.xml
MANIFEST="android/app/src/main/AndroidManifest.xml"
if [ -f "$MANIFEST" ]; then
  sed -i.bak "s|package=\".*\"|package=\"$PACKAGE_NAME\"|" "$MANIFEST"
else
  echo "⚠️ $MANIFEST not found!"
fi

# MainActivity.kt (update package declaration)
MAIN_ACTIVITY=$(find android/app/src/main/kotlin -name "MainActivity.kt")
if [ -f "$MAIN_ACTIVITY" ]; then
  sed -i.bak "1s|^package .*|package $PACKAGE_NAME|" "$MAIN_ACTIVITY"
else
  echo "⚠️ MainActivity.kt not found!"
fi

# -------------------------------
# Update launcher icons
# -------------------------------
echo "Updating launcher icons..."
flutter pub run flutter_launcher_icons:main

# -------------------------------
# Update domain in api_endpoint.dart
# -------------------------------
API_FILE="lib/backend/services/api_endpoint.dart"
if [ -f "$API_FILE" ]; then
  echo "Updating mainDomain in $API_FILE..."
  sed -i.bak "s|static const String mainDomain = .*|static const String mainDomain = \"$MAIN_DOMAIN\";|" "$API_FILE"
else
  echo "⚠️ $API_FILE not found!"
fi

# -------------------------------
# Build APKs split per ABI
# -------------------------------
echo "Building split APKs..."
flutter build apk --release \
  --target-platform android-arm,android-arm64,android-x64 \
  --split-per-abi

# -------------------------------
# Git commit + push
# -------------------------------
echo "Committing & pushing changes..."
git add .
git commit -m "chore: setup $APP_NAME ($PACKAGE_NAME) with mainDomain $MAIN_DOMAIN"
git push origin "$BRANCH_NAME"

echo "✅ Done! APKs available at: build/app/outputs/flutter-apk/"
ls -lh build/app/outputs/flutter-apk/*.apk
