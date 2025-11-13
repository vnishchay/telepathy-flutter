package com.phonebuddy

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class AudioControlService : Service() {

    companion object {
        private const val CHANNEL_ID = "audio_control_channel"
        private const val NOTIFICATION_ID = 1001
        const val ACTION_SET_AUDIO_PROFILE = "SET_AUDIO_PROFILE"
        const val EXTRA_PROFILE = "profile"
    }

    private lateinit var audioManager: AudioManager
    private lateinit var notificationManager: NotificationManager

    override fun onCreate() {
        super.onCreate()
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_SET_AUDIO_PROFILE -> {
                val profile = intent.getStringExtra(EXTRA_PROFILE)
                if (profile != null) {
                    handleAudioProfileChange(profile)
                }
            }
        }

        startForeground(NOTIFICATION_ID, createNotification())
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun handleAudioProfileChange(profile: String) {
        val ringerMode = when (profile) {
            "ringing" -> AudioManager.RINGER_MODE_NORMAL
            "vibrate" -> AudioManager.RINGER_MODE_VIBRATE
            "silent" -> AudioManager.RINGER_MODE_SILENT
            else -> AudioManager.RINGER_MODE_NORMAL
        }

        try {
            audioManager.ringerMode = ringerMode
        } catch (e: SecurityException) {
            // Handle case where Do Not Disturb access is not granted
            // Could potentially request permission here, but this is a background service
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Audio Control",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Handles audio profile changes from remote device"
                setShowBadge(false)
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("PhoneBuddy Active")
            .setContentText("Monitoring audio control requests")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()
    }
}
