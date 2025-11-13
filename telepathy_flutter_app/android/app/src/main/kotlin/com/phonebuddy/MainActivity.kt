package com.phonebuddy

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.provider.Settings
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
}

