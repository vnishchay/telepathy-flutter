package com.phonebuddy

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.TaskStackBuilder

object AudioNotificationHelper {
    const val SERVICE_CHANNEL_ID: String = "audio_control_channel"
    const val SILENT_CHANNEL_ID: String = "silent_channel"
    const val ALERT_CHANNEL_ID: String = "audio_control_alerts"
    const val BACKGROUND_NOTIFICATION_ID: Int = 2001

    private const val SERVICE_CHANNEL_NAME = "Audio Control"
    private const val SILENT_CHANNEL_NAME = "Silent Updates"
    private const val ALERT_CHANNEL_NAME = "Audio Control Alerts"

    fun ensureChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                ?: return

        val serviceChannel = NotificationChannel(
            SERVICE_CHANNEL_ID,
            SERVICE_CHANNEL_NAME,
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Maintains the foreground audio control service"
            setShowBadge(false)
        }

        val silentChannel = NotificationChannel(
            SILENT_CHANNEL_ID,
            SILENT_CHANNEL_NAME,
            NotificationManager.IMPORTANCE_MIN
        ).apply {
            description = "Silent notifications for background audio updates"
            setSound(null, null)
            enableVibration(false)
            enableLights(false)
            setShowBadge(false)
        }

        val alertChannel = NotificationChannel(
            ALERT_CHANNEL_ID,
            ALERT_CHANNEL_NAME,
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = "Alerts when remote audio profile changes are received"
            setShowBadge(false)
        }

        notificationManager.createNotificationChannel(serviceChannel)
        notificationManager.createNotificationChannel(silentChannel)
        notificationManager.createNotificationChannel(alertChannel)
    }

    fun buildServiceNotification(context: Context): Notification {
        ensureChannels(context)
        return NotificationCompat.Builder(context, SERVICE_CHANNEL_ID)
            .setContentTitle("PhoneBuddy Active")
            .setContentText("Monitoring audio control requests")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()
    }

    fun buildBackgroundNotification(
        context: Context,
        title: String,
        body: String,
        data: Map<String, String>
    ): Notification {
        ensureChannels(context)

        val intent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            data.forEach { (key, value) ->
                putExtra(key, value)
            }
        }

        val pendingIntentFlags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0

        val pendingIntent = TaskStackBuilder.create(context).run {
            addNextIntentWithParentStack(intent)
            getPendingIntent(0, pendingIntentFlags)
        }

        return NotificationCompat.Builder(context, ALERT_CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .build()
    }
}
