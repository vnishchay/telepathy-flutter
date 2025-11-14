package com.phonebuddy

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.app.NotificationManagerCompat
import com.google.firebase.FirebaseApp
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import java.util.Locale

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

        AudioNotificationHelper.ensureChannels(this)

        if (FirebaseApp.getApps(this).isEmpty()) {
            FirebaseApp.initializeApp(this)
            Log.d(TAG, "Firebase initialized in AudioControlMessagingService")
        }

        val data = remoteMessage.data
        val profile = data["profile"]
        val type = data["type"]
        val timestamp = data["timestamp"]

        Log.d(TAG, "Profile: $profile, Type: $type, Timestamp: $timestamp")

        val isForeground = isAppInForeground()
        val shouldShowNotification = !isForeground

        if (profile != null && type == "profile_update") {
            Log.d(TAG, "Audio profile update received: $profile")
            Log.d(TAG, "Ensuring AudioControlService is running")
            AudioControlService.startWithProfile(this, profile)

            if (shouldShowNotification) {
                val title = remoteMessage.notification?.title ?: "PhoneBuddy"
                val body = remoteMessage.notification?.body
                    ?: "Audio profile updated to ${profile.replaceFirstChar { if (it.isLowerCase()) it.titlecase(Locale.getDefault()) else it.toString() }}"
                showBackgroundNotification(title, body, data)
            }
        } else {
            Log.w(TAG, "Invalid or missing profile data in FCM message")

            if (shouldShowNotification && remoteMessage.notification != null) {
                showBackgroundNotification(
                    remoteMessage.notification!!.title ?: "PhoneBuddy",
                    remoteMessage.notification!!.body ?: "You have a new update",
                    data
                )
            }
        }
    }

    override fun onNewToken(token: String) {
        Log.d(TAG, "Refreshed token: $token")
        sendRegistrationToServer(token)
    }

    private fun showBackgroundNotification(
        title: String,
        body: String,
        data: Map<String, String>
    ) {
        val notification = AudioNotificationHelper.buildBackgroundNotification(
            context = this,
            title = title,
            body = body,
            data = data
        )
        NotificationManagerCompat.from(this)
            .notify(AudioNotificationHelper.BACKGROUND_NOTIFICATION_ID, notification)
    }

    private fun isAppInForeground(): Boolean {
        val manager = getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager ?: return false
        val runningProcesses = manager.runningAppProcesses ?: return false

        val packageName = packageName
        for (process in runningProcesses) {
            if (process.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND &&
                process.processName == packageName
            ) {
                return true
            }
        }
        return false
    }

    private fun sendRegistrationToServer(token: String) {
        val prefs = getSharedPreferences("telepathy_prefs", MODE_PRIVATE)
        prefs.edit().putString("fcm_token", token).apply()
    }
}
