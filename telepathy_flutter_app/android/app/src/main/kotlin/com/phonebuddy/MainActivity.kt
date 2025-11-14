package com.phonebuddy

import android.Manifest
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioManager
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

private const val CHANNEL_AUDIO = "telepathy/audio"
private const val MODE_SILENT = 0
private const val MODE_VIBRATE = 1
private const val MODE_RING = 2

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_AUDIO)
            .setMethodCallHandler(::handleAudioMethodCall)
    }

    private fun handleAudioMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasPolicyAccess" -> result.success(hasPolicyAccess())
            "requestPolicyAccess" -> result.success(requestPolicyAccess())
            "requestNotificationPermission" -> result.success(requestNotificationPermission())
            "disableDoNotDisturb" -> result.success(disableDoNotDisturb())
            "getDoNotDisturbStatus" -> result.success(getDoNotDisturbStatus())
            "openPolicySettings" -> {
                openPolicySettings()
                result.success(null)
            }
            "setRingerMode" -> {
                val mode = call.argument<Int>("mode")
                if (mode == null) {
                    result.error("invalid_args", "mode is required", null)
                    return
                }
                val success = setRingerMode(mode)
                if (success) {
                    result.success(true)
                } else {
                    result.error(
                        "set_failed",
                        "Permission missing or audio manager unavailable",
                        null
                    )
                }
            }
            "getRingerMode" -> result.success(getRingerMode())
            "vibrate" -> {
                val duration = call.argument<Int>("duration") ?: 100
                vibrate(duration)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun hasPolicyAccess(): Boolean {
        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return false
        return notificationManager.isNotificationPolicyAccessGranted
    }

    private fun requestPolicyAccess(): Boolean {
        if (hasPolicyAccess()) {
            return true
        }
        openPolicySettings()
        // We cannot know the result immediately; caller should poll hasPolicyAccess after user action.
        return false
    }

    private fun requestNotificationPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            // No notification permission needed for Android < 13
            return true
        }

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) {
            return true
        }

        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            1001 // Request code
        )

        // We cannot know the result immediately; caller should check again after user action.
        return false
    }

    private fun disableDoNotDisturb(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && hasPolicyAccess()) {
                val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                val currentFilter = notificationManager.currentInterruptionFilter

                if (currentFilter != NotificationManager.INTERRUPTION_FILTER_ALL) {
                    notificationManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
                    true
                } else {
                    true // Already disabled
                }
            } else {
                false // Cannot control DND
            }
        } catch (e: Exception) {
            false
        }
    }

    private fun getDoNotDisturbStatus(): String {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && hasPolicyAccess()) {
                val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                val currentFilter = notificationManager.currentInterruptionFilter

                when (currentFilter) {
                    NotificationManager.INTERRUPTION_FILTER_ALL -> "disabled"
                    NotificationManager.INTERRUPTION_FILTER_NONE -> "alarms_only"
                    NotificationManager.INTERRUPTION_FILTER_PRIORITY -> "priority_only"
                    NotificationManager.INTERRUPTION_FILTER_UNKNOWN -> "unknown"
                    else -> "enabled"
                }
            } else {
                "unsupported"
            }
        } catch (e: Exception) {
            "error"
        }
    }

    private fun openPolicySettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun setRingerMode(mode: Int): Boolean {
        if (!hasPolicyAccess()) return false
        val audioManager =
            getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return false
        val mapped = when (mode) {
            MODE_SILENT -> AudioManager.RINGER_MODE_SILENT
            MODE_VIBRATE -> AudioManager.RINGER_MODE_VIBRATE
            else -> AudioManager.RINGER_MODE_NORMAL
        }
        audioManager.ringerMode = mapped
        return true
    }

    private fun getRingerMode(): Int {
        val audioManager =
            getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return MODE_RING
        return when (audioManager.ringerMode) {
            AudioManager.RINGER_MODE_SILENT -> MODE_SILENT
            AudioManager.RINGER_MODE_VIBRATE -> MODE_VIBRATE
            else -> MODE_RING
        }
    }

    private fun vibrate(durationMillis: Int) {
        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            vibratorManager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(
                VibrationEffect.createOneShot(
                    durationMillis.toLong(),
                    VibrationEffect.DEFAULT_AMPLITUDE
                )
            )
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(durationMillis.toLong())
        }
    }
}

