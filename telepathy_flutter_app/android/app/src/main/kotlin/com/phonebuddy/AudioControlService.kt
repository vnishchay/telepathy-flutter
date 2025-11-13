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
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import androidx.core.app.NotificationCompat

class AudioControlService : Service() {

    companion object {
        private const val TAG = "AudioControlService"
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
        Log.d(TAG, "AudioControlService created")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_SET_AUDIO_PROFILE -> {
                val profile = intent.getStringExtra(EXTRA_PROFILE)
                if (profile != null) {
                    Log.d(TAG, "Received audio profile change request: $profile")
                    handleAudioProfileChange(profile)
                } else {
                    Log.e(TAG, "Profile extra is null")
                }
            }
            else -> {
                Log.d(TAG, "Unknown action: ${intent?.action}")
            }
        }

        startForeground(NOTIFICATION_ID, createNotification())
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun hasNotificationPolicyAccess(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            notificationManager.isNotificationPolicyAccessGranted
        } else {
            true // No restriction on older Android versions
        }
    }

    private fun handleAudioProfileChange(profile: String) {
        Log.d(TAG, "Attempting to change audio profile to: $profile")
        
        // Check if we have notification policy access (required for ringer mode changes)
        if (!hasNotificationPolicyAccess()) {
            Log.e(TAG, "Notification policy access not granted. Cannot change ringer mode.")
            // Send broadcast to notify app that permission is needed
            sendBroadcast(Intent("com.phonebuddy.PERMISSION_REQUIRED").apply {
                putExtra("required_permission", "ACCESS_NOTIFICATION_POLICY")
            })
            return
        }

        val ringerMode = when (profile.lowercase()) {
            "ringing", "ring" -> AudioManager.RINGER_MODE_NORMAL
            "vibrate", "vibration" -> AudioManager.RINGER_MODE_VIBRATE
            "silent" -> AudioManager.RINGER_MODE_SILENT
            else -> {
                Log.w(TAG, "Unknown profile: $profile, defaulting to NORMAL")
                AudioManager.RINGER_MODE_NORMAL
            }
        }

        try {
            val currentMode = audioManager.ringerMode
            Log.d(TAG, "Current ringer mode: $currentMode, Target mode: $ringerMode")
            
            if (currentMode != ringerMode) {
                audioManager.ringerMode = ringerMode
                val newMode = audioManager.ringerMode
                Log.d(TAG, "Successfully changed ringer mode to: $newMode")
                
                // Verify the change was applied
                if (newMode == ringerMode) {
                    Log.d(TAG, "Ringer mode change confirmed: $profile")
                    // Provide vibration feedback to user
                    vibrateFeedback()
                } else {
                    Log.w(TAG, "Ringer mode change may have failed. Expected: $ringerMode, Got: $newMode")
                }
            } else {
                Log.d(TAG, "Ringer mode already set to: $profile")
            }
        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException when changing ringer mode: ${e.message}", e)
            // Send broadcast to notify app that permission is needed
            sendBroadcast(Intent("com.phonebuddy.PERMISSION_REQUIRED").apply {
                putExtra("required_permission", "MODIFY_AUDIO_SETTINGS")
                putExtra("error", e.message)
            })
        } catch (e: Exception) {
            Log.e(TAG, "Exception when changing ringer mode: ${e.message}", e)
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

    private fun vibrateFeedback() {
        try {
            val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                vibratorManager.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }

            // Short vibration feedback (150ms) to indicate profile change
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(
                    VibrationEffect.createOneShot(
                        150,
                        VibrationEffect.DEFAULT_AMPLITUDE
                    )
                )
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(150)
            }
            Log.d(TAG, "Vibration feedback triggered")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to vibrate: ${e.message}", e)
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
