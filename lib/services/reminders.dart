import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../state/app_state.dart';

/// Kuniga ko'pi bilan 4 ta eslatma (Toshkent vaqti): 08:00, 14:00, 20:00, 21:30.
/// Matnlar har safar ro'yxatdan tasodifiy tanlanadi. Foydalanuvchi vaqtlarni o'zgartira olmaydi.
/// - 14:00: bugungi takrorlar hammasi bajarilgan bo'lsa kelmaydi.
/// - 20:00 va 21:30: bugun bitta mashq yoki takror qilingan bo'lsa kelmaydi.
class Reminders {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static String? _sig;
  static Timer? _debounce;
  static final _rnd = Random();

  static const _days = 14; // oldindan rejalashtiriladigan kunlar

  static const morningDue = [
    "Tong bilan {n} ta takror kutib turibdi ☕ Choy qaynaguncha bittasini tugatasiz!",
    "Uyg'ondingizmi? 🌞 So'zlaringiz sizni sog'inib qoldi: bugun {n} ta takror.",
    "Bugungi reja: {n} ta takror. Miya ham badantarbiya qilsin 💪",
    "Ertalabki 5 daqiqa kun bo'yi esda qoladi. {n} ta takror sizni kutyapti 📚",
  ];
  static const morningFree = [
    "Bugun takror yo'q, demak yangi so'zlar vaqti! 🚀 Bir hayt deb 20 tasini yodlab yuboring.",
    "Bo'sh kun yo'q, yangi unit bor! 😎 Bugun nechta so'z olamiz?",
  ];
  static const noonDone = [
    "Zo'r ketyapsiz! {jami} tadan {done} tasi tayyor, {n} tasi qoldi 🔥",
  ];
  static const noon = [
    "Yarim yo'ldasiz 👀 Qolgan {n} ta takror 5 daqiqalik ish.",
    "Tanaffusmi? Unda bitta takror ham sig'adi ⏱ {n} ta qoldi.",
    "So'zlar esdan chiqmasidan bir ko'rib qo'ying 🧠 {n} ta qoldi.",
  ];
  static const evening = [
    "Iye, shashtingiz pastku? 😏 Bitta takror qiling, olov o'chmasin 🔥",
    "Olovingiz kuyyapti! 🔥 5 daqiqangiz ketadi, xolos.",
    "Bir hayt deb 20 ta so'z yodlab yuboring endi 💨",
  ];
  static const eveningFire = ["{olov} kunlik olov sizdan bitta takror kutyapti 🔥"];
  static const late = [
    "Karnaychidan bitta puff, bor-yo'g'i 20 ta so'z 🎺 Olov o'chmasin endi!",
    "Guruhdoshlaringiz reytingda o'tib ketyapti 👀 Bitta takror bilan joyingizni qaytarib oling!",
    "Uxlashdan oldin 5 daqiqa: olov ham, so'zlar ham saqlanib qoladi 🌙",
  ];
  static const lateFire = ["Oxirgi imkoniyat! {olov} kunlik olovingiz yarim tunda o'chadi 😱"];

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_reminders',
      'Kunlik eslatmalar',
      channelDescription: "08:00, 14:00, 20:00 va 21:30 dagi o'qish eslatmalari",
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

  static String _pick(List<String> list) => list[_rnd.nextInt(list.length)];

  static String _fill(String t, {int n = 0, int jami = 0, int done = 0, int olov = 0}) => t
      .replaceAll('{n}', '$n')
      .replaceAll('{jami}', '$jami')
      .replaceAll('{done}', '$done')
      .replaceAll('{olov}', '$olov');

  /// Bitta kun uchun eslatmalar: (soat, daqiqa, sarlavha, matn). [d] = bugundan necha kun keyin.
  @visibleForTesting
  static List<(int, int, String, String)> plan(AppState s, int d) {
    final day = addDays(s.today, d);
    final out = <(int, int, String, String)>[];
    final isToday = d == 0;
    final left = s.dueUnitsBy(day); // qolgan takrorlar (unit)
    final done = isToday ? s.reviewedToday : 0;
    final jami = left + done;
    final activeToday = isToday && s.active(day);
    final fire = isToday ? s.streak : 0;

    // 08:00
    out.add(left > 0
        ? (8, 0, 'Bugun $left ta takror bor', _fill(_pick(morningDue), n: left))
        : (8, 0, "Yangi so'zlar vaqti", _pick(morningFree)));
    // 14:00: takror qolgan bo'lsa
    if (left > 0) {
      final title = done > 0 ? '$jami tadan $done tasini bajardingiz, $left ta qoldi' : '$left ta takror qoldi';
      out.add((14, 0, title, _fill(_pick(done > 0 ? [...noonDone, ...noon] : noon), n: left, jami: jami, done: done)));
    }
    // 20:00 va 21:30: bugun hali hech narsa qilinmagan bo'lsa
    if (!activeToday) {
      out.add((20, 0, 'Olovingiz kuyyapti! 🔥', _fill(_pick(fire > 0 ? [...evening, ...eveningFire] : evening), olov: fire)));
      out.add((21, 30, 'Oxirgi eslatma 🔥', _fill(_pick(fire > 0 ? [...late, ...lateFire] : late), olov: fire)));
    }
    return out;
  }

  /// Ilova ochilganda va bugungi holat o'zgarganda chaqiriladi.
  static Future<void> schedule(AppState s) async {
    if (!_ready) return;
    _sig = _signature(s);
    final now = tz.TZDateTime.now(tz.local);
    try {
      await _plugin.cancelAllPendingNotifications();
      for (var d = 0; d < _days; d++) {
        for (final (i, (h, m, title, body)) in plan(s, d).indexed) {
          final at = tz.TZDateTime(tz.local, now.year, now.month, now.day + d, h, m);
          if (!at.isAfter(now)) continue;
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
      debugPrint("Eslatmalarni rejalashtirib bo'lmadi: $e");
    }
  }

  static String _signature(AppState s) => '${s.td}|${s.active(s.today)}|${s.dueUnitsBy(s.today)}|${s.reviewedToday}';

  /// Bugungi holat (mashq qilindi, takror bajarildi) o'zgarsa eslatmalarni qayta tuzish.
  static void watch(AppState s) {
    s.addListener(() {
      if (_signature(s) == _sig) return;
      _debounce?.cancel();
      _debounce = Timer(const Duration(seconds: 2), () => schedule(s));
    });
  }
}
