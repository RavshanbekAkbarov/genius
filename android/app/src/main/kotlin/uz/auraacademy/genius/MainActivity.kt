package uz.auraacademy.genius

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
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
    }
}
