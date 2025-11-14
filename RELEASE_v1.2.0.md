# Release v1.2.0 - Ready to Publish

## ✅ Build Complete

- **Version**: 1.2.0+3
- **APK**: `releases/phonebuddy-v1.2.0-release.apk` (51 MB)
- **Status**: Built and pushed to GitHub

## 🚀 Create Release Now

### Quick Method: GitHub Web Interface

1. **Visit**: https://github.com/vnishchay/telepathy-flutter/releases
2. **Click**: "Draft a new release"
3. **Fill in**:
   - **Tag**: `v1.2.0` (create new tag)
   - **Release title**: `PhoneBuddy v1.2.0`
   - **Description**: Copy from below
4. **Attach APK**: Upload `releases/phonebuddy-v1.2.0-release.apk`
5. **Publish**: Click "Publish release"

### Release Notes

```markdown
## PhoneBuddy v1.2.0

### What's New
- 🚀 **Performance Improvements**: Optimized Firebase operations and reduced unnecessary API calls
- 💾 **Cost Optimization**: Smart caching to minimize Firestore reads and Cloud Function invocations
- 🔒 **Enhanced Security**: Improved token management and credential handling
- 🎨 **UI Polish**: Better loading states and user feedback during remote operations

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

### Alternative: Use Script

```bash
export GITHUB_TOKEN=your_token_here
./create_release.sh
```

