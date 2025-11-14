package com.phonebuddy

import android.app.Notification
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
import androidx.core.content.ContextCompat
import com.google.firebase.FirebaseApp
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.SetOptions

class AudioControlService : Service() {

    companion object {
        private const val TAG = "AudioControlService"
        private const val NOTIFICATION_ID = 1001
        const val ACTION_SET_AUDIO_PROFILE = "SET_AUDIO_PROFILE"
        const val ACTION_START_SERVICE = "START_SERVICE"
        const val ACTION_STOP_SERVICE = "STOP_SERVICE"
        const val EXTRA_PROFILE = "profile"

        fun start(context: Context) {
            val intent = Intent(context, AudioControlService::class.java).apply {
                action = ACTION_START_SERVICE
            }
            ContextCompat.startForegroundService(context, intent)
        }

        fun startWithProfile(context: Context, profile: String) {
            start(context)
            val updateIntent = Intent(context, AudioControlService::class.java).apply {
                action = ACTION_SET_AUDIO_PROFILE
                putExtra(EXTRA_PROFILE, profile)
            }
            ContextCompat.startForegroundService(context, updateIntent)
        }
    }

    private var audioManager: AudioManager? = null
    private var firestore: FirebaseFirestore? = null
    private var isForeground = false

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "AudioControlService onCreate called")

        try {
            audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
                ?: throw IllegalStateException("AudioManager not available")

            AudioNotificationHelper.ensureChannels(this)

            if (FirebaseApp.getApps(this).isNotEmpty()) {
                firestore = FirebaseFirestore.getInstance()
                Log.d(TAG, "Firestore initialized in AudioControlService")
            } else {
                Log.w(TAG, "Firebase not initialized - Firestore operations will be skipped")
            }

            Log.d(TAG, "AudioControlService created successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize AudioControlService: ${e.message}", e)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "=== onStartCommand called ===")
        Log.d(TAG, "Action: ${intent?.action}")
        Log.d(TAG, "Flags: $flags, StartId: $startId")

        if (intent?.action != ACTION_STOP_SERVICE) {
            ensureForeground()
        }

        when (intent?.action) {
            ACTION_START_SERVICE -> {
                Log.d(TAG, "Service start requested - keeping service running")
                storePairingInfo()
            }
            ACTION_STOP_SERVICE -> {
                Log.d(TAG, "Service stop requested")
                stopForeground(true)
                stopSelf()
                isForeground = false
                return START_NOT_STICKY
            }
            ACTION_SET_AUDIO_PROFILE -> {
                val profile = intent.getStringExtra(EXTRA_PROFILE)
                if (profile != null) {
                    Log.d(TAG, "=== Received audio profile change request: $profile ===")
                    Log.d(TAG, "Current ringer mode before change: ${audioManager?.ringerMode}")
                    handleAudioProfileChange(profile)
                    Log.d(TAG, "Current ringer mode after change: ${audioManager?.ringerMode}")
                } else {
                    Log.e(TAG, "Profile extra is null - cannot process audio change")
                }
            }
            else -> Log.d(TAG, "Unknown action: ${intent?.action}")
        }

        Log.d(TAG, "Service running in foreground with START_STICKY")
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        isForeground = false
        Log.d(TAG, "AudioControlService destroyed")
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun ensureForeground() {
        if (!isForeground) {
            startForeground(NOTIFICATION_ID, createNotification())
            isForeground = true
        }
    }

    private fun hasNotificationPolicyAccess(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val notificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as? android.app.NotificationManager
            notificationManager?.isNotificationPolicyAccessGranted ?: false
        } else {
            true
        }
    }

    private fun disableDoNotDisturb() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && hasNotificationPolicyAccess()) {
                val notificationManager =
                    getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
                val currentFilter = notificationManager.currentInterruptionFilter
                Log.d(TAG, "Current interruption filter: $currentFilter")

                if (currentFilter != android.app.NotificationManager.INTERRUPTION_FILTER_ALL) {
                    notificationManager.setInterruptionFilter(android.app.NotificationManager.INTERRUPTION_FILTER_ALL)
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
        Log.d(TAG, "=== handleAudioProfileChange called ===")
        Log.d(TAG, "Target profile: $profile")
        Log.d(TAG, "Current ringer mode: ${audioManager?.ringerMode}")

        if (!hasNotificationPolicyAccess()) {
            Log.e(TAG, "Notification policy access not granted. Cannot change ringer mode.")
            sendBroadcast(Intent("com.phonebuddy.PERMISSION_REQUIRED").apply {
                putExtra("required_permission", "ACCESS_NOTIFICATION_POLICY")
            })
            return
        }

        if (audioManager == null) {
            Log.e(TAG, "AudioManager not available. Cannot change ringer mode.")
            return
        }

        val ringerMode = when (profile.lowercase()) {
            "ringing", "ring" -> android.media.AudioManager.RINGER_MODE_NORMAL
            "vibrate", "vibration" -> android.media.AudioManager.RINGER_MODE_VIBRATE
            "silent" -> android.media.AudioManager.RINGER_MODE_SILENT
            else -> {
                Log.w(TAG, "Unknown profile: $profile, defaulting to NORMAL")
                android.media.AudioManager.RINGER_MODE_NORMAL
            }
        }

        try {
            if (profile.lowercase() in listOf("ringing", "ring", "vibrate", "vibration")) {
                disableDoNotDisturb()
            }

            val currentMode = audioManager!!.ringerMode
            Log.d(TAG, "Current ringer mode: $currentMode, Target mode: $ringerMode")

            if (currentMode != ringerMode) {
                audioManager!!.ringerMode = ringerMode
                val newMode = audioManager!!.ringerMode
                Log.d(TAG, "Successfully changed ringer mode to: $newMode")

                if (newMode == ringerMode) {
                    Log.d(TAG, "Ringer mode change confirmed: $profile")
                    vibrateFeedback()
                } else {
                    Log.w(TAG, "Ringer mode change may have failed. Expected: $ringerMode, Got: $newMode")
                }
            } else {
                Log.d(TAG, "Ringer mode already set to: $profile")
            }
        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException when changing ringer mode: ${e.message}", e)
            sendBroadcast(Intent("com.phonebuddy.PERMISSION_REQUIRED").apply {
                putExtra("required_permission", "MODIFY_AUDIO_SETTINGS")
                putExtra("error", e.message)
            })
        } catch (e: Exception) {
            Log.e(TAG, "Exception when changing ringer mode: ${e.message}", e)
        }
    }

    private fun vibrateFeedback() {
        try {
            val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager =
                    getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                vibratorManager.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }

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
        return AudioNotificationHelper.buildServiceNotification(this)
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
            val prefs = getSharedPreferences("telepathy_prefs", MODE_PRIVATE)
            val pairingCode = prefs.getString("pairing_code", null)
            val deviceId = prefs.getString("device_id", null)
            val isRemote = prefs.getBoolean("is_remote", false)

            if (pairingCode == null || deviceId == null) {
                Log.w(TAG, "Cannot update Firestore: pairing info not available")
                return
            }

            if (isRemote) {
                Log.d(TAG, "Skipping Firestore update: device is remote controller")
                return
            }

            Log.d(TAG, "Updating Firestore profile: $profile for device: $deviceId in room: $pairingCode")

            val updateData = hashMapOf<String, Any>(
                "profile" to profile,
                "updatedAt" to com.google.firebase.Timestamp.now()
            )

            firestore?.collection("rooms")
                ?.document(pairingCode)
                ?.collection("devices")
                ?.document(deviceId)
                ?.set(updateData, SetOptions.merge())
                ?.addOnSuccessListener {
                    Log.d(TAG, "Successfully updated Firestore profile: $profile")
                }
                ?.addOnFailureListener { e ->
                    Log.e(TAG, "Failed to update Firestore profile: ${e.message}", e)
                }
        } catch (e: Exception) {
            Log.e(TAG, "Exception updating Firestore profile: ${e.message}", e)
        }
    }
}
