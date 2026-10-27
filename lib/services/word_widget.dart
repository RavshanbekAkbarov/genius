import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/catalog.dart';
import '../data/words.dart';
import '../state/app_state.dart';

/// Kunning so'zi: har kuni tanlangan kitobdan bitta so'z (hamma uchun bir xil tartibda).
Word wordOfDay(AppState s, [DateTime? day]) {
  final d = day ?? s.today;
  final b = bookById(s.currentBook);
  final all = <Word>[];
  for (var u = 1; u <= s.unitsOf(b); u++) {
    all.addAll(s.words(b.id, u));
  }
  if (all.isEmpty) {
    for (var u = 1; u <= 30; u++) {
      all.addAll(WordBank.unit('e1', u));
    }
  }
  if (all.isEmpty) return const Word('genius', 'daho, juda aqlli odam', '/ˈdʒiːniəs/');
  final n = d.difference(DateTime(2026)).inDays;
  return all[(n * 37).abs() % all.length];
}

/// Bosh ekrandagi vidjet: 7 kunlik so'zlar telefonga yoziladi, Android vidjeti kunini o'zi tanlaydi.
class WordWidget {
  static const _channel = MethodChannel('genius/widget');

  static Future<void> update(AppState s) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final days = <String, dynamic>{};
      for (var i = 0; i < 7; i++) {
        final d = addDays(s.today, i);
        final w = wordOfDay(s, d);
        days[ds(d)] = {'en': w.en, 'uz': w.uz, 'ipa': w.ipa};
      }
      final p = await SharedPreferences.getInstance();
      await p.setString('word-widget', jsonEncode(days));
      await _channel.invokeMethod('update');
    } catch (e) {
      debugPrint('Vidjet yangilanmadi: $e');
    }
  }
}
