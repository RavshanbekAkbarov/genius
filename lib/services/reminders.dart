import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../state/app_state.dart';

/// Kunlik eslatmalar: 09:00, 14:00, 20:00 (Toshkent vaqti).
/// Vaqtlar qat'iy: foydalanuvchi o'zgartira olmaydi yoki o'chira olmaydi (ilova ichida).
/// 20:00 eslatmasi faqat o'sha kuni hali mashq qilinmagan bo'lsa keladi.
class Reminders {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static bool? _activeToday;

  static const _days = 14; // oldindan rejalashtiriladigan kunlar
  static const _slots = [
    (9, "Xayrli tong! 📚", "Bugungi yangi so'zlarni yodlash vaqti."),
    (14, 'Takrorlash vaqti 🔁', "So'zlaringizni takrorlab, xotirada mustahkamlang."),
    (20, 'Marrangiz kuyadi! 🔥', "Bugun hali mashq qilmadingiz. Olovni saqlab qoling."),
  ];

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_reminders',
      'Kunlik eslatmalar',
      channelDescription: "09:00, 14:00 va 20:00 dagi o'qish eslatmalari",
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Tashkent'));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _ready = true;
    } catch (e) {
      debugPrint('Eslatmalar ishga tushmadi: $e');
    }
  }

  /// Ilova ochilganda va bugungi birinchi mashqdan keyin chaqiriladi.
  static Future<void> schedule(AppState s) async {
    if (!_ready) return;
    final now = tz.TZDateTime.now(tz.local);
    final activeToday = s.active(DateTime(now.year, now.month, now.day));
    _activeToday = activeToday;
    try {
      await _plugin.cancelAllPendingNotifications();
      for (var d = 0; d < _days; d++) {
        for (var i = 0; i < _slots.length; i++) {
          final (hour, title, body) = _slots[i];
          final at = tz.TZDateTime(tz.local, now.year, now.month, now.day + d, hour);
          if (!at.isAfter(now)) continue;
          if (d == 0 && hour == 20 && activeToday) continue;
          await _plugin.zonedSchedule(
            id: d * 10 + i,
            scheduledDate: at,
            notificationDetails: _details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            title: title,
            body: body,
          );
        }
      }
    } catch (e) {
      debugPrint('Eslatmalarni rejalashtirib bo\'lmadi: $e');
    }
  }

  /// Bugun birinchi marta mashq qilinganda 20:00 eslatmasini olib tashlash uchun.
  static void watch(AppState s) {
    s.addListener(() {
      final n = DateTime.now();
      final a = s.active(DateTime(n.year, n.month, n.day));
      if (a != _activeToday) schedule(s);
    });
  }
}
