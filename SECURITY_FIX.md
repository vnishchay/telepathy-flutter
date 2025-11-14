# Security Fix: Exposed API Key

## ⚠️ Critical Security Issue

Google has detected that an API key was exposed in the public GitHub repository. The key `AIzaSyDGzCtnv_2IeU5ytj8J1rEu14U5ovRITbo` was found in `google-services.json` file.

## ✅ Immediate Actions Taken

1. **Removed from Git History**: The file has been removed from all commits using `git filter-branch`
2. **Added to .gitignore**: `google-services.json` is now properly excluded
3. **File Not in Working Directory**: The file is not currently tracked

## 🔒 Required Actions (Do These Now)

### Step 1: Regenerate the API Key in Google Cloud Console

1. **Go to Google Cloud Console**: https://console.cloud.google.com/
2. **Select Project**: `myBlogs (myblogs-1f4ac)`
3. **Navigate to APIs & Services → Credentials**
4. **Find the API Key**: `AIzaSyDGzCtnv_2IeU5ytj8J1rEu14U5ovRITbo`
5. **Click on the key → Edit**
6. **Click "Regenerate key"** → Confirm
7. **Copy the new key**

### Step 2: Download New google-services.json

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select Project**: `myblogs-1f4ac`
3. **Go to Project Settings** (gear icon)
4. **Scroll to "Your apps" section**
5. **Click on Android app** (com.phonebuddy)
6. **Download `google-services.json`**
7. **Place it at**: `telepathy_flutter_app/android/app/google-services.json`
8. **DO NOT COMMIT THIS FILE** - It's in `.gitignore`

### Step 3: Add API Key Restrictions (Important!)

1. **In Google Cloud Console → Credentials**
2. **Click on your API key**
3. **Under "API restrictions"**:
   - Select "Restrict key"
   - Enable only: **Firebase Cloud Messaging API**, **Firebase Installations API**
4. **Under "Application restrictions"**:
   - Select "Android apps"
   - Add package name: `com.phonebuddy`
   - Add SHA-1 certificate fingerprint (get from your keystore)
5. **Save**

### Step 4: Verify .gitignore

Ensure `.gitignore` contains:
```
**/google-services.json
```

### Step 5: Force Push Updated History

```bash
# WARNING: This rewrites history. Coordinate with team first!
git push origin --force --all
git push origin --force --tags
```

## 🛡️ Prevention Measures

### For All Team Members

1. **Never commit** `google-services.json` or `key.properties`
2. **Always check** `git status` before committing
3. **Use** `git add -n <file>` to preview what will be added
4. **Set up** pre-commit hooks to prevent accidental commits

### Pre-commit Hook (Optional but Recommended)

Create `.git/hooks/pre-commit`:
```bash
#!/bin/bash
# Prevent committing sensitive files
if git diff --cached --name-only | grep -E "(google-services\.json|key\.properties|\.jks|\.keystore)"; then
    echo "ERROR: Attempted to commit sensitive file!"
    echo "Files like google-services.json should never be committed."
    exit 1
fi
```

Make it executable:
```bash
chmod +x .git/hooks/pre-commit
```

## 📋 Checklist

- [ ] Regenerated API key in Google Cloud Console
- [ ] Downloaded new `google-services.json` from Firebase
- [ ] Added API key restrictions (API restrictions + Android app restrictions)
- [ ] Verified `.gitignore` excludes `google-services.json`
- [ ] Tested app with new credentials
- [ ] Force-pushed cleaned git history (if needed)
- [ ] Notified team members about the security fix

## 🔍 Verify Fix

1. **Check git history**:
   ```bash
   git log --all --full-history -- "**/google-services.json"
   ```
   Should return nothing or only show removal commits.

2. **Check current files**:
   ```bash
   git ls-files | grep google-services
   ```
   Should return nothing.

3. **Test app**: Build and run to ensure new credentials work.

## 📞 Support

If you need help:
- Google Cloud Support: https://cloud.google.com/support
- Firebase Support: https://firebase.google.com/support

## ⚠️ Important Notes

- The old API key is now compromised and should be considered invalid
- Anyone who cloned the repo before the fix may still have the old key
- Consider rotating all credentials if this was a production app
- Monitor Google Cloud Console for unusual API usage

