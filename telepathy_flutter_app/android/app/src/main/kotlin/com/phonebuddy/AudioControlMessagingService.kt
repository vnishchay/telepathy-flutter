package com.phonebuddy

import android.content.Intent
import android.util.Log
import com.google.firebase.FirebaseApp
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class AudioControlMessagingService : FirebaseMessagingService() {

    companion object {
        private const val TAG = "AudioControlMessaging"
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        Log.d(TAG, "=== FCM Message Received ===")
        Log.d(TAG, "From: ${remoteMessage.from}")
        Log.d(TAG, "Message ID: ${remoteMessage.messageId}")
        Log.d(TAG, "Message Type: ${remoteMessage.messageType}")
        Log.d(TAG, "Data: ${remoteMessage.data}")
        Log.d(TAG, "Notification: ${remoteMessage.notification?.title} - ${remoteMessage.notification?.body}")

        // Initialize Firebase if needed
        if (FirebaseApp.getApps(this).isEmpty()) {
            FirebaseApp.initializeApp(this)
            Log.d(TAG, "Firebase initialized in AudioControlMessagingService")
        }

        // Check if message contains a data payload
        remoteMessage.data.let { data ->
            Log.d(TAG, "Message data keys: ${data.keys}")
            val profile = data["profile"]
            if (profile != null) {
                Log.d(TAG, "Audio profile update received: $profile")
                Log.d(TAG, "Starting AudioControlService to apply profile change")
                handleAudioProfileUpdate(profile)
            } else {
                Log.w(TAG, "No profile found in FCM message data")
            }
        }
    }

    override fun onNewToken(token: String) {
        Log.d(TAG, "Refreshed token: $token")
        // Send token to your server or store it
        sendRegistrationToServer(token)
    }

    private fun handleAudioProfileUpdate(profile: String) {
        Log.d(TAG, "Handling audio profile update: $profile")
        val serviceIntent = Intent(this, AudioControlService::class.java).apply {
            action = AudioControlService.ACTION_SET_AUDIO_PROFILE
            putExtra(AudioControlService.EXTRA_PROFILE, profile)
        }

        try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent)
                Log.d(TAG, "Started foreground service for profile: $profile")
            } else {
                startService(serviceIntent)
                Log.d(TAG, "Started service for profile: $profile")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start AudioControlService: ${e.message}", e)
        }
    }

    private fun sendRegistrationToServer(token: String) {
        // Store the FCM token in SharedPreferences for later use
        // This will be sent to Firestore when the device connects
        val prefs = getSharedPreferences("telepathy_prefs", MODE_PRIVATE)
        prefs.edit().putString("fcm_token", token).apply()
    }
}
