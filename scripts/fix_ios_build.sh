#!/bin/sh
# Syncs CocoaPods and Flutter so "PhaseScriptExecution failed" / "sandbox not in sync" are resolved.
# Run from project root: sh scripts/fix_ios_build.sh

set -e
cd "$(dirname "$0")/.."

echo "→ Flutter clean..."
flutter clean

echo "→ Flutter pub get..."
flutter pub get

echo "→ Pod install (ios)..."
cd ios && pod install && cd ..

echo "✓ Done. Try building again from Xcode or run: flutter build ios --no-codesign"
echo "  If Xcode still shows PhaseScriptExecution failed, run that flutter build command in Terminal to see the real error."
