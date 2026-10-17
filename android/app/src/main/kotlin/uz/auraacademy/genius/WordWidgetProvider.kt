package uz.auraacademy.genius

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/// Bosh ekrandagi "Kunning so'zi" vidjeti. So'zlar ilova tomonidan bir necha kun oldinga
/// saqlab qo'yiladi, shuning uchun ilova ochilmasa ham har kuni yangi so'z chiqadi.
class WordWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        var en = "Genius"
        var uz = "Ilovani oching"
        var ipa = ""
        try {
            val all = JSONObject(prefs.getString("flutter.word-widget", "{}") ?: "{}")
            val keys = all.keys().asSequence().sorted().toList()
            // Bugungi so'z bo'lmasa, bugungacha bo'lgan eng oxirgisi.
            val key = keys.lastOrNull { it <= today } ?: keys.firstOrNull()
            if (key != null) {
                val w = all.getJSONObject(key)
                en = w.optString("en", en)
                uz = w.optString("uz", uz)
                ipa = w.optString("ipa", "")
            }
        } catch (_: Exception) {
        }
        val open = PendingIntent.getActivity(
            context, 0, Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        for (id in ids) {
            val views = RemoteViews(context.packageName, R.layout.word_widget)
            views.setTextViewText(R.id.wod_en, en)
            views.setTextViewText(R.id.wod_uz, uz)
            views.setTextViewText(R.id.wod_ipa, ipa)
            views.setViewVisibility(R.id.wod_ipa, if (ipa.isEmpty()) View.GONE else View.VISIBLE)
            views.setOnClickPendingIntent(R.id.wod_root, open)
            manager.updateAppWidget(id, views)
        }
    }
}
