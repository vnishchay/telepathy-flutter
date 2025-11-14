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
import com.google.firebase.FirebaseApp
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.SetOptions
import java.util.Date

class AudioControlService : Service() {

    companion object {
        private const val TAG = "AudioControlService"
        private const val CHANNEL_ID = "audio_control_channel"
        private const val NOTIFICATION_ID = 1001
        const val ACTION_SET_AUDIO_PROFILE = "SET_AUDIO_PROFILE"
        const val ACTION_START_SERVICE = "START_SERVICE"
        const val ACTION_STOP_SERVICE = "STOP_SERVICE"
        const val EXTRA_PROFILE = "profile"
    }

    private lateinit var audioManager: AudioManager
    private lateinit var notificationManager: NotificationManager
    private lateinit var firestore: FirebaseFirestore

    override fun onCreate() {
        super.onCreate()

        // Initialize Firebase if not already initialized
        if (FirebaseApp.getApps(this).isEmpty()) {
            FirebaseApp.initializeApp(this)
            Log.d(TAG, "Firebase initialized in AudioControlService")
        }

        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        firestore = FirebaseFirestore.getInstance()
        createNotificationChannel()
        Log.d(TAG, "AudioControlService created")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "=== onStartCommand called ===")
        Log.d(TAG, "Action: ${intent?.action}")
        Log.d(TAG, "Flags: $flags, StartId: $startId")
        
        when (intent?.action) {
            ACTION_START_SERVICE -> {
                Log.d(TAG, "Service start requested - keeping service running")
                startForeground(NOTIFICATION_ID, createNotification())
                // Store pairing info for later use
                storePairingInfo()
            }
            ACTION_STOP_SERVICE -> {
                Log.d(TAG, "Service stop requested")
                stopForeground(true)
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_SET_AUDIO_PROFILE -> {
                val profile = intent.getStringExtra(EXTRA_PROFILE)
                if (profile != null) {
                    Log.d(TAG, "=== Received audio profile change request: $profile ===")
                    Log.d(TAG, "Current ringer mode before change: ${audioManager.ringerMode}")
                    handleAudioProfileChange(profile)
                    Log.d(TAG, "Current ringer mode after change: ${audioManager.ringerMode}")
                } else {
                    Log.e(TAG, "Profile extra is null - cannot process audio change")
                }
            }
            else -> {
                Log.d(TAG, "Unknown action: ${intent?.action}, starting service anyway")
                startForeground(NOTIFICATION_ID, createNotification())
            }
        }

        // Keep service running even if app is closed
        // START_STICKY ensures service restarts if killed by system
        startForeground(NOTIFICATION_ID, createNotification())
        Log.d(TAG, "Service running in foreground with START_STICKY")
        return START_STICKY // Keep service running even if app is closed
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun hasNotificationPolicyAccess(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            notificationManager.isNotificationPolicyAccessGranted
        } else {
            true // No restriction on older Android versions
        }
    }

    private fun disableDoNotDisturb() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && hasNotificationPolicyAccess()) {
                // Check current interruption filter
                val currentFilter = notificationManager.currentInterruptionFilter
                Log.d(TAG, "Current interruption filter: $currentFilter")

                // If DND is active (filter is not ALL), disable it
                if (currentFilter != NotificationManager.INTERRUPTION_FILTER_ALL) {
                    notificationManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
                    Log.d(TAG, "Disabled Do Not Disturb mode")
                } else {
                    Log.d(TAG, "Do Not Disturb already disabled")
                }
            } else {
                Log.d(TAG, "Cannot control DND: API level < M or no notification policy access")
            }
        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException when disabling DND: ${e.message}", e)
        } catch (e: Exception) {
            Log.e(TAG, "Exception when disabling DND: ${e.message}", e)
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
            // Disable Do Not Disturb mode if we're setting to ring or vibrate
            if (profile.lowercase() in listOf("ringing", "ring", "vibrate", "vibration")) {
                disableDoNotDisturb()
            }

            val currentMode = audioManager.ringerMode
            Log.d(TAG, "Current ringer mode: $currentMode, Target mode: $ringerMode")

            if (currentMode != ringerMode) {
                audioManager.ringerMode = ringerMode
                val newMode = audioManager.ringerMode
                Log.d(TAG, "Successfully changed ringer mode to: $newMode")

                // Verify the change was applied
                if (newMode == ringerMode) {
                    Log.d(TAG, "Ringer mode change confirmed: $profile")
                    // Don't update Firestore here - it's already updated by the remote device
                    // Updating from background service causes SecurityException
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

    private fun storePairingInfo() {
        try {
            val prefs = getSharedPreferences("telepathy_prefs", MODE_PRIVATE)
            val pairingCode = prefs.getString("pairing_code", null)
            val deviceId = prefs.getString("device_id", null)
            val isRemote = prefs.getBoolean("is_remote", false)
            
            Log.d(TAG, "Stored pairing info - Code: $pairingCode, Device: $deviceId, Remote: $isRemote")
        } catch (e: Exception) {
            Log.e(TAG, "Exception storing pairing info: ${e.message}", e)
        }
    }

    private fun updateFirestoreProfile(profile: String) {
        try {
            // Get pairing info from SharedPreferences
            val prefs = getSharedPreferences("telepathy_prefs", MODE_PRIVATE)
            val pairingCode = prefs.getString("pairing_code", null)
            val deviceId = prefs.getString("device_id", null)
            val isRemote = prefs.getBoolean("is_remote", false)

            if (pairingCode == null || deviceId == null) {
                Log.w(TAG, "Cannot update Firestore: pairing info not available")
                return
            }

            // Only update if this is a receiver device (not remote controller)
            if (isRemote) {
                Log.d(TAG, "Skipping Firestore update: device is remote controller")
                return
            }

            Log.d(TAG, "Updating Firestore profile: $profile for device: $deviceId in room: $pairingCode")

            // Create the update data
            val updateData = hashMapOf<String, Any>(
                "profile" to profile,
                "updatedAt" to com.google.firebase.Timestamp.now()
            )

            // Update the device document in Firestore
            firestore.collection("rooms")
                .document(pairingCode)
                .collection("devices")
                .document(deviceId)
                .set(updateData, SetOptions.merge())
                .addOnSuccessListener {
                    Log.d(TAG, "Successfully updated Firestore profile: $profile")
                }
                .addOnFailureListener { e ->
                    Log.e(TAG, "Failed to update Firestore profile: ${e.message}", e)
                }

        } catch (e: Exception) {
            Log.e(TAG, "Exception updating Firestore profile: ${e.message}", e)
        }
    }
}
