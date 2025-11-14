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

    const newData = change.after.data();
    const previousData = change.before.data();

    if (!newData || !previousData) {
      console.log('Missing data in change snapshot. Skipping.');
      return null;
    }

    if (previousData.profile === newData.profile) {
      console.log('Skipping FCM: profile unchanged');
      return null;
    }

    if (newData.role !== 'receiver') {
      console.log('Skipping FCM: updated document is not a receiver device');
      return null;
    }

    const updatedBy = newData.updatedBy;
    const receiverDeviceId = context.params.deviceId;

    if (!updatedBy) {
      console.log('Skipping FCM: missing updatedBy metadata (legacy client).');
      return null;
    }

    if (updatedBy === receiverDeviceId) {
      console.log('Skipping FCM: receiver updated its own status');
      return null;
    }

    const receiverFcmToken = typeof newData.fcmToken === 'string' ? newData.fcmToken : null;

    if (!receiverFcmToken || receiverFcmToken.length < 10) {
      console.log('Skipping FCM: receiver token unavailable or invalid');
      return null;
    }

    const payloadData = {
      profile: newData.profile,
      pairingCode: context.params.pairingCode,
      senderId: updatedBy,
      type: 'profile_update',
      timestamp: Date.now().toString(),
    };

    const message = {
      token: receiverFcmToken,
      data: payloadData,
      android: {
        priority: 'high',
      },
      apns: {
        headers: {
          'apns-priority': '10',
        },
        payload: {
          aps: {
            'content-available': 1,
            sound: '',
            badge: 0,
          },
        },
      },
    };

    try {
      console.log('Sending FCM to receiver token:', receiverFcmToken.substring(0, 20) + '...');
      const response = await admin.messaging().send(message);
      console.log('Successfully sent FCM message to receiver. Message ID:', response);
      return { success: true, messageId: response };
    } catch (error) {
      console.error('Failed to send FCM message:', error);
      return null;
    }
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
