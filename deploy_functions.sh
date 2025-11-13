#!/bin/bash

# Telepathy App - Cloud Functions Deployment Script

echo "🚀 Deploying Telepathy Cloud Functions..."

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Install with: npm install -g firebase-tools"
    exit 1
fi

# Check if user is logged in
if ! firebase projects:list &> /dev/null; then
    echo "❌ Not logged in to Firebase. Run: firebase login"
    exit 1
fi

# Navigate to project root
cd "$(dirname "$0")"

# Install Cloud Functions dependencies
echo "📦 Installing Cloud Functions dependencies..."
cd functions
npm install
cd ..

# Deploy functions
echo "🔥 Deploying Cloud Functions..."
firebase deploy --only functions

if [ $? -eq 0 ]; then
    echo "✅ Cloud Functions deployed successfully!"
    echo ""
    echo "📱 Your telepathy app is now ready for background audio control!"
    echo ""
    echo "Next steps:"
    echo "1. Build and run the Flutter app on your devices"
    echo "2. Test the remote control functionality"
    echo "3. FCM messages will now work even when the receiver app is closed"
else
    echo "❌ Deployment failed. Check the error messages above."
    exit 1
fi
