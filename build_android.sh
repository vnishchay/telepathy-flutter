#!/bin/bash

# Build script for Telepathy Flutter App (Android)
# Usage: ./build_android.sh [debug|release|bundle]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default build type
BUILD_TYPE=${1:-release}

# Navigate to app directory
cd "$(dirname "$0")/telepathy_flutter_app" || exit

echo -e "${GREEN}Building Telepathy Flutter App (Android)${NC}"
echo -e "${YELLOW}Build type: $BUILD_TYPE${NC}"
echo ""

# Clean previous builds
echo -e "${YELLOW}Cleaning previous builds...${NC}"
flutter clean

# Get dependencies
echo -e "${YELLOW}Getting dependencies...${NC}"
flutter pub get

# Build based on type
case $BUILD_TYPE in
  debug)
    echo -e "${GREEN}Building Debug APK...${NC}"
    flutter build apk --debug
    echo -e "${GREEN}✓ Debug APK built successfully!${NC}"
    echo -e "Location: ${GREEN}build/app/outputs/flutter-apk/app-debug.apk${NC}"
    ;;
  release)
    echo -e "${GREEN}Building Release APK...${NC}"
    flutter build apk --release
    echo -e "${GREEN}✓ Release APK built successfully!${NC}"
    echo -e "Location: ${GREEN}build/app/outputs/flutter-apk/app-release.apk${NC}"
    
    # Show APK size
    if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
      SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
      echo -e "APK Size: ${GREEN}$SIZE${NC}"
    fi
    ;;
  bundle)
    echo -e "${GREEN}Building App Bundle (for Play Store)...${NC}"
    flutter build appbundle --release
    echo -e "${GREEN}✓ App Bundle built successfully!${NC}"
    echo -e "Location: ${GREEN}build/app/outputs/bundle/release/app-release.aab${NC}"
    
    # Show AAB size
    if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
      SIZE=$(du -h build/app/outputs/bundle/release/app-release.aab | cut -f1)
      echo -e "AAB Size: ${GREEN}$SIZE${NC}"
    fi
    ;;
  split)
    echo -e "${GREEN}Building Split APKs (by ABI)...${NC}"
    flutter build apk --release --split-per-abi
    echo -e "${GREEN}✓ Split APKs built successfully!${NC}"
    echo -e "Location: ${GREEN}build/app/outputs/flutter-apk/${NC}"
    ;;
  *)
    echo -e "${RED}Invalid build type: $BUILD_TYPE${NC}"
    echo "Usage: ./build_android.sh [debug|release|bundle|split]"
    exit 1
    ;;
esac

echo ""
echo -e "${GREEN}Build completed!${NC}"

