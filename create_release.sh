#!/bin/bash
# Script to create a GitHub release with APK attachment
# Requires: curl, jq (optional), and GITHUB_TOKEN environment variable

set -e

REPO="vnishchay/telepathy-flutter"
VERSION="v1.0.0"
APK_PATH="releases/phonebuddy-v1.0.0-release.apk"
RELEASE_NOTES="## PhoneBuddy v1.0.0

### Features
- Remote audio profile control (Ring, Vibrate, Silent)
- Works in background and after device reboot
- Secure Google Sign-In authentication
- Real-time status synchronization
- Minimal data usage via FCM

### Installation
1. Download the APK below
2. Enable \"Install from Unknown Sources\" on your Android device
3. Install and sign in with Google
4. Follow the in-app setup guide

### Requirements
- Android 8.0+ (Oreo or newer)
- Two Android devices
- Google account
- Internet connection for initial pairing

### Documentation
See [README.md](README.md) for detailed setup instructions and troubleshooting.

---

**Download the APK below to get started!**"

if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN environment variable is not set"
    echo "Please set it with: export GITHUB_TOKEN=your_token_here"
    echo "You can create a token at: https://github.com/settings/tokens"
    exit 1
fi

if [ ! -f "$APK_PATH" ]; then
    echo "Error: APK file not found at $APK_PATH"
    exit 1
fi

echo "Creating release $VERSION..."

# Create release
RESPONSE=$(curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/$REPO/releases" \
  -d "{
    \"tag_name\": \"$VERSION\",
    \"name\": \"PhoneBuddy $VERSION\",
    \"body\": $(echo "$RELEASE_NOTES" | jq -Rs .),
    \"draft\": false,
    \"prerelease\": false
  }")

# Extract upload URL
UPLOAD_URL=$(echo "$RESPONSE" | grep -o '"upload_url": "[^"]*' | cut -d'"' -f4 | sed 's/{?name,label}//')

if [ -z "$UPLOAD_URL" ]; then
    echo "Error: Failed to create release. Response:"
    echo "$RESPONSE"
    exit 1
fi

echo "Release created! Uploading APK..."

# Upload APK
APK_NAME=$(basename "$APK_PATH")
UPLOAD_RESPONSE=$(curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Content-Type: application/vnd.android.package-archive" \
  --data-binary "@$APK_PATH" \
  "$UPLOAD_URL?name=$APK_NAME")

if echo "$UPLOAD_RESPONSE" | grep -q '"id"'; then
    echo "✓ Successfully created release $VERSION with APK!"
    echo "Release URL: https://github.com/$REPO/releases/tag/$VERSION"
else
    echo "Error: Failed to upload APK. Response:"
    echo "$UPLOAD_RESPONSE"
    exit 1
fi

