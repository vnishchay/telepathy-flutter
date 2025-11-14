# 🚨 URGENT: Security Actions Required

## Critical: Exposed API Key Detected

Google has detected that API key `AIzaSyDGzCtnv_2IeU5ytj8J1rEu14U5ovRITbo` was exposed in the public GitHub repository.

## ✅ Actions Already Completed

1. ✓ Removed `google-services.json` from Git history
2. ✓ File is in `.gitignore` (will not be committed)
3. ✓ Moved old local file (contains exposed key)
4. ✓ Created security documentation

## 🔴 IMMEDIATE ACTIONS REQUIRED (Do Now!)

### 1. Regenerate API Key in Google Cloud Console

**URGENT - Do this first:**

1. Go to: https://console.cloud.google.com/apis/credentials?project=myblogs-1f4ac
2. Find API key: `AIzaSyDGzCtnv_2IeU5ytj8J1rEu14U5ovRITbo`
3. Click on it → **"REGENERATE KEY"** → Confirm
4. **Copy the new key immediately** (you won't see it again)

### 2. Download New google-services.json from Firebase

1. Go to: https://console.firebase.google.com/project/myblogs-1f4ac/settings/general
2. Scroll to "Your apps" → Android app (`com.phonebuddy`)
3. Click **"Download google-services.json"**
4. Place it at: `telepathy_flutter_app/android/app/google-services.json`
5. **DO NOT COMMIT THIS FILE** - It's already in `.gitignore`

### 3. Add API Key Restrictions (Critical!)

**This prevents abuse even if the key is exposed again:**

1. In Google Cloud Console → Credentials
2. Click on your **new** API key
3. **API restrictions**:
   - Select "Restrict key"
   - Enable ONLY:
     - ✅ Firebase Cloud Messaging API
     - ✅ Firebase Installations API
     - ✅ Firebase Remote Config API (if used)
4. **Application restrictions**:
   - Select "Android apps"
   - Add package name: `com.phonebuddy`
   - Add SHA-1 fingerprint (get from your keystore):
     ```bash
     keytool -list -v -keystore ~/keystores/telepathy-release.jks -alias telepathy
     ```
5. **Save**

### 4. Force Push Cleaned History

**WARNING**: This rewrites Git history. Coordinate with team first!

```bash
cd /home/nishv/Documents/telepathy-flutter

# Force push to remove exposed key from remote history
git push origin --force --all
git push origin --force --tags
```

**Note**: Anyone who cloned before this fix will still have the old key. Consider notifying team members.

### 5. Monitor for Abuse

1. Go to: https://console.cloud.google.com/apis/dashboard?project=myblogs-1f4ac
2. Check API usage for unusual activity
3. Review billing for unexpected charges
4. Set up billing alerts

## 📋 Verification Checklist

- [ ] Old API key regenerated in Google Cloud Console
- [ ] New `google-services.json` downloaded from Firebase
- [ ] New file placed at `telepathy_flutter_app/android/app/google-services.json`
- [ ] API key restrictions added (API + Android app restrictions)
- [ ] App tested with new credentials
- [ ] Git history force-pushed (if team coordinated)
- [ ] Billing/usage monitored for suspicious activity

## 🛡️ Prevention

### Pre-commit Hook (Recommended)

Create `.git/hooks/pre-commit`:
```bash
#!/bin/bash
if git diff --cached --name-only | grep -E "(google-services\.json|key\.properties|\.jks)"; then
    echo "❌ ERROR: Attempted to commit sensitive file!"
    exit 1
fi
```

Make executable:
```bash
chmod +x .git/hooks/pre-commit
```

### Always Check Before Committing

```bash
# Preview what will be committed
git status
git diff --cached

# If you see google-services.json, DO NOT COMMIT
```

## 📞 Need Help?

- **Google Cloud Support**: https://cloud.google.com/support
- **Firebase Support**: https://firebase.google.com/support
- **Security Best Practices**: https://cloud.google.com/docs/security

---

**Status**: Old file moved to `.OLD.EXPOSED_KEY`. Download new file from Firebase Console.

