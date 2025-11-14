#!/bin/bash
# Quick icon setup using online tool or manual conversion
# This script helps set up the PhoneBuddy icon

set -e

echo "PhoneBuddy Icon Setup"
echo "===================="
echo ""
echo "The icon SVG is ready: phonebuddy-icon.svg"
echo ""
echo "To generate Android icons, choose one method:"
echo ""
echo "METHOD 1: Online Tool (Easiest)"
echo "1. Go to: https://romannurik.github.io/AndroidAssetStudio/icons-launcher.html"
echo "2. Upload: phonebuddy-icon.svg"
echo "3. Download the generated zip"
echo "4. Extract to: telepathy_flutter_app/android/app/src/main/res/"
echo ""
echo "METHOD 2: Using Inkscape (if installed)"
if command -v inkscape &> /dev/null; then
    echo "Inkscape found! Generating icons..."
    INKSCAPE_CMD="inkscape"
    
    $INKSCAPE_CMD phonebuddy-icon.svg -w 48 -h 48 -o telepathy_flutter_app/android/app/src/main/res/mipmap-mdpi/ic_launcher.png
    $INKSCAPE_CMD phonebuddy-icon.svg -w 72 -h 72 -o telepathy_flutter_app/android/app/src/main/res/mipmap-hdpi/ic_launcher.png
    $INKSCAPE_CMD phonebuddy-icon.svg -w 96 -h 96 -o telepathy_flutter_app/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
    $INKSCAPE_CMD phonebuddy-icon.svg -w 144 -h 144 -o telepathy_flutter_app/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
    $INKSCAPE_CMD phonebuddy-icon.svg -w 192 -h 192 -o telepathy_flutter_app/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
    $INKSCAPE_CMD phonebuddy-icon.svg -w 512 -h 512 -o phonebuddy-icon-512.png
    
    echo "✓ Icons generated successfully!"
else
    echo "Inkscape not installed. Install with:"
    echo "  Ubuntu/Debian: sudo apt install inkscape"
    echo "  macOS: brew install inkscape"
fi
echo ""
echo "METHOD 3: Manual (see ICON_INSTRUCTIONS.md for details)"
echo ""
echo "After generating icons, rebuild the app:"
echo "  cd telepathy_flutter_app && flutter build apk --release"

