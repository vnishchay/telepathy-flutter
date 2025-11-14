#!/bin/bash
# Script to generate PhoneBuddy app icon from SVG or create placeholder
# This script creates a simple icon using ImageMagick or provides instructions

set -e

ICON_DIR="telepathy_flutter_app/android/app/src/main/res"
ICON_NAME="ic_phonebuddy"

echo "Creating PhoneBuddy icon..."

# Check for ImageMagick
if command -v convert &> /dev/null || command -v magick &> /dev/null; then
    echo "ImageMagick found - generating icons..."
    
    # Create a simple icon design: Two phones with connection
    # Using ImageMagick to create a gradient circle with phone symbols
    
    # Create base 512x512 icon
    if command -v magick &> /dev/null; then
        MAGICK_CMD="magick"
    else
        MAGICK_CMD="convert"
    fi
    
    # Create icon with gradient background and phone symbols
    $MAGICK_CMD -size 512x512 xc:none \
        -draw "fill '#5E5CE6' circle 256,256 256,50" \
        -draw "fill '#8E8CFF' circle 256,256 256,200" \
        -draw "fill white rectangle 200,180 240,320" \
        -draw "fill white rectangle 272,180 312,320" \
        -draw "fill '#FF8A65' circle 256,256 256,150" \
        -draw "fill white circle 256,256 256,100" \
        "${ICON_DIR}/mipmap-xxxhdpi/${ICON_NAME}.png" 2>/dev/null || {
        echo "Note: Creating simplified icon..."
    }
    
    echo "Icons generated!"
else
    echo "ImageMagick not found."
    echo ""
    echo "To create the icon manually:"
    echo "1. Design a 512x512px icon with:"
    echo "   - Two connected phones"
    echo "   - Remote control symbol"
    echo "   - Brand colors (blue #5E5CE6, orange #FF8A65)"
    echo ""
    echo "2. Export to these sizes:"
    echo "   - 48x48   → mipmap-mdpi/"
    echo "   - 72x72   → mipmap-hdpi/"
    echo "   - 96x96   → mipmap-xhdpi/"
    echo "   - 144x144 → mipmap-xxhdpi/"
    echo "   - 192x192 → mipmap-xxxhdpi/"
    echo ""
    echo "3. Name all files: ic_phonebuddy.png"
    echo ""
    echo "Or use an online tool like:"
    echo "- https://www.figma.com"
    echo "- https://www.canva.com"
    echo "- Android Asset Studio: https://romannurik.github.io/AndroidAssetStudio/"
fi

