import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../data/catalog.dart';
import '../data/quotes.dart';
import '../data/words.dart';
import '../state/app_state.dart';
import 'word_widget.dart';

/// Server (Supabase): hisob, Premium, markaz kitoblari, progress nusxasi.
/// Server sozlanmagan yoki internet yo'q bo'lsa hamma chaqiruv jim o'tadi, ilova telefonda ishlayveradi.
class Cloud {
  static bool _ready = false;
  static AppState? _s;
  static Timer? _push;

  /// Kirish yoki chiqish bo'lganda ekranlar yangilanishi uchun.
  static final signedInNotifier = ValueNotifier<bool>(false);

  static bool get enabled => cloudEnabled && _ready;
  static SupabaseClient get _db => Supabase.instance.client;
  static User? get user => enabled ? _db.auth.currentUser : null;
  static bool get signedIn => user != null;

  static Future<void> init(AppState s) async {
    _s = s;
    if (!cloudEnabled) return;
    try {
      await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
      _ready = true;
    } catch (e) {
      debugPrint('Server ulanmadi: $e');
      return;
    }
    signedInNotifier.value = signedIn;
    _db.auth.onAuthStateChange.listen((e) {
      final was = signedInNotifier.value;
      signedInNotifier.value = e.session != null;
      if (e.event == AuthChangeEvent.signedIn && !was) {
        s.loginSeen = true;
        s.refresh();
        unawaited(sync());
      }
    });
    s.addListener(_schedulePush);
    unawaited(sync());
    unawaited(resumeTelegram());
  }

  // ---------- kirish ----------
  /// Telegram orqali kirish: bot ochiladi, foydalanuvchi "Ha, kiraman" ni bosadi,
  /// ilova esa server orqali kirish kalitini oladi. [cancelled] true bo'lsa to'xtaydi.
  /// Kod telefonda saqlanadi: Android ilovani yopib qo'ysa ham, qayta ochilganda kirish yakunlanadi.
  static Future<String?> signInTelegram(ValueListenable<bool> cancelled) async {
    if (!enabled) return "Server hali ulanmagan";
    final code = _randomCode(24);
    final p = await SharedPreferences.getInstance();
    await p.setString(_tgKey, '$code|${DateTime.now().millisecondsSinceEpoch}');
    final ok = await launchUrl(Uri.parse('https://t.me/$botUsername?start=login_$code'),
        mode: LaunchMode.externalApplication);
    if (!ok) return "Telegram ochilmadi";
    return _pollTelegram(code, const Duration(minutes: 5), cancelled);
  }

  static const _tgKey = 'tg_login_pending';
  static Completer<void>? _wake;

  /// Ilovaga qaytilganda kutmasdan darhol tekshirish uchun.
  static void pokeTelegram() {
    final w = _wake;
    if (w != null && !w.isCompleted) w.complete();
  }

  /// Ilova qayta ochilganda: yarim qolgan Telegram kirishini yakunlash.
  static Future<void> resumeTelegram() async {
    if (!enabled || signedIn) return;
    final p = await SharedPreferences.getInstance();
    final v = p.getString(_tgKey)?.split('|');
    if (v == null || v.length != 2) return;
    final age = DateTime.now().millisecondsSinceEpoch - (int.tryParse(v[1]) ?? 0);
    if (age > const Duration(minutes: 10).inMilliseconds) {
      await p.remove(_tgKey);
      return;
    }
    await _pollTelegram(v[0], const Duration(minutes: 1), ValueNotifier(false));
  }

  static Future<String?> _pollTelegram(String code, Duration limit, ValueListenable<bool> cancelled) async {
    final end = DateTime.now().add(limit);
    var fails = 0;
    String? lastErr;
    var first = true;
    while (DateTime.now().isBefore(end) && !cancelled.value) {
      if (!first) {
        _wake = Completer<void>();
        await Future.any([_wake!.future, Future<void>.delayed(const Duration(seconds: 2))]);
        if (cancelled.value) break;
      }
      first = false;
      try {
        final r = await _db.functions.invoke('tg-login', body: {'code': code});
        final data = r.data as Map<String, dynamic>?;
        final status = data?['status'];
        fails = 0;
        if (status == 'ok') {
          await _db.auth.verifyOTP(type: OtpType.magiclink, tokenHash: data!['token_hash'] as String);
          await _clearTelegram();
          final s = _s!;
          s.account = 'telegram';
          s.accountLabel = data['username'] == null ? 'Telegram' : '@${data['username']}';
          s.loginSeen = true;
          s.refresh();
          return null;
        }
        if (status == 'expired') {
          await _clearTelegram();
          return "Vaqt tugadi, qaytadan urinib ko'ring";
        }
      } on FunctionException catch (e) {
        // Server xato qaytardi: bir necha marta takrorlansa foydalanuvchiga ko'rsatamiz.
        final d = e.details;
        lastErr = d is Map && d['error'] != null ? '${d['error']}' : 'kod ${e.status}';
        if (++fails >= 3) return "Server xatosi: $lastErr";
      } on AuthException catch (e) {
        return "Kirib bo'lmadi: ${e.message}";
      } catch (e) {
        // Internet uzilib qolgan bo'lishi mumkin: yana urinamiz.
        lastErr = '$e';
        fails++;
      }
    }
    if (cancelled.value) return '';
    return lastErr == null ? "Vaqt tugadi, qaytadan urinib ko'ring" : "Kirib bo'lmadi: $lastErr";
  }

  static Future<void> _clearTelegram() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_tgKey);
  }

  static Future<void> signOut() async {
    final s = _s;
    if (enabled) {
      await _pushNow();
      try {
        await _db.auth.signOut();
      } catch (_) {}
    }
    if (s != null) {
      s.account = null;
      s.accountLabel = null;
      s.premiumUntil = null;
      s.owned = {};
      s.refresh();
    }
  }

  static String _randomCode(int n) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random.secure();
    return List.generate(n, (_) => chars[r.nextInt(chars.length)]).join();
  }

  // ---------- ma'lumotlarni olish ----------
  /// Profil, Premium, sotib olingan kitoblar, markaz kitoblari va progress nusxasi.
  static Future<void> sync() async {
    final s = _s;
    if (!enabled || s == null) return;
    final u = user;
    unawaited(_syncDaily(s));
    if (u == null) {
      await _syncBooks(s);
      return;
    }
    try {
      final p = await _db.from('profiles').select().eq('id', u.id).maybeSingle();
      if (p != null) {
        s.nickname = (p['nickname'] ?? s.nickname) as String;
        s.avatar = (p['avatar'] ?? s.avatar) as String;
        s.premiumUntil = p['premium_until'] as String?;
        if (p['tg_username'] != null && s.account == 'telegram') s.accountLabel = '@${p['tg_username']}';
      }
      final bought = await _db.from('purchases').select('book_id');
      s.owned = {for (final r in bought) r['book_id'] as String};
      final st = await _db.from('user_state').select('data').eq('user_id', u.id).maybeSingle();
      final data = st?['data'] as Map<String, dynamic>?;
      if (data != null && (s.isFresh || ((data['updatedAt'] ?? 0) as int) > s.updatedAt)) {
        s.restoreProgress(data);
      } else {
        s.refresh();
        _schedulePush();
      }
      await _syncBooks(s);
    } catch (e) {
      debugPrint('Sinxronlash xatosi: $e');
    }
  }

  /// Admin paneldagi iqtiboslar va kunning so'zlari (kechadan 60 kun oldinga).
  static Future<void> _syncDaily(AppState s) async {
    try {
      final qs = await _db.from('quotes').select('en, uz, author').eq('active', true).order('sort').order('id');
      final from = ds(addDays(s.today, -1));
      final to = ds(addDays(s.today, 60));
      final ws = await _db.from('daily_words').select('day, en, uz, ipa, ex').gte('day', from).lte('day', to);
      s.setDaily([for (final q in qs) Quote.fromJson(q)], {for (final w in ws) w['day'] as String: Word.fromJson(w)});
      WordWidget.update(s);
    } catch (e) {
      debugPrint('Kunlik ma\'lumotni olib bo\'lmadi: $e');
    }
  }

  static Future<void> _syncBooks(AppState s) async {
    try {
      final rows = await _db.from('books').select().order('sort');
      final list = [for (final r in rows) Book.fromJson(r)];
      final words = <String, List<Word>>{};
      for (final b in list) {
        // Sotib olinmagan pullik kitobdan faqat bepul namuna (1-unit) keladi.
        var q = _db.from('words').select('unit, idx, en, uz, ipa, ex').eq('book_id', b.id);
        if (s.locked(b)) q = q.eq('unit', 1);
        final ws = await q.order('unit').order('idx');
        for (final w in ws) {
          words.putIfAbsent('${b.id}|${w['unit']}', () => []).add(Word.fromJson(w));
        }
      }
      s.setRemote(list, words);
    } catch (e) {
      debugPrint('Kitoblarni olib bo\'lmadi: $e');
    }
  }

  // ---------- yuborish ----------
  static void _schedulePush() {
    if (!signedIn) return;
    _push?.cancel();
    _push = Timer(const Duration(seconds: 12), _pushNow);
  }

  static Future<void> _pushNow() async {
    _push?.cancel();
    final s = _s;
    final u = user;
    if (s == null || u == null) return;
    try {
      await _db.from('user_state').upsert({'user_id': u.id, 'data': s.progressJson(), 'updated_at': DateTime.now().toUtc().toIso8601String()});
      for (final d in [addDays(s.today, -1), s.today]) {
        final k = ds(d);
        final score = s.log[k] ?? 0;
        if (score == 0) continue;
        final dl = s.days[k];
        await _db.rpc('submit_day', params: {
          'p_day': k,
          'p_score': score,
          'p_new_words': dl?.newWords ?? 0,
          'p_reviews': dl?.reviewWords ?? 0,
          'p_sessions': dl?.sessions ?? 0,
        });
      }
    } catch (e) {
      debugPrint('Serverga yuborib bo\'lmadi: $e');
    }
  }

  static Future<String?> saveProfile({required String nickname, required String avatar}) async {
    final u = user;
    if (u == null) return null;
    try {
      await _db.from('profiles').update({'nickname': nickname, 'avatar': avatar}).eq('id', u.id);
      return null;
    } catch (e) {
      return "Serverga saqlanmadi: taxallus 2–20 harf bo'lsin";
    }
  }

  // ---------- to'lov ----------
  /// To'lov boshlash: server kod beradi va Telegram bot shu kod bilan ochiladi.
  /// [kind]: `premium` yoki `book:<id>`.
  static Future<String?> startPayment(String kind) async {
    if (!enabled) return "Server hali ulanmagan";
    if (!signedIn) return 'login';
    try {
      final code = await _db.rpc('create_pay_code', params: {'p_kind': kind}) as String;
      final ok = await launchUrl(Uri.parse('https://t.me/$botUsername?start=pay_$code'),
          mode: LaunchMode.externalApplication);
      return ok ? null : "Telegram ochilmadi";
    } catch (e) {
      return "To'lovni boshlab bo'lmadi, internetni tekshiring";
    }
  }
}
