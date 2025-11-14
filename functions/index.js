const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Cloud Function to send FCM messages when audio profiles are updated
exports.sendAudioProfileUpdate = functions.firestore
  .document('rooms/{pairingCode}/devices/{deviceId}')
  .onUpdate(async (change, context) => {
    console.log('=== Cloud Function Triggered ===');
    console.log('Pairing Code:', context.params.pairingCode);
    console.log('Device ID:', context.params.deviceId);
    console.log('Before data:', JSON.stringify(change.before.data()));
    console.log('After data:', JSON.stringify(change.after.data()));
    
    const newData = change.after.data();
    const previousData = change.before.data();

    // Skip if profile hasn't changed
    if (previousData.profile === newData.profile) {
      console.log('Skipping FCM: profile unchanged');
      console.log('Previous profile:', previousData.profile);
      console.log('New profile:', newData.profile);
      return null;
    }
    
    console.log('Profile changed:', previousData.profile, '->', newData.profile);

    // Get all devices in this room to validate pairing
    const devicesRef = change.after.ref.parent;
    const devicesSnapshot = await devicesRef.get();

    console.log('Total devices in room:', devicesSnapshot.size);
    devicesSnapshot.forEach((doc) => {
      console.log(`Device ${doc.id}:`, JSON.stringify(doc.data()));
    });

    if (devicesSnapshot.empty || devicesSnapshot.size !== 2) {
      console.log('Skipping FCM: room must have exactly 2 devices to be paired');
      console.log('Current device count:', devicesSnapshot.size);
      return null;
    }

    // Find remote and receiver devices
    let remoteDevice = null;
    let receiverDevice = null;
    let receiverFcmToken = null;
    let remoteFcmToken = null;

    devicesSnapshot.forEach((doc) => {
      const deviceData = doc.data();
      const docId = doc.id;

      if (deviceData.role === 'remote') {
        remoteDevice = docId;
        remoteFcmToken = deviceData.fcmToken;
      } else if (deviceData.role === 'receiver') {
        receiverDevice = docId;
        receiverFcmToken = deviceData.fcmToken;
      }
    });

    // Ensure we have both roles
    if (!remoteDevice || !receiverDevice) {
      console.log('Skipping FCM: missing remote/receiver roles');
      return null;
    }

    const updatedDeviceId = context.params.deviceId;
    const isReceiverUpdate = updatedDeviceId === receiverDevice;
    const isRemoteUpdate = updatedDeviceId === remoteDevice;

    console.log('Device roles - Remote:', remoteDevice, 'Receiver:', receiverDevice);
    console.log('Updated device ID:', updatedDeviceId);
    console.log('Is receiver update:', isReceiverUpdate);
    console.log('Is remote update:', isRemoteUpdate);
    console.log('Receiver FCM token:', receiverFcmToken ? 'Present' : 'Missing');
    
    // Case 1: Remote device updated receiver's profile (via cyclePartnerProfile)
    // IMPORTANT: Only send FCM when receiver document is updated by REMOTE device
    // We detect this by checking if the update includes fields that only remote would set
    // OR if the update happened without the receiver's deviceId being the one making the change
    // Since cyclePartnerProfile updates receiver's document, we need to ensure receiver itself
    // doesn't trigger FCM when it updates its own profile
    
    // Check: If receiver document updated, only send FCM if:
    // 1. Receiver has FCM token
    // 2. The update is NOT from receiver updating itself (we can't directly detect this, but
    //    receiver should only update Firestore when syncing status, not when applying FCM changes)
    // 3. Remote device exists and is paired
    
    if (isReceiverUpdate && newData.role === 'receiver' && remoteDevice && receiverFcmToken) {
      // Only send FCM if this looks like a remote-initiated update
      // Receiver updates its own profile via _syncLocalStatus, but that should only happen
      // when permissions change or initial sync, not when applying FCM changes
      console.log(`Sending FCM: Receiver profile updated by remote, notifying receiver device`);
        
        // Validate FCM token format
        if (!receiverFcmToken || typeof receiverFcmToken !== 'string' || receiverFcmToken.length < 10) {
          console.error('Invalid FCM token format:', receiverFcmToken);
          return null;
        }

        // For Android background message handling, we need BOTH data AND notification
        // The notification will be silent and not shown to user, but ensures delivery
        const payload = {
          data: {
            profile: newData.profile,
            pairingCode: context.params.pairingCode,
            senderId: remoteDevice,
            type: 'profile_update',
            timestamp: Date.now().toString(),
          },
          // Include a silent notification to ensure background delivery on Android
          notification: {
            title: 'Audio Control',
            body: 'Profile update received',
            // Make it silent by not setting sound
            android_channel_id: 'silent_channel',
          },
          android: {
            priority: 'high',
            // Use data message type for background handling
            notification: {
              channel_id: 'silent_channel',
              // Silent notification - no sound, no vibration, no lights
              default_sound: false,
              default_vibrate_timings: false,
              default_light_settings: false,
            },
          },
          apns: {
            headers: {
              'apns-priority': '10',
            },
            payload: {
              aps: {
                'content-available': 1, // Silent notification for iOS
                sound: '', // No sound
                badge: 0,
              },
            },
          },
        };

        try {
          console.log('Attempting to send FCM (with silent notification) to token:', receiverFcmToken.substring(0, 20) + '...');
          // Use send() method with data-only payload for background handling
          const message = {
            token: receiverFcmToken,
            data: payload.data,
            android: {
              priority: 'high',
            },
            apns: payload.apns,
          };
          
          const response = await admin.messaging().send(message);
          console.log('Successfully sent FCM message to receiver. Message ID:', response);
          return { success: true, messageId: response };
        } catch (error) {
          console.error('Failed to send FCM message:', error);
          console.error('Error code:', error.code);
          console.error('Error message:', error.message);
          
          // If token is invalid, log it but don't throw
          if (error.code === 'messaging/invalid-registration-token' || 
              error.code === 'messaging/registration-token-not-registered') {
            console.error('FCM token is invalid or unregistered. Receiver needs to refresh token.');
          }
          return null;
        }
    }

    // Case 2: REMOVED - Remote device updating its own profile should NOT notify receiver
    // Only remote updating receiver's profile should trigger FCM
    // This prevents unnecessary FCM messages when remote changes its own profile
    
    console.log('Skipping FCM: Only receiver profile updates from remote trigger FCM');
    return null;
  });

// Alternative callable function for manual FCM sending
exports.sendFCMMessage = functions.https.onCall(async (data, context) => {
  // Verify authentication (optional but recommended)
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'The function must be called while authenticated.'
    );
  }

  const { tokens, profile, pairingCode } = data;

  if (!tokens || !Array.isArray(tokens) || tokens.length === 0) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'FCM tokens array is required.'
    );
  }

  const payload = {
    data: {
      profile: profile || 'ringing',
      pairingCode: pairingCode || '',
    },
  };

  try {
    const response = await admin.messaging().sendToDevice(tokens, payload);
    console.log('FCM message sent successfully:', response);
    return { success: true, response };
  } catch (error) {
    console.error('Error sending FCM message:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send FCM message');
  }
});
