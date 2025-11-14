# PhoneBuddy - Remote Audio Control

**PhoneBuddy** turns two Android phones into a trusted pair: one device operates as the **remote controller** while the other becomes the **receiver** whose ringer profile (ring, vibrate, silent) can be switched instantly—even if the receiver app is backgrounded or the screen is off.

## 🚀 Quick Start Guide

### For End Users

#### Step 1: Install the App
1. Download the latest APK from the [Releases](../../releases) section
2. Enable "Install from Unknown Sources" on your Android device:
   - Go to **Settings → Security → Unknown Sources** (or **Settings → Apps → Special Access → Install Unknown Apps**)
   - Enable installation from your file manager or browser
3. Install the APK on both phones you want to pair

#### Step 2: First-Time Setup
1. **Open the app on both devices**
2. **Sign in with Google** (required for secure pairing)
3. **Complete the onboarding** - The app will explain the two roles:
   - **Remote Controller**: The device that sends commands
   - **Receiver**: The device that receives and applies audio profile changes

#### Step 3: Pair Your Devices
1. **On Device A (Remote Controller)**:
   - Tap **"Create Room"** or **"Join Room"**
   - Enter a pairing code (letters and numbers, e.g., "ABC123")
   - Select **"Remote Controller"** role
   - Tap **"Connect"**

2. **On Device B (Receiver)**:
   - Tap **"Join Room"**
   - Enter the **same pairing code** (e.g., "ABC123")
   - Select **"Receiver"** role
   - Tap **"Connect"**

3. **Grant Permissions on Receiver Device**:
   - The app will prompt for **"Do Not Disturb" access**
   - Tap **"Grant Permission"** → This opens Android Settings
   - Find **"PhoneBuddy"** in the list and toggle it **ON**
   - Return to the app

#### Step 4: Start Controlling
- **On the Remote Controller device**, you'll see a large status card showing the receiver's current audio profile
- **Tap the card** to cycle through:
  - 🔔 **Ringing** (blue gradient)
  - 📳 **Vibrate** (orange gradient)
  - 🔇 **Silent** (red gradient)
- The receiver device will **instantly change** its ringer mode, even if:
  - The app is in the background
  - The screen is locked
  - The app was closed (but not force-stopped)

---

## 📱 How It Works

### Architecture Overview
- **Flutter UI & State**: Manages pairing, permissions, and displays real-time status
- **Firebase Firestore**: Stores room/device documents with audio profile and FCM tokens
- **Firebase Cloud Functions**: Listens for profile changes and sends push notifications
- **Android Foreground Service**: Runs in the background to apply ringer changes reliably
- **FCM (Firebase Cloud Messaging)**: Delivers commands even when the app is closed

### Key Features
✅ **Works in Background**: Receiver responds to commands even when the app is closed  
✅ **Survives Reboot**: Service automatically restarts after device restart  
✅ **Real-time Sync**: Both devices see the current audio profile instantly  
✅ **Secure Pairing**: Google Sign-In ensures only authorized devices can pair  
✅ **No Internet Required After Pairing**: Commands work via FCM (minimal data usage)

---

## 🎯 Use Cases

- **Parents controlling kids' phones**: Switch to silent during school hours
- **Meeting management**: Quickly silence a phone from across the room
- **Lost phone finder**: Switch to ringing mode to locate a misplaced device
- **Privacy control**: Remotely silence a device when privacy is needed

---

## ⚙️ Technical Details

### Permissions Required
- **Do Not Disturb Access** (Receiver only): Allows the app to change ringer mode
- **Notification Permission** (Android 13+): Required for background notifications
- **Foreground Service**: Runs automatically (shows a persistent notification)

### Background Behavior
- The receiver device runs a **foreground service** (visible notification: "PhoneBuddy Active")
- This service ensures commands are processed even when:
  - The app is backgrounded
  - The screen is locked
  - The app process was killed by the system

### Limitations
- **Force-stop protection**: If the receiver app is force-stopped from Settings, commands won't work until the app is reopened
- **Internet required**: Initial pairing and commands require an internet connection
- **Android 8.0+**: Requires Android Oreo or newer

---

## 🔧 Troubleshooting

| Issue | Solution |
|-------|----------|
| **Receiver doesn't respond to commands** | 1. Check if "PhoneBuddy Active" notification is visible<br>2. Verify Do Not Disturb permission is granted<br>3. Unpair and re-pair the devices |
| **Can't grant Do Not Disturb permission** | Go to **Settings → Apps → Special Access → Do Not Disturb Access** → Enable PhoneBuddy |
| **Commands work but app shows wrong status** | Tap the refresh icon or unpair/re-pair to sync |
| **App crashes on startup** | Ensure you're signed in with Google and have internet connection |
| **Pairing code doesn't work** | Codes are case-insensitive but must match exactly. Try creating a new room |

---

## 📦 Installation for Developers

### Prerequisites
- Flutter SDK 3.16+
- Android SDK (API 26+)
- Firebase project with Firestore and Cloud Messaging enabled
- Node.js 18+ (for Cloud Functions)

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/<your-org>/telepathy-flutter.git
   cd telepathy-flutter/telepathy_flutter_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Download `google-services.json` from Firebase Console
   - Place it at: `android/app/google-services.json`
   - Run: `flutterfire configure`

4. **Deploy Cloud Functions**
   ```bash
   cd ../functions
   npm install
   firebase deploy --only functions
   ```

5. **Build and run**
   ```bash
   flutter run
   ```

### Building Production APK

1. **Create a signing key** (one-time)
   ```bash
   keytool -genkey -v -keystore ~/keystores/telepathy-release.jks \
     -alias telepathy -keyalg RSA -keysize 2048 -validity 10000
   ```

2. **Create `key.properties`** (never commit this)
   ```properties
   storePassword=your-store-password
   keyPassword=your-key-password
   keyAlias=telepathy
   storeFile=/absolute/path/to/telepathy-release.jks
   ```

3. **Build release APK**
   ```bash
   flutter build apk --release
   ```
   Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## 🔒 Security & Privacy

- **No data stored locally**: All pairing data is stored in Firebase Firestore
- **Google Sign-In required**: Ensures only authenticated users can pair devices
- **Secure communication**: All commands are sent via encrypted FCM messages
- **No location tracking**: The app does not access or store location data
- **Minimal permissions**: Only requests permissions necessary for audio control

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

## 📞 Support

For issues, questions, or feature requests, please open an issue on GitHub.

---

**Made with ❤️ for seamless device control**
