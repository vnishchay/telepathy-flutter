package com.phonebuddy

import android.content.Intent
import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class AudioControlMessagingService : FirebaseMessagingService() {

    companion object {
        private const val TAG = "AudioControlMessaging"
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        Log.d(TAG, "From: ${remoteMessage.from}")

        // Check if message contains a data payload
        remoteMessage.data.let { data ->
            val profile = data["profile"]
            if (profile != null) {
                Log.d(TAG, "Audio profile update received: $profile")
                handleAudioProfileUpdate(profile)
            }
        }
    }

    override fun onNewToken(token: String) {
        Log.d(TAG, "Refreshed token: $token")
        // Send token to your server or store it
        sendRegistrationToServer(token)
    }

    private fun handleAudioProfileUpdate(profile: String) {
        val serviceIntent = Intent(this, AudioControlService::class.java).apply {
            action = AudioControlService.ACTION_SET_AUDIO_PROFILE
            putExtra(AudioControlService.EXTRA_PROFILE, profile)
        }

        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
    }

    private fun sendRegistrationToServer(token: String) {
        // Store the FCM token in SharedPreferences for later use
        // This will be sent to Firestore when the device connects
        val prefs = getSharedPreferences("telepathy_prefs", MODE_PRIVATE)
        prefs.edit().putString("fcm_token", token).apply()
    }
}
