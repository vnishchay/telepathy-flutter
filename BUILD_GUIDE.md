# Build Guide for Telepathy Flutter App

## Prerequisites

1. **Flutter SDK** installed and configured
2. **Android Studio** or Android SDK tools installed
3. **Java JDK 17** (required for Android builds)
4. **Firebase configured** (google-services.json in place)

## Quick Build Commands

### Android Debug Build (for testing)

```bash
cd telepathy_flutter_app
flutter clean
flutter pub get
flutter build apk --debug
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`

### Android Release Build (for production)

```bash
cd telepathy_flutter_app
flutter clean
flutter pub get
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (for Google Play Store)

```bash
cd telepathy_flutter_app
flutter clean
flutter pub get
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

## Detailed Build Instructions

### 1. Prepare for Release Build

Before building for release, you need to:

#### a) Update Version Number

Edit `pubspec.yaml`:
```yaml
version: 1.0.0+1  # Format: version_name+build_number
```

- `1.0.0` = version name (shown to users)
- `1` = build number (incremented for each release)

#### b) Configure Signing (Android)

For release builds, you need a signing key. Create a keystore:

```bash
cd telepathy_flutter_app/android
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Then create `android/key.properties`:
```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=upload
storeFile=<path-to-your-keystore-file>
```

Update `android/app/build.gradle.kts` to use signing config (see build script below).

### 2. Build Types

#### Debug Build
- Includes debugging symbols
- Not optimized
- Larger file size
- For development/testing only

```bash
flutter build apk --debug
```

#### Profile Build
- Optimized for performance
- Includes debugging symbols
- For performance testing

```bash
flutter build apk --profile
```

#### Release Build
- Fully optimized
- No debugging symbols
- Smallest file size
- For production

```bash
flutter build apk --release
```

### 3. Build for Specific Platforms

#### Android Only
```bash
flutter build apk --release
```

#### iOS (requires macOS and Xcode)
```bash
flutter build ios --release
```

#### Web
```bash
flutter build web --release
```

### 4. Build Variants

#### Split APKs by ABI (smaller downloads)
```bash
flutter build apk --release --split-per-abi
```

This creates separate APKs for:
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM)
- `app-x86_64-release.apk` (64-bit x86)

#### Single APK (universal)
```bash
flutter build apk --release
```

## Build Scripts

See `build_android.sh` for automated build script.

## Troubleshooting

### Build Fails with "Gradle Error"
```bash
cd telepathy_flutter_app/android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk --release
```

### Build Fails with "Signing Error"
- Make sure `key.properties` exists and is configured correctly
- Verify keystore file path is correct
- Check passwords are correct

### Build Fails with "Firebase Error"
- Ensure `google-services.json` is in `android/app/` directory
- Verify SHA-1 fingerprint is added to Firebase Console
- Download fresh `google-services.json` from Firebase Console

### Build Size Too Large
- Use `--split-per-abi` to create separate APKs
- Use App Bundle (`.aab`) for Play Store (smaller size)
- Check for unused assets/resources

## Installing the Build

### Install Debug APK
```bash
flutter install
# or
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### Install Release APK
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Uploading to Play Store

1. Build App Bundle:
   ```bash
   flutter build appbundle --release
   ```

2. Go to [Google Play Console](https://play.google.com/console)
3. Create new app or select existing
4. Go to **Production** → **Create new release**
5. Upload `app-release.aab` file
6. Fill in release notes
7. Submit for review

## Version Management

### Increment Version for New Release

Edit `pubspec.yaml`:
```yaml
version: 1.0.1+2  # Increment both version and build number
```

Or use command line:
```bash
flutter build apk --release --build-name=1.0.1 --build-number=2
```

## Build Output Locations

- **Debug APK**: `build/app/outputs/flutter-apk/app-debug.apk`
- **Release APK**: `build/app/outputs/flutter-apk/app-release.apk`
- **App Bundle**: `build/app/outputs/bundle/release/app-release.aab`
- **Split APKs**: `build/app/outputs/flutter-apk/`

