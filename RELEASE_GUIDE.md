# Creating a GitHub Release with APK

## Option 1: Using GitHub Web Interface (Recommended)

1. **Go to your repository**: https://github.com/vnishchay/telepathy-flutter
2. **Click "Releases"** in the right sidebar (or go to `/releases`)
3. **Click "Draft a new release"**
4. **Fill in the details**:
   - **Tag**: `v1.0.0` (or create a new tag)
   - **Release title**: `PhoneBuddy v1.0.0`
   - **Description**: Copy from the release notes below
5. **Attach the APK**:
   - Scroll down to "Attach binaries"
   - Click "Choose your files"
   - Select `releases/phonebuddy-v1.0.0-release.apk`
6. **Click "Publish release"**

### Release Notes Template

```markdown
## PhoneBuddy v1.0.0

### Features
- Remote audio profile control (Ring, Vibrate, Silent)
- Works in background and after device reboot
- Secure Google Sign-In authentication
- Real-time status synchronization
- Minimal data usage via FCM

### Installation
1. Download the APK below
2. Enable "Install from Unknown Sources" on your Android device
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

**Download the APK below to get started!**
```

## Option 2: Using GitHub CLI

If you have GitHub CLI installed:

```bash
gh release create v1.0.0 \
  --title "PhoneBuddy v1.0.0" \
  --notes-file <(cat <<EOF
## PhoneBuddy v1.0.0

### Features
- Remote audio profile control (Ring, Vibrate, Silent)
- Works in background and after device reboot
- Secure Google Sign-In authentication
- Real-time status synchronization
- Minimal data usage via FCM

### Installation
1. Download the APK below
2. Enable "Install from Unknown Sources" on your Android device
3. Install and sign in with Google
4. Follow the in-app setup guide
EOF
) \
  releases/phonebuddy-v1.0.0-release.apk
```

## Option 3: Using the Script (Requires GitHub Token)

1. **Create a GitHub Personal Access Token**:
   - Go to: https://github.com/settings/tokens
   - Click "Generate new token (classic)"
   - Select scope: `repo` (full control of private repositories)
   - Copy the token

2. **Run the script**:
   ```bash
   export GITHUB_TOKEN=your_token_here
   ./create_release.sh
   ```

The script will automatically:
- Create the release
- Upload the APK
- Set release notes

## Verification

After creating the release, verify:
- ✅ Release appears at: https://github.com/vnishchay/telepathy-flutter/releases
- ✅ APK is downloadable from the release page
- ✅ Release notes are properly formatted

