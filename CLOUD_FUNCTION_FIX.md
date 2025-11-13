# Cloud Function Fix - FCM Notifications

## Issue
The Cloud Function was not sending FCM notifications when the remote device changed the receiver's profile.

## Root Cause
The old Cloud Function only triggered FCM when:
- A **remote** device updated its **own** document
- The update had to have `role === 'remote'`

However, when `cyclePartnerProfile()` is called, it updates the **receiver's** document (not the remote's), so the function was skipping the notification.

## Solution
Updated the Cloud Function to handle **both scenarios**:

1. **Case 1**: Remote device updates receiver's profile (via `cyclePartnerProfile`)
   - Detects when receiver document is updated
   - Sends FCM notification to receiver device

2. **Case 2**: Remote device updates its own profile
   - Detects when remote document is updated
   - Sends FCM notification to receiver device

## Changes Made

### 1. Updated Cloud Function Logic (`functions/index.js`)
- Removed the restrictive check that only allowed remote role updates
- Added logic to detect receiver document updates
- Added extensive logging for debugging
- Handles both update scenarios

### 2. Enhanced Logging
The function now logs:
- When it's triggered
- Pairing code and device ID
- Before/after data
- Device roles and FCM tokens
- Why it's skipping (if applicable)
- Success/failure of FCM sending

## Testing

After deployment, test by:

1. **Pair two devices** (one remote, one receiver)
2. **On remote device**: Tap the cycle button to change receiver's profile
3. **Check logs**: 
   ```bash
   firebase functions:log | grep sendAudioProfileUpdate
   ```
4. **Verify**: Receiver device should receive FCM notification and apply profile change

## Monitoring

To monitor the function:
```bash
# View recent logs
firebase functions:log | grep sendAudioProfileUpdate

# View logs in real-time
firebase functions:log --follow
```

## Expected Log Output

When working correctly, you should see:
```
=== Cloud Function Triggered ===
Pairing Code: ABC123
Device ID: {deviceId}
Profile changed: ringing -> vibrate
Total devices in room: 2
Device roles - Remote: {remoteId}, Receiver: {receiverId}
Sending FCM: Receiver profile updated (likely by remote), notifying receiver device
Successfully sent FCM message to receiver: {...}
```

## Deployment

The function has been deployed. If you need to redeploy:
```bash
cd /home/nishv/Documents/telepathy-flutter
./deploy_functions.sh
```

Or manually:
```bash
cd functions
npm install
firebase deploy --only functions
```

