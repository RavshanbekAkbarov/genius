package uz.auraacademy.genius

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.PowerManager

/// Tinglash: ekran o'chganda yoki ilovadan chiqilganda ham so'zlar o'qilishi uchun
/// ilova jarayonini tirik saqlaydigan servis (bildirishnoma + protsessorni uxlatmaslik).
/// So'zlarni o'qishning o'zi Flutter tomonida qoladi.
class ListenService : Service() {
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            onStopPressed?.invoke()
            stopSelf()
            return START_NOT_STICKY
        }
        val text = intent?.getStringExtra(EXTRA_TEXT) ?: "So'zlar o'qilmoqda"
        val n = build(text)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(NOTIFICATION_ID, n)
        }
        if (wakeLock == null) {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "genius:listen").apply {
                setReferenceCounted(false)
                acquire(3 * 60 * 60 * 1000L) // ko'pi bilan 3 soat
            }
        }
        instance = this
        return START_NOT_STICKY
    }

    /// Bildirishnomadagi so'zni yangilash (servisni qayta ishga tushirmasdan).
    fun update(text: String) {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIFICATION_ID, build(text))
    }

    /// Ilova "So'nggi ilovalar"dan surib yopilsa, o'qish ham to'xtaydi.
    override fun onTaskRemoved(rootIntent: Intent?) {
        stopSelf()
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        if (instance === this) instance = null
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
        super.onDestroy()
    }

    private fun build(text: String): Notification {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && nm.getNotificationChannel(CHANNEL) == null) {
            nm.createNotificationChannel(
                NotificationChannel(CHANNEL, "Tinglash", NotificationManager.IMPORTANCE_LOW).apply {
                    description = "So'zlar o'qilayotganda ko'rinadi"
                    setShowBadge(false)
                }
            )
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        val open = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP), flags
        )
        val stop = PendingIntent.getService(
            this, 1, Intent(this, ListenService::class.java).setAction(ACTION_STOP), flags
        )
        val b = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        return b.setSmallIcon(android.R.drawable.ic_media_play)
            .setContentTitle("Genius · Tinglash")
            .setContentText(text)
            .setContentIntent(open)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .addAction(Notification.Action.Builder(null, "To'xtatish", stop).build())
            .build()
    }

    companion object {
        const val CHANNEL = "genius_listen"
        const val NOTIFICATION_ID = 7301
        const val ACTION_STOP = "uz.auraacademy.genius.LISTEN_STOP"
        const val EXTRA_TEXT = "text"

        /// Bildirishnomadagi "To'xtatish" bosilganda Flutter'ga xabar berish uchun.
        var onStopPressed: (() -> Unit)? = null

        /// Ishlab turgan servis (bo'lmasa null).
        var instance: ListenService? = null
    }
}
