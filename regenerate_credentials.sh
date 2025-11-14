#!/bin/bash
# Script to help regenerate Firebase credentials after security fix
# This script guides you through the process

set -e

echo "=========================================="
echo "PhoneBuddy - Credential Regeneration"
echo "=========================================="
echo ""

PROJECT_ID="myblogs-1f4ac"
OLD_KEY="AIzaSyDGzCtnv_2IeU5ytj8J1rEu14U5ovRITbo"
PACKAGE_NAME="com.phonebuddy"
TARGET_FILE="telepathy_flutter_app/android/app/google-services.json"

echo "⚠️  IMPORTANT: The old API key was exposed and must be regenerated."
echo ""
echo "Step 1: Regenerate API Key in Google Cloud Console"
echo "---------------------------------------------------"
echo "1. Open: https://console.cloud.google.com/apis/credentials?project=${PROJECT_ID}"
echo "2. Find API key: ${OLD_KEY}"
echo "3. Click on it → Click 'REGENERATE KEY' → Confirm"
echo "4. Copy the new key"
echo ""
read -p "Press Enter after you've regenerated the API key..."

echo ""
echo "Step 2: Download New google-services.json from Firebase"
echo "-------------------------------------------------------"
echo "1. Open: https://console.firebase.google.com/project/${PROJECT_ID}/settings/general"
echo "2. Scroll to 'Your apps' section"
echo "3. Find Android app with package: ${PACKAGE_NAME}"
echo "4. Click 'Download google-services.json'"
echo "5. Save it to: ${TARGET_FILE}"
echo ""
read -p "Press Enter after you've downloaded the new google-services.json file..."

if [ ! -f "$TARGET_FILE" ]; then
    echo ""
    echo "❌ ERROR: File not found at ${TARGET_FILE}"
    echo "Please download it from Firebase Console and place it there."
    exit 1
fi

echo ""
echo "✓ File found at ${TARGET_FILE}"
echo ""

# Check if old key is still in the file
if grep -q "$OLD_KEY" "$TARGET_FILE" 2>/dev/null; then
    echo "⚠️  WARNING: Old exposed key still found in file!"
    echo "Please ensure you downloaded the NEW file from Firebase."
    exit 1
fi

echo "✓ Old key not found in new file (good!)"
echo ""

echo "Step 3: Add API Key Restrictions"
echo "--------------------------------"
echo "1. Go to: https://console.cloud.google.com/apis/credentials?project=${PROJECT_ID}"
echo "2. Click on your NEW API key"
echo "3. Under 'API restrictions':"
echo "   - Select 'Restrict key'"
echo "   - Enable ONLY:"
echo "     • Firebase Cloud Messaging API"
echo "     • Firebase Installations API"
echo "4. Under 'Application restrictions':"
echo "   - Select 'Android apps'"
echo "   - Add package name: ${PACKAGE_NAME}"
echo "   - Add SHA-1 fingerprint (get from keystore):"
echo "     keytool -list -v -keystore ~/keystores/telepathy-release.jks -alias telepathy"
echo "5. Click 'Save'"
echo ""
read -p "Press Enter after you've added API key restrictions..."

echo ""
echo "Step 4: Verify Setup"
echo "--------------------"
echo "Checking file location and git status..."

if [ -f "$TARGET_FILE" ]; then
    echo "✓ google-services.json exists"
    
    # Check if it's tracked by git (should NOT be)
    if git ls-files | grep -q "google-services.json"; then
        echo "❌ ERROR: File is tracked by git! Remove it:"
        echo "   git rm --cached ${TARGET_FILE}"
        exit 1
    else
        echo "✓ File is NOT tracked by git (correct)"
    fi
    
    # Check if it's in .gitignore
    if grep -q "google-services.json" .gitignore; then
        echo "✓ File is in .gitignore (correct)"
    else
        echo "⚠️  WARNING: File not in .gitignore!"
    fi
else
    echo "❌ ERROR: File not found"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Test the app: cd telepathy_flutter_app && flutter run"
echo "2. Monitor Google Cloud Console for unusual activity"
echo "3. Set up billing alerts"
echo ""
echo "The old exposed key has been removed from GitHub history."
echo "Your new credentials are secure and local-only."

