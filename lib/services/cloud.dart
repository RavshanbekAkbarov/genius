import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../data/catalog.dart';
import '../data/words.dart';
import '../state/app_state.dart';

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
        final provider = e.session?.user.appMetadata['provider'] as String?;
        if (provider == 'google') {
          s.account = 'google';
          s.accountLabel = e.session?.user.email;
        }
        s.loginSeen = true;
        s.refresh();
        unawaited(sync());
      }
    });
    s.addListener(_schedulePush);
    unawaited(sync());
  }

  // ---------- kirish ----------
  static Future<String?> signInGoogle() async {
    if (!enabled) return "Server hali ulanmagan";
    try {
      final ok = await _db.auth.signInWithOAuth(OAuthProvider.google,
          redirectTo: authRedirect, authScreenLaunchMode: LaunchMode.externalApplication);
      return ok ? null : "Brauzer ochilmadi";
    } catch (e) {
      return "Kirib bo'lmadi: $e";
    }
  }

  /// Telegram orqali kirish: bot ochiladi, foydalanuvchi "Ha, kiraman" ni bosadi,
  /// ilova esa server orqali kirish kalitini oladi. [cancelled] true bo'lsa to'xtaydi.
  static Future<String?> signInTelegram(ValueListenable<bool> cancelled) async {
    if (!enabled) return "Server hali ulanmagan";
    final code = _randomCode(24);
    final ok = await launchUrl(Uri.parse('https://t.me/$botUsername?start=login_$code'),
        mode: LaunchMode.externalApplication);
    if (!ok) return "Telegram ochilmadi";
    final end = DateTime.now().add(const Duration(minutes: 5));
    while (DateTime.now().isBefore(end) && !cancelled.value) {
      await Future<void>.delayed(const Duration(seconds: 2));
      try {
        final r = await _db.functions.invoke('tg-login', body: {'code': code});
        final data = r.data as Map<String, dynamic>?;
        final status = data?['status'];
        if (status == 'ok') {
          await _db.auth.verifyOTP(type: OtpType.magiclink, tokenHash: data!['token_hash'] as String);
          final s = _s!;
          s.account = 'telegram';
          s.accountLabel = data['username'] == null ? 'Telegram' : '@${data['username']}';
          s.loginSeen = true;
          s.refresh();
          return null;
        }
        if (status == 'expired') return "Vaqt tugadi, qaytadan urinib ko'ring";
      } catch (_) {
        // Internet uzilib qolgan bo'lishi mumkin: yana urinamiz.
      }
    }
    return cancelled.value ? '' : "Vaqt tugadi, qaytadan urinib ko'ring";
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

  static Future<void> _syncBooks(AppState s) async {
    try {
      final rows = await _db.from('books').select().order('sort');
      final list = [for (final r in rows) Book.fromJson(r)];
      final words = <String, List<Word>>{};
      for (final b in list) {
        if (b.paid && !s.owned.contains(b.id)) continue;
        final ws = await _db.from('words').select('unit, idx, en, uz, ipa, ex').eq('book_id', b.id).order('unit').order('idx');
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
