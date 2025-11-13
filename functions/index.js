const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Cloud Function to send FCM messages when audio profiles are updated
exports.sendAudioProfileUpdate = functions.firestore
  .document('rooms/{pairingCode}/devices/{deviceId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const previousData = change.before.data();

    // Only proceed if this is a profile update from a remote controller
    if (newData.role !== 'remote' ||
        previousData.profile === newData.profile ||
        !newData.fcmToken) {
      console.log('Skipping FCM: not a valid remote controller profile update');
      return null;
    }

    // Get all devices in this room to validate pairing
    const devicesRef = change.after.ref.parent;
    const devicesSnapshot = await devicesRef.get();

    if (devicesSnapshot.empty || devicesSnapshot.size !== 2) {
      console.log('Skipping FCM: room must have exactly 2 devices to be paired');
      return null;
    }

    // Validate that we have both a remote and receiver device
    let remoteDevice = null;
    let receiverDevice = null;
    let receiverFcmToken = null;

    devicesSnapshot.forEach((doc) => {
      const deviceData = doc.data();

      if (deviceData.role === 'remote') {
        remoteDevice = doc.id;
      } else if (deviceData.role === 'receiver') {
        receiverDevice = doc.id;
        receiverFcmToken = deviceData.fcmToken;
      }
    });

    // Ensure we have both roles and the receiver has an FCM token
    if (!remoteDevice || !receiverDevice || !receiverFcmToken) {
      console.log('Skipping FCM: missing remote/receiver roles or receiver FCM token');
      return null;
    }

    // Only send FCM if the update is from the remote device to the receiver
    if (context.params.deviceId !== remoteDevice) {
      console.log('Skipping FCM: update not from remote controller');
      return null;
    }

    console.log(`Sending FCM from remote (${remoteDevice}) to receiver (${receiverDevice})`);

    const payload = {
      data: {
        profile: newData.profile,
        pairingCode: context.params.pairingCode,
        senderId: context.params.deviceId,
      },
    };

    try {
      const response = await admin.messaging().sendToDevice([receiverFcmToken], payload);
      console.log('Successfully sent FCM message:', response);
      return response;
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
