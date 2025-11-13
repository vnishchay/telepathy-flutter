# Telepathy Flutter App

Telepathy is a two-mode Flutter application that lets one Android device act as
the remote for another phone’s audio profile (ringing, vibrate, or silent).
Both phones run the same app and connect through a shared Firebase Firestore
pairing code.

## Features

- Dark, illustration-driven onboarding carousel shown on first launch.
- Sleek pairing screen with animated orb, pairing chip, and single-code entry.
- Live paired-device card with large tap-to-cycle ring/vibrate/silent control.
- Firebase-backed rooms keyed by a 6-character code with presence detection.
- **Background audio control**: Remote control works even when receiver app is not running via FCM push notifications.
- Dedicated settings view to unpair, switch roles, and manage permissions.
- Native Android method channel for ringer changes (Do Not Disturb aware).
- Foreground service for reliable audio profile changes across app states.

## Prerequisites

- Flutter 3.16+ (latest master channel recommended) and Android toolchain.
- Android Studio or Android SDK platform tools.
- Two Android devices (or one device and an emulator) running Android 8.0+.
- A Firebase project with Firestore enabled.

## Firebase configuration

1. Install the FlutterFire CLI if needed:
   ```bash
   dart pub global activate flutterfire_cli
   ```
2. Ensure your Android package name remains `com.phonebuddy` (matches `google-services.json`).
3. From the project root, run:
   ```bash
   flutterfire configure
   ```
   Select project `myblogs-1f4ac` (or the one you created) and the Android
   application with package `com.phonebuddy`. The command generates
   `lib/firebase_options.dart`; **replace** the placeholder file that ships
   with the repo.
4. Fetch dependencies:
   ```bash
   flutter pub get
   ```

## Firebase Cloud Messaging (FCM) Setup for Background Audio Control

The app uses FCM with Cloud Functions to send push notifications for audio control changes even when the receiver app is not actively running. This ensures that remote control works seamlessly and securely.

### Cloud Functions Deployment

1. **Install Firebase CLI** (if not already installed):
   ```bash
   npm install -g firebase-tools
   firebase login
   ```

2. **Navigate to the project root** (containing `firebase.json`):
   ```bash
   cd /home/nishv/Documents/telepathy-flutter
   ```

3. **Install Cloud Functions dependencies**:
   ```bash
   cd functions
   npm install
   cd ..
   ```

4. **Deploy Cloud Functions**:
   ```bash
   firebase deploy --only functions
   ```

### FCM Permissions

The app automatically requests FCM permissions on startup. Users will be prompted to allow notifications when the app first runs.

### Background Audio Control Flow

1. **Remote Action**: User taps audio control button on remote controller
2. **Firestore Update**: Profile change saved to Firestore via `StatusController`
3. **Cloud Function Trigger**: Firestore `onUpdate` trigger detects profile change
4. **FCM Message**: Cloud Function sends push notification to receiver devices
5. **Android Service**: Native code receives FCM and starts foreground audio service
6. **Audio Change**: Foreground service applies ringer mode change immediately

### Automatic vs Manual FCM

- **Automatic**: Cloud Functions automatically detect Firestore changes and send FCM messages
- **Manual**: Fallback method available via `FirebaseService.sendFCMMessage()` if needed

### FCM Token Storage

- FCM tokens are automatically stored in Firestore alongside device statuses
- Tokens are managed by the Flutter `FcmService` and updated in `StatusController`
- Cloud Functions read tokens from Firestore to send targeted notifications
- Tokens are refreshed automatically when they change

### Security

- Cloud Functions run with appropriate Firestore security rules
- Only authenticated users can read/write room data
- FCM messages are sent server-side, not from client devices
- No sensitive API keys exposed in client code

## Android permissions

The receiver device must grant the **Do Not Disturb** access permission so the
app can change the ringer mode. When you switch a device into receiver mode,
the dashboard shows a prompt to request permission and directs the user to the
system settings panel.

## Running the app

1. Connect an Android device (or start an emulator) and verify detection:
   ```bash
   flutter devices
   ```
2. Launch the app:
   ```bash
   flutter run -d <device-id>
   ```
3. Repeat on the second phone. Choose matching pairing codes and designate one
   device as **Remote Controller** and the other as **Receiver**.

## Usage workflow

1. First launch presents a short carousel—tap through or skip to start pairing.
2. Enter the same pairing code (letters/numbers) on both phones.
3. Choose which phone acts as **Remote controller**; the other becomes the receiver.
4. Tap **Connect** on each device.
5. On the receiver, grant Do Not Disturb permission when prompted.
6. The remote phone now shows the paired device card; tap the icon to cycle
   between ring, vibrate, and silent.
7. To change codes or roles later, open **Settings → Unpair this device**.

## Testing

Run the unit tests (mocks Firebase/Audio layers) with:

```bash
flutter test
```

## Notes & limitations

- Firestore security rules are not included; configure appropriate rules before
  shipping.
- Audio control is currently implemented for Android only.
- The placeholder Firebase configuration must be replaced prior to running on
  a real device.
