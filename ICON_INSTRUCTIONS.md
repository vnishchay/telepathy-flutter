# PhoneBuddy Icon Generation Instructions

## Quick Method: Use Online Tool

1. **Go to Android Asset Studio**: https://romannurik.github.io/AndroidAssetStudio/icons-launcher.html
2. **Upload the SVG**: Use `phonebuddy-icon.svg` from this repository
3. **Generate icons**: The tool will create all required sizes automatically
4. **Download and extract** to `telepathy_flutter_app/android/app/src/main/res/`

## Manual Method: Convert SVG to PNG

### Using Inkscape (Recommended)

```bash
# Install Inkscape
sudo apt install inkscape  # Ubuntu/Debian
brew install inkscape       # macOS

# Convert to all required sizes
inkscape phonebuddy-icon.svg -w 48 -h 48 -o telepathy_flutter_app/android/app/src/main/res/mipmap-mdpi/ic_launcher.png
inkscape phonebuddy-icon.svg -w 72 -h 72 -o telepathy_flutter_app/android/app/src/main/res/mipmap-hdpi/ic_launcher.png
inkscape phonebuddy-icon.svg -w 96 -h 96 -o telepathy_flutter_app/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
inkscape phonebuddy-icon.svg -w 144 -h 144 -o telepathy_flutter_app/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
inkscape phonebuddy-icon.svg -w 192 -h 192 -o telepathy_flutter_app/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png

# Create 512x512 for documentation
inkscape phonebuddy-icon.svg -w 512 -h 512 -o phonebuddy-icon-512.png
```

### Using ImageMagick

```bash
# Install ImageMagick
sudo apt install imagemagick  # Ubuntu/Debian
brew install imagemagick      # macOS

# Convert SVG to PNG at different sizes
convert -background none -resize 48x48 phonebuddy-icon.svg telepathy_flutter_app/android/app/src/main/res/mipmap-mdpi/ic_launcher.png
convert -background none -resize 72x72 phonebuddy-icon.svg telepathy_flutter_app/android/app/src/main/res/mipmap-hdpi/ic_launcher.png
convert -background none -resize 96x96 phonebuddy-icon.svg telepathy_flutter_app/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
convert -background none -resize 144x144 phonebuddy-icon.svg telepathy_flutter_app/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
convert -background none -resize 192x192 phonebuddy-icon.svg telepathy_flutter_app/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
convert -background none -resize 512x512 phonebuddy-icon.svg phonebuddy-icon-512.png
```

### Using Python with Pillow

```bash
# Install Pillow
pip3 install Pillow

# Run the generator script
python3 generate_icon.py
```

## Icon Design Description

The PhoneBuddy icon features:
- **Two connected phones** (left: blue, right: orange) representing the pair
- **Connection line** between them (light blue)
- **Remote control symbol** in the center (circle with play icon)
- **Gradient background** (blue to light blue) matching app theme
- **Audio wave accents** for visual appeal

## Verification

After generating icons, verify:
- All 5 mipmap folders have `ic_launcher.png`
- Icons are square and properly sized
- No transparency issues
- Icons look clear at small sizes

## Next Steps

1. Generate icons using one of the methods above
2. Update AndroidManifest.xml if needed (usually not required)
3. Rebuild the app: `flutter build apk --release`
4. Test the icon appears correctly on device

