package com.phonebuddy

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class AudioControlBootReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "AudioControlBootReceiver"
        private val SUPPORTED_ACTIONS = setOf(
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_LOCKED_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_USER_PRESENT
        )
    }

    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action
        Log.d(TAG, "Received broadcast: $action")

        if (action != null && SUPPORTED_ACTIONS.contains(action)) {
            Log.d(TAG, "Starting AudioControlService from broadcast: $action")
            AudioControlService.start(context.applicationContext)
        } else {
            Log.d(TAG, "Ignored broadcast: $action")
        }
    }
}
