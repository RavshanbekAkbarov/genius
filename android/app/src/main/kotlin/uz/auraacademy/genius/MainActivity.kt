package uz.auraacademy.genius

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Flutter "Kunning so'zi"ni saqlagach, bosh ekrandagi vidjetni yangilash uchun chaqiradi.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "genius/widget").setMethodCallHandler { call, result ->
            if (call.method == "update") {
                val manager = AppWidgetManager.getInstance(this)
                val ids = manager.getAppWidgetIds(ComponentName(this, WordWidgetProvider::class.java))
                val intent = Intent(this, WordWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                }
                sendBroadcast(intent)
                result.success(ids.size)
            } else {
                result.notImplemented()
            }
        }
        // Tinglash: ekran o'chganda ham o'qishda davom etish uchun servisni yoqish/o'chirish.
        val listen = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "genius/listen")
        ListenService.onStopPressed = { runOnUiThread { listen.invokeMethod("stop", null) } }
        listen.setMethodCallHandler { call, result ->
            when (call.method) {
                "update" -> {
                    // Servis allaqachon ishlayapti: faqat bildirishnomadagi so'zni almashtiramiz.
                    ListenService.instance?.update(call.argument<String>("text") ?: "")
                    result.success(ListenService.instance != null)
                }
                "start" -> {
                    val intent = Intent(this, ListenService::class.java)
                        .putExtra(ListenService.EXTRA_TEXT, call.argument<String>("text"))
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(intent) else startService(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        // Masalan, Android ilova orqa fonda turganda yangi servis ochishga ruxsat bermasa.
                        result.success(false)
                    }
                }
                "stop" -> {
                    stopService(Intent(this, ListenService::class.java))
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
