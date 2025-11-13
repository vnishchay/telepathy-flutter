# Google Sign-In Setup Guide

## Error Code 10 (DEVELOPER_ERROR) Fix

This error occurs when the SHA-1 fingerprint is not configured in Firebase Console.

## Steps to Fix:

### 1. Get Your SHA-1 Fingerprint

**Debug SHA-1 (for development):**
```
F7:C3:71:10:49:05:64:1C:3A:7D:18:30:19:D6:57:82:EF:BE:D4:AA
```

**To get release SHA-1 (for production):**
```bash
cd android
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Or if you have a release keystore:
```bash
keytool -list -v -keystore /path/to/your/release.keystore -alias your-key-alias
```

### 2. Add SHA-1 to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Project Settings** (gear icon)
4. Scroll down to **Your apps** section
5. Find your Android app (package name: `com.phonebuddy`)
6. Click **Add fingerprint**
7. Paste your SHA-1 fingerprint: `F7:C3:71:10:49:05:64:1C:3A:7D:18:30:19:D6:57:82:EF:BE:D4:AA`
8. Click **Save**

### 3. Enable Google Sign-In

1. In Firebase Console, go to **Authentication**
2. Click on **Sign-in method** tab
3. Find **Google** in the list
4. Click on it and **Enable** it
5. Enter your **Support email** (required)
6. Click **Save**

### 4. Download Updated google-services.json

After adding the SHA-1 fingerprint:

1. Go back to **Project Settings**
2. Scroll to **Your apps** section
3. Click the **Download google-services.json** button
4. Replace the existing file at: `telepathy_flutter_app/android/app/google-services.json`

### 5. Verify Configuration

Make sure your `google-services.json` file contains:
- Package name: `com.phonebuddy`
- OAuth client IDs for Google Sign-In

### 6. Rebuild the App

After updating Firebase configuration:

```bash
cd telepathy_flutter_app
flutter clean
flutter pub get
flutter run
```

## Troubleshooting

- **Still getting error?** Wait a few minutes after adding SHA-1 - Firebase needs time to propagate changes
- **Production builds?** Make sure to add your release keystore SHA-1 fingerprint as well
- **Multiple environments?** Add SHA-1 fingerprints for all keystores you use (debug, release, etc.)

## Package Name

Your app's package name is: `com.phonebuddy`

Make sure this matches exactly in:
- `android/app/build.gradle.kts` (applicationId)
- `AndroidManifest.xml` (package attribute)
- Firebase Console app registration

