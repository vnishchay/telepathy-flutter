# PhoneBuddy - Remote Audio Control

<div align="center">

![PhoneBuddy Icon](phonebuddy-icon.svg)

**PhoneBuddy** is a Flutter application that allows you to remotely control the audio profile (ring, vibrate, silent) of an Android device from another Android device. Perfect for parents managing kids' phones, meeting management, or finding lost devices.

[![Download APK](https://img.shields.io/badge/Download-APK-brightgreen)](https://github.com/vnishchay/telepathy-flutter/releases)
[![Android](https://img.shields.io/badge/Android-8.0%2B-blue)](https://www.android.com)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

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

## 📦 Releases

Download the latest production APK from [GitHub Releases](https://github.com/vnishchay/telepathy-flutter/releases).

**Current Version**: v1.0.0

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

- **Issues**: [GitHub Issues](https://github.com/vnishchay/telepathy-flutter/issues)
- **Questions**: Open a discussion on GitHub

## 🙏 Acknowledgments

Built with Flutter, Firebase, and ❤️ for seamless device control.

---

**Made for Android** | **Requires Android 8.0+** | **Free & Open Source**

