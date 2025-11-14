# PhoneBuddy - Remote Audio Control

<div align="center">

![PhoneBuddy Icon](phonebuddy-icon.svg)

**PhoneBuddy** is a Flutter application that allows you to remotely control the audio profile (ring, vibrate, silent) of an Android device from another Android device. Perfect for parents managing kids' phones, meeting management, or finding lost devices.

[![GitHub release](https://img.shields.io/github/v/release/vnishchay/telepathy-flutter?label=Latest%20Release&style=for-the-badge)](https://github.com/vnishchay/telepathy-flutter/releases/latest)
[![GitHub downloads](https://img.shields.io/github/downloads/vnishchay/telepathy-flutter/total?label=Total%20Downloads&style=for-the-badge&color=success)](https://github.com/vnishchay/telepathy-flutter/releases)
[![GitHub stars](https://img.shields.io/github/stars/vnishchay/telepathy-flutter?style=for-the-badge&color=yellow)](https://github.com/vnishchay/telepathy-flutter/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/vnishchay/telepathy-flutter?style=for-the-badge&color=blue)](https://github.com/vnishchay/telepathy-flutter/network/members)

[![Android](https://img.shields.io/badge/Android-8.0%2B-blue?style=for-the-badge)](https://www.android.com)
[![Flutter](https://img.shields.io/badge/Flutter-3.16%2B-02569B?style=for-the-badge&logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)

**📥 [Download Latest APK](https://github.com/vnishchay/telepathy-flutter/releases/latest)** | **📖 [Documentation](telepathy_flutter_app/README.md)** | **🐛 [Report Issue](https://github.com/vnishchay/telepathy-flutter/issues)**

</div>

---

### 📊 Repository Statistics

<div align="center">

![GitHub watchers](https://img.shields.io/github/watchers/vnishchay/telepathy-flutter?label=Watchers&style=flat-square)
![GitHub contributors](https://img.shields.io/github/contributors/vnishchay/telepathy-flutter?label=Contributors&style=flat-square)
![GitHub last commit](https://img.shields.io/github/last-commit/vnishchay/telepathy-flutter?label=Last%20Commit&style=flat-square)
![GitHub repo size](https://img.shields.io/github/repo-size/vnishchay/telepathy-flutter?label=Repo%20Size&style=flat-square)

</div>

## 🚀 Quick Start

### Download & Install

1. **Download the latest APK** from [Releases](https://github.com/vnishchay/telepathy-flutter/releases)
2. **Enable "Install from Unknown Sources"** on your Android device
3. **Install the APK** on both phones you want to pair
4. **Sign in with Google** and follow the in-app setup

### First-Time Setup

1. **On Device A (Remote Controller)**:
   - Open PhoneBuddy
   - Tap "Create Room" or "Join Room"
   - Enter a pairing code (e.g., "ABC123")
   - Select "Remote Controller" role
   - Tap "Connect"

2. **On Device B (Receiver)**:
   - Open PhoneBuddy
   - Tap "Join Room"
   - Enter the **same pairing code**
   - Select "Receiver" role
   - Tap "Connect"
   - **Grant "Do Not Disturb" permission** when prompted

3. **Start Controlling**:
   - On the Remote Controller, tap the status card to cycle through:
     - 🔔 **Ringing** (blue)
     - 📳 **Vibrate** (orange)
     - 🔇 **Silent** (red)
   - The receiver device will instantly change its ringer mode!

## ✨ Features

- ✅ **Works in Background**: Commands work even when the app is closed
- ✅ **Survives Reboot**: Service automatically restarts after device restart
- ✅ **Real-time Sync**: Both devices see current status instantly
- ✅ **Secure Pairing**: Google Sign-In ensures authorized access only
- ✅ **No Internet After Pairing**: Minimal data usage via FCM

## 📱 Requirements

- **Android 8.0+** (Oreo or newer)
- **Two Android devices** (or one device + emulator)
- **Google account** for authentication
- **Internet connection** for initial pairing

## 🎯 Use Cases

- **Parents & Kids**: Remotely silence phones during school hours
- **Meeting Management**: Quickly silence a phone from across the room
- **Lost Phone Finder**: Switch to ringing mode to locate a device
- **Privacy Control**: Remotely silence when privacy is needed

## 📖 Documentation

For detailed documentation, see:
- **[User Guide](telepathy_flutter_app/README.md)** - Complete setup and troubleshooting
- **[Developer Setup](telepathy_flutter_app/README.md#installation-for-developers)** - Building from source

## 🏗️ Project Structure

```
telepathy-flutter/
├── telepathy_flutter_app/     # Flutter application
│   ├── lib/                   # Dart source code
│   ├── android/               # Android native code (Kotlin)
│   └── README.md             # Detailed documentation
├── functions/                 # Firebase Cloud Functions
│   └── index.js              # FCM message handler
├── releases/                 # Production APK builds
└── README.md                # This file
```

## 🔧 Technology Stack

- **Flutter** - Cross-platform UI framework
- **Firebase** - Backend (Firestore, Cloud Messaging, Auth)
- **Kotlin** - Android native services
- **Cloud Functions** - Serverless FCM delivery

## 🔒 Security & Privacy

- ✅ Google Sign-In required for authentication
- ✅ Encrypted FCM messages
- ✅ No location tracking
- ✅ Minimal permissions (only what's needed)
- ✅ Secure Firestore rules

## 📦 Releases & Downloads

<div align="center">

### 📥 Download Statistics

[![GitHub all releases](https://img.shields.io/github/downloads/vnishchay/telepathy-flutter/total?label=Total%20Downloads&style=for-the-badge&color=success)](https://github.com/vnishchay/telepathy-flutter/releases)
[![GitHub release (latest by date)](https://img.shields.io/github/downloads/vnishchay/telepathy-flutter/latest/total?label=Latest%20Release%20Downloads&style=for-the-badge&color=blue)](https://github.com/vnishchay/telepathy-flutter/releases/latest)

</div>

**Current Version**: [![GitHub release](https://img.shields.io/github/v/release/vnishchay/telepathy-flutter?label=v1.2.0&style=flat-square)](https://github.com/vnishchay/telepathy-flutter/releases/latest)

Download the latest production APK from [GitHub Releases](https://github.com/vnishchay/telepathy-flutter/releases).

### Release History

| Version | Downloads | Release Date | Notes |
|---------|-----------|--------------|-------|
| [v1.2.0](https://github.com/vnishchay/telepathy-flutter/releases/tag/v1.2.0) | ![GitHub downloads](https://img.shields.io/github/downloads/vnishchay/telepathy-flutter/v1.2.0/total?label=&style=flat-square) | Latest | Performance improvements & cost optimization |
| [v1.1.0](https://github.com/vnishchay/telepathy-flutter/releases/tag/v1.1.0) | ![GitHub downloads](https://img.shields.io/github/downloads/vnishchay/telepathy-flutter/v1.1.0/total?label=&style=flat-square) | - | New app icon & enhanced branding |
| [v1.0.0](https://github.com/vnishchay/telepathy-flutter/releases/tag/v1.0.0) | ![GitHub downloads](https://img.shields.io/github/downloads/vnishchay/telepathy-flutter/v1.0.0/total?label=&style=flat-square) | - | Initial release |

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| Receiver doesn't respond | Check "PhoneBuddy Active" notification is visible, verify DND permission |
| Can't grant permission | Go to Settings → Apps → Special Access → Do Not Disturb Access |
| Commands don't work | Unpair and re-pair the devices |
| App crashes | Ensure you're signed in with Google and have internet |

For more troubleshooting tips, see the [detailed README](telepathy_flutter_app/README.md#troubleshooting).

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

- **Issues**: [![GitHub issues](https://img.shields.io/github/issues/vnishchay/telepathy-flutter?label=Open%20Issues&style=flat-square)](https://github.com/vnishchay/telepathy-flutter/issues) [![GitHub closed issues](https://img.shields.io/github/issues-closed/vnishchay/telepathy-flutter?label=Closed&style=flat-square)](https://github.com/vnishchay/telepathy-flutter/issues?q=is%3Aissue+is%3Aclosed)
- **Questions**: Open a [discussion](https://github.com/vnishchay/telepathy-flutter/discussions) on GitHub
- **Pull Requests**: [![GitHub pull requests](https://img.shields.io/github/issues-pr/vnishchay/telepathy-flutter?label=PRs&style=flat-square)](https://github.com/vnishchay/telepathy-flutter/pulls)

## 🙏 Acknowledgments

Built with Flutter, Firebase, and ❤️ for seamless device control.

---

**Made for Android** | **Requires Android 8.0+** | **Free & Open Source**

