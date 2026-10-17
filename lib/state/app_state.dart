import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/catalog.dart';
import '../data/words.dart';

/// Bitta so'zning yodlash holati.
class Prog {
  bool learned;
  int stage; // intervals ichidagi bosqich; intervals.length = mustahkam
  String due; // yyyy-mm-dd
  int fails;
  Prog({this.learned = false, this.stage = 0, required this.due, this.fails = 0});

  factory Prog.fromJson(Map<String, dynamic> j) => Prog(
      learned: j['learned'] == true,
      stage: (j['stage'] ?? 0) as int,
      due: (j['due'] ?? '') as String,
      fails: (j['fails'] ?? 0) as int);
  Map<String, dynamic> toJson() => {'learned': learned, 'stage': stage, 'due': due, 'fails': fails};
}

/// Bir kunda nima qilingani: kalendar va kun tafsiloti uchun.
class DayLog {
  int newWords;
  Set<String> newUnits; // "kitob|unit": shu kuni yangi so'z yodlangan unitlar
  int reviewWords;
  Set<String> reviewUnits; // shu kunga belgilangan va bajarilgan takrorlar (kechikib bajarilsa ham)
  Map<String, String> lateUnits; // shu kunning takrori kechikib bajarilgan bo'lsa: unit -> bajarilgan sana
  Set<String> reviewedUnits; // shu kuni haqiqatda takrorlangan unitlar
  int sessions;
  int right;
  int wrong;
  DayLog(
      {this.newWords = 0,
      Set<String>? newUnits,
      this.reviewWords = 0,
      Set<String>? reviewUnits,
      Map<String, String>? lateUnits,
      Set<String>? reviewedUnits,
      this.sessions = 0,
      this.right = 0,
      this.wrong = 0})
      : newUnits = newUnits ?? {},
        reviewUnits = reviewUnits ?? {},
        lateUnits = lateUnits ?? {},
        reviewedUnits = reviewedUnits ?? {};

  bool get empty => newWords == 0 && reviewWords == 0 && sessions == 0 && reviewUnits.isEmpty;
  int? get accuracy => right + wrong == 0 ? null : (right / (right + wrong) * 100).round();

  factory DayLog.fromJson(Map<String, dynamic> j) => DayLog(
        newWords: (j['nw'] ?? 0) as int,
        newUnits: ((j['nu'] ?? []) as List).cast<String>().toSet(),
        reviewWords: (j['rw'] ?? 0) as int,
        reviewUnits: ((j['ru'] ?? []) as List).cast<String>().toSet(),
        lateUnits: ((j['lu'] ?? {}) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as String)),
        reviewedUnits: ((j['rd'] ?? []) as List).cast<String>().toSet(),
        sessions: (j['s'] ?? 0) as int,
        right: (j['ok'] ?? 0) as int,
        wrong: (j['no'] ?? 0) as int,
      );
  Map<String, dynamic> toJson() => {
        'nw': newWords,
        'nu': newUnits.toList(),
        'rw': reviewWords,
        'ru': reviewUnits.toList(),
        'lu': lateUnits,
        'rd': reviewedUnits.toList(),
        's': sessions,
        'ok': right,
        'no': wrong,
      };
}

/// Bugungi takrorlar ro'yxatidagi bitta unit.
class DueGroup {
  final String book;
  final int unit;
  final List<String> keys;
  final int stage;
  final bool late;
  DueGroup(this.book, this.unit, this.keys, this.stage, this.late);
}

/// Mashqdagi bitta karta.
class CardItem {
  final String key; // "kitob|unit|indeks"
  final String book;
  final int unit;
  final Word word;
  const CardItem(this.key, this.book, this.unit, this.word);
}

/// Ketma-ket faol kunlar seriyasi (profildagi "Eng uzun seriyalar").
class StreakRun {
  final DateTime start, end;
  StreakRun(this.start, this.end);
  int get length => end.difference(start).inDays + 1;
}

String ds(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);
String wkey(String b, int u, int i) => '$b|$u|$i';
String ukey(String b, int u) => '$b|$u';

/// Ilovaning butun holati. Hammasi telefonda (SharedPreferences) saqlanadi,
/// hisobga kirilgan bo'lsa serverga ham nusxasi yuboriladi.
class AppState extends ChangeNotifier {
  static const _key = 'genius-v1';
  SharedPreferences? _prefs;

  Map<String, Prog> prog = {};
  Map<String, int> log = {};
  Map<String, DayLog> days = {};
  Set<String> saved = {};
  int bonusXp = 0;
  int dayOffset = 0; // faqat sinov uchun: kunni oldinga surish
  String? premiumUntil;
  String dailyDay = '';
  int dailyCount = 0;
  String offlineDay = '';
  int offlineCount = 0;
  Set<String> owned = {}; // sotib olingan markaz kitoblari (id)
  String currentBook = 'e1';
  String askedSave = '';
  String evening = '';
  String nickname = '';
  String avatar = '🦁';
  int dailyGoal = defaultDailyGoal;
  List<Word> myWords = [];

  // Sozlamalar
  bool reverse = false; // Teskari (uz → en): hamma unitda saqlanadi
  double fontScale = 1.0;
  String? voiceName;
  String? voiceLocale;
  int listenRepeat = 1;
  double listenSpeed = 1.0;
  bool listenShuffle = false;
  bool listenUzFirst = false;

  // Hisob
  bool loginSeen = false; // birinchi ochilishdagi kirish oynasi ko'rsatildimi
  String? account; // 'google' | 'telegram' | null
  String? accountLabel;
  String? groupId;
  String? groupName;
  int updatedAt = 0; // oxirgi o'zgarish vaqti (ms), server nusxasi bilan solishtirish uchun

  // ---------- saqlash ----------
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw != null) {
      try {
        fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    _loadRemote();
  }

  void save() {
    _prefs?.setString(_key, jsonEncode(toJson()));
  }

  void changed() {
    updatedAt = DateTime.now().millisecondsSinceEpoch;
    save();
    notifyListeners();
  }

  /// Faqat ekranni yangilash (serverdan kelgan ma'lumot uchun).
  void refresh() {
    save();
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
        'prog': prog.map((k, v) => MapEntry(k, v.toJson())),
        'log': log,
        'days': days.map((k, v) => MapEntry(k, v.toJson())),
        'saved': saved.toList(),
        'xp': bonusXp,
        'offset': dayOffset,
        'premiumUntil': premiumUntil,
        'daily': {'d': dailyDay, 'n': dailyCount},
        'offline': {'d': offlineDay, 'n': offlineCount},
        'owned': owned.toList(),
        'book': currentBook,
        'askedSave': askedSave,
        'evening': evening,
        'nick': nickname,
        'avatar': avatar,
        'goal': dailyGoal,
        'my': myWords.map((w) => w.toJson()).toList(),
        'reverse': reverse,
        'font': fontScale,
        'voice': voiceName == null ? null : {'name': voiceName, 'locale': voiceLocale},
        'listen': {'r': listenRepeat, 's': listenSpeed, 'mix': listenShuffle, 'uz': listenUzFirst},
        'loginSeen': loginSeen,
        'account': account,
        'accountLabel': accountLabel,
        'group': groupId == null ? null : {'id': groupId, 'name': groupName},
        'updatedAt': updatedAt,
      };

  void fromJson(Map<String, dynamic> j) {
    prog = ((j['prog'] ?? {}) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, Prog.fromJson(v as Map<String, dynamic>)));
    log = ((j['log'] ?? {}) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int));
    days = ((j['days'] ?? {}) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, DayLog.fromJson(v as Map<String, dynamic>)));
    saved = ((j['saved'] ?? []) as List).cast<String>().toSet();
    bonusXp = (j['xp'] ?? 0) as int;
    dayOffset = (j['offset'] ?? 0) as int;
    premiumUntil = j['premiumUntil'] as String?;
    final daily = (j['daily'] ?? {}) as Map<String, dynamic>;
    dailyDay = (daily['d'] ?? '') as String;
    dailyCount = (daily['n'] ?? 0) as int;
    final off = (j['offline'] ?? {}) as Map<String, dynamic>;
    offlineDay = (off['d'] ?? '') as String;
    offlineCount = (off['n'] ?? 0) as int;
    owned = ((j['owned'] ?? []) as List).cast<String>().where((x) => !x.contains(':')).toSet();
    currentBook = (j['book'] ?? 'e1') as String;
    askedSave = (j['askedSave'] ?? '') as String;
    evening = (j['evening'] ?? '') as String;
    nickname = (j['nick'] ?? '') as String;
    avatar = (j['avatar'] ?? '🦁') as String;
    dailyGoal = (j['goal'] ?? defaultDailyGoal) as int;
    myWords = ((j['my'] ?? []) as List).map((e) => Word.fromJson(e as Map<String, dynamic>)).toList();
    reverse = j['reverse'] == true;
    fontScale = ((j['font'] ?? 1.0) as num).toDouble();
    final v = j['voice'] as Map<String, dynamic>?;
    voiceName = v?['name'] as String?;
    voiceLocale = v?['locale'] as String?;
    final l = (j['listen'] ?? {}) as Map<String, dynamic>;
    listenRepeat = (l['r'] ?? 1) as int;
    listenSpeed = ((l['s'] ?? 1.0) as num).toDouble();
    listenShuffle = l['mix'] == true;
    listenUzFirst = l['uz'] == true;
    loginSeen = j['loginSeen'] == true;
    account = j['account'] as String?;
    accountLabel = j['accountLabel'] as String?;
    final g = j['group'] as Map<String, dynamic>?;
    groupId = g?['id'] as String?;
    groupName = g?['name'] as String?;
    updatedAt = (j['updatedAt'] ?? 0) as int;
  }

  /// Serverga yuboriladigan nusxa: o'quv holati (hisob va qurilma sozlamalarisiz).
  Map<String, dynamic> progressJson() {
    final j = toJson();
    for (final k in ['offset', 'premiumUntil', 'loginSeen', 'account', 'accountLabel', 'group', 'voice', 'owned']) {
      j.remove(k);
    }
    return j;
  }

  /// Boshqa telefondan kirilganda serverdagi nusxani tiklash.
  void restoreProgress(Map<String, dynamic> j) {
    final keep = {
      'offset': dayOffset,
      'premiumUntil': premiumUntil,
      'loginSeen': loginSeen,
      'account': account,
      'accountLabel': accountLabel,
      'group': groupId == null ? null : {'id': groupId, 'name': groupName},
      'voice': voiceName == null ? null : {'name': voiceName, 'locale': voiceLocale},
      'owned': owned.toList(),
    };
    fromJson({...j, ...keep});
    refresh();
  }

  /// Telefonda hali hech narsa qilinmaganmi (yangi o'rnatilgan).
  bool get isFresh => prog.isEmpty && log.isEmpty && myWords.isEmpty;

  // ---------- serverdan kelgan markaz kitoblari ----------
  static const _remoteKey = 'genius-remote';

  void _loadRemote() {
    final raw = _prefs?.getString(_remoteKey);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      remoteBooks = ((j['books'] ?? []) as List).map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
      WordBank.remote = ((j['words'] ?? {}) as Map<String, dynamic>).map((k, v) =>
          MapEntry(k, (v as List).map((e) => Word.fromJson(e as Map<String, dynamic>)).toList()));
    } catch (_) {}
  }

  void setRemote(List<Book> list, Map<String, List<Word>> words) {
    remoteBooks = list;
    WordBank.remote = words;
    _prefs?.setString(
        _remoteKey,
        jsonEncode({
          'books': list.map((b) => b.toJson()).toList(),
          'words': words.map((k, v) => MapEntry(k, v.map((w) => w.toJson()).toList())),
        }));
    notifyListeners();
  }

  /// Faqat sinov uchun: o'tgan kunlar faolligi va takror jadvali namunasi.
  void seedDemo() {
    final t = today;
    const counts = [8, 14, 20, 26, 12, 18, 22, 9];
    for (var i = 1; i <= 40; i++) {
      final r = (i * 37) % 11;
      if (i <= 12 || r > 5) {
        final k = ds(addDays(t, -i));
        log[k] = counts[i % 8];
        days[k] = DayLog(newWords: counts[i % 8], newUnits: {'e1|${1 + i % 3}'}, sessions: 1 + i % 3, right: 18, wrong: 3);
      }
    }
    void put(String b, int u, int n, int stage, int dueOff) {
      for (var i = 0; i < n; i++) {
        prog[wkey(b, u, i)] = Prog(learned: true, stage: stage, due: ds(addDays(t, dueOff)));
      }
    }

    put('e1', 1, 20, 2, -1); // 7-kun takrori kechikkan
    put('e1', 2, 20, 1, 0); // 3-kun takrori bugun
    put('e1', 3, 10, 0, 1); // 1-kun takrori ertaga
    changed();
  }

  void resetAll() {
    prog = {};
    log = {};
    days = {};
    saved = {};
    bonusXp = 0;
    dayOffset = 0;
    dailyDay = '';
    dailyCount = 0;
    offlineDay = '';
    offlineCount = 0;
    currentBook = 'e1';
    askedSave = '';
    evening = '';
    myWords = [];
    changed();
  }

  // ---------- vaqt ----------
  DateTime get now => DateTime.now().add(Duration(days: dayOffset));
  DateTime get today {
    final n = now;
    return DateTime(n.year, n.month, n.day);
  }

  String get td => ds(today);

  void shiftDays(int n) {
    dayOffset += n;
    changed();
  }

  DayLog day(String k) => days.putIfAbsent(k, () => DayLog());
  DayLog? dayOf(DateTime d) => days[ds(d)];

  // ---------- sozlamalar ----------
  void setReverse(bool v) {
    reverse = v;
    changed();
  }

  static const fontMin = .8, fontMax = 1.6;
  void bumpFont(int dir) {
    fontScale = ((fontScale + dir * .1) * 10).round() / 10;
    fontScale = fontScale.clamp(fontMin, fontMax);
    changed();
  }

  void setVoice(String name, String locale) {
    voiceName = name;
    voiceLocale = locale;
    changed();
  }

  void setListen({int? repeat, double? speed, bool? shuffle, bool? uzFirst}) {
    listenRepeat = repeat ?? listenRepeat;
    listenSpeed = speed ?? listenSpeed;
    listenShuffle = shuffle ?? listenShuffle;
    listenUzFirst = uzFirst ?? listenUzFirst;
    changed();
  }

  void setProfile({String? nick, String? avatar, int? goal}) {
    if (nick != null) nickname = nick;
    if (avatar != null) this.avatar = avatar;
    if (goal != null) dailyGoal = goal;
    changed();
  }

  String get displayName => nickname.isEmpty ? 'Siz' : nickname;

  // ---------- kitoblar va so'zlar ----------
  int unitsOf(Book b) => b.isMine ? max(1, (myWords.length / 20).ceil()) : b.fixedUnits;

  /// Pullik markaz kitobi va hali sotib olinmagan.
  bool locked(Book b) => b.paid && !owned.contains(b.id);

  List<Word> words(String b, int u) {
    if (b == myBookId) {
      final s = (u - 1) * 20;
      if (s >= myWords.length) return const [];
      return myWords.sublist(s, min(s + 20, myWords.length));
    }
    return WordBank.unit(b, u);
  }

  bool learned(String k) => prog[k]?.learned ?? false;
  int unitLearned(String b, int u) {
    final w = words(b, u);
    var n = 0;
    for (var i = 0; i < w.length; i++) {
      if (learned(wkey(b, u, i))) n++;
    }
    return n;
  }

  bool unitDone(String b, int u) {
    final w = words(b, u).length;
    return w > 0 && unitLearned(b, u) == w;
  }

  int bookPct(String id) {
    final b = bookById(id);
    var n = 0, all = 0;
    final units = unitsOf(b);
    for (var u = 1; u <= units; u++) {
      n += unitLearned(id, u);
      final w = words(id, u).length;
      all += b.isMine ? w : (w == 0 ? 20 : w);
    }
    return all == 0 ? 0 : (n / all * 100).round();
  }

  int get totalLearned => prog.values.where((p) => p.learned).length;

  /// Davom etish uchun birinchi tugallanmagan unit.
  int? nextUnit(String id) {
    final b = bookById(id);
    for (var u = 1; u <= unitsOf(b); u++) {
      final w = words(id, u).length;
      if (unitLearned(id, u) < (b.isMine ? w : (w == 0 ? 20 : w))) return u;
    }
    return null;
  }

  /// Bugungi mashq uchun yangi so'zlar: tanlangan kitobning birinchi tugallanmagan unitidan.
  List<CardItem> nextNewCards() {
    final b = currentBook;
    final u = nextUnit(b);
    if (u == null) return const [];
    final w = words(b, u);
    return [
      for (var i = 0; i < w.length; i++)
        if (!learned(wkey(b, u, i))) CardItem(wkey(b, u, i), b, u, w[i]),
    ];
  }

  void pickBook(String id) {
    currentBook = id;
    changed();
  }

  // ---------- Mening so'zlarim ----------
  bool hasMyWord(String en) => myWords.any((w) => w.en.toLowerCase() == en.trim().toLowerCase());

  /// Qo'shilgan unit raqamini qaytaradi.
  int addMyWord(Word w) {
    myWords.add(w);
    changed();
    return (myWords.length / 20).ceil();
  }

  void editMyWord(int index, Word w) {
    myWords[index] = w;
    changed();
  }

  // ---------- XP, unvon, olov ----------
  int get xp => totalLearned * 10 + bonusXp;

  ({String cur, String? next, int nextAt, int pct}) get titleInfo {
    final x = xp;
    var i = 0;
    while (i + 1 < titles.length && titles[i + 1].$1 <= x) {
      i++;
    }
    final cur = titles[i];
    final nx = i + 1 < titles.length ? titles[i + 1] : null;
    final pct = nx == null ? 100 : ((x - cur.$1) / (nx.$1 - cur.$1) * 100).round();
    return (cur: cur.$2, next: nx?.$2, nextAt: nx?.$1 ?? x, pct: pct);
  }

  bool active(DateTime d) {
    final k = ds(d);
    return (log[k] ?? 0) > 0 || saved.contains(k);
  }

  int get streak {
    var d = today;
    if (!active(d)) d = addDays(d, -1);
    var n = 0;
    while (active(d)) {
      n++;
      d = addDays(d, -1);
    }
    return n;
  }

  /// Kecha o'tkazib yuborilgan bo'lsa, undan oldingi ketma-ketlik.
  int get prevStreak {
    var d = addDays(today, -2);
    var n = 0;
    while (active(d)) {
      n++;
      d = addDays(d, -1);
    }
    return n;
  }

  /// Eng uzun seriyalar (uzunidan qisqasiga).
  List<StreakRun> bestStreaks([int n = 3]) {
    final keys = {...log.keys.where((k) => (log[k] ?? 0) > 0), ...saved}.toList()..sort();
    final runs = <StreakRun>[];
    DateTime? start, prev;
    for (final k in keys) {
      final d = DateTime.parse(k);
      if (d.isAfter(today)) continue;
      if (prev != null && addDays(prev, 1) == d) {
        prev = d;
        continue;
      }
      if (start != null) runs.add(StreakRun(start, prev!));
      start = d;
      prev = d;
    }
    if (start != null) runs.add(StreakRun(start, prev!));
    runs.sort((a, b) => b.length != a.length ? b.length.compareTo(a.length) : b.end.compareTo(a.end));
    return runs.take(n).toList();
  }

  /// Kecha mashq qilinmagan, undan oldin qilingan, bugun hali yo'q: olovni saqlash taklifi.
  bool get needSave => !active(addDays(today, -1)) && active(addDays(today, -2)) && !active(today);

  /// Bosh sahifada bir marta ko'rsatish uchun.
  bool takeSaveOffer() {
    if (needSave && askedSave != td) {
      askedSave = td;
      save();
      return true;
    }
    return false;
  }

  /// 20:00 dan keyin bugun hali mashq bo'lmasa: "Marrangiz kuyadi".
  bool get eveningWarning => !active(today) && streak > 0 && (now.hour >= 20 || evening == td);

  void showEveningDemo() {
    evening = td;
    changed();
  }

  void saveStreakDay({required bool todayMode}) {
    saved.add(ds(todayMode ? today : addDays(today, -1)));
    changed();
  }

  void logToday(int n) {
    log[td] = (log[td] ?? 0) + n;
  }

  // ---------- takrorlar ----------
  List<String> get dueKeys => prog.entries
      .where((e) => e.value.learned && e.value.stage < intervals.length && e.value.due.compareTo(td) <= 0)
      .map((e) => e.key)
      .toList();

  List<DueGroup> get dueGroups => _groups(dueKeys, td);

  List<DueGroup> _groups(Iterable<String> keys, String onDay) {
    final g = <String, List<String>>{};
    for (final k in keys) {
      final p = k.split('|');
      g.putIfAbsent(ukey(p[0], int.parse(p[1])), () => []).add(k);
    }
    return g.entries.map((e) {
      final p = e.key.split('|');
      final st = e.value.map((k) => prog[k]!.stage).reduce(min);
      final late = e.value.any((k) => prog[k]!.due.compareTo(onDay) < 0);
      return DueGroup(p[0], int.parse(p[1]), e.value, st, late);
    }).toList()
      ..sort((a, b) => a.late != b.late ? (a.late ? -1 : 1) : a.unit.compareTo(b.unit));
  }

  int dueOn(DateTime d) {
    final k = ds(d);
    return prog.values.where((p) => p.learned && p.stage < intervals.length && p.due == k).length;
  }

  /// Aynan shu kunga belgilangan (hali bajarilmagan) takror unitlari.
  List<DueGroup> plannedOn(DateTime d) {
    final k = ds(d);
    return _groups(
        prog.entries.where((e) => e.value.learned && e.value.stage < intervals.length && e.value.due == k).map((e) => e.key),
        k);
  }

  /// Shu kuni (yoki undan oldin) bajarilishi kerak bo'lgan takror unitlari soni: eslatmalar uchun.
  int dueUnitsBy(DateTime d) {
    final k = ds(d);
    return prog.entries
        .where((e) => e.value.learned && e.value.stage < intervals.length && e.value.due.compareTo(k) <= 0)
        .map((e) => e.key.substring(0, e.key.lastIndexOf('|')))
        .toSet()
        .length;
  }

  /// Bugun takrorlangan unitlar soni.
  int get reviewedToday => days[td]?.reviewedUnits.length ?? 0;

  List<CardItem> reviewCards(String b, int u) => _cards(dueKeys.where((k) => k.startsWith('$b|$u|')));

  /// Bugungi barcha takrorlar bitta mashqda.
  List<CardItem> allReviewCards() => _cards(dueKeys);

  List<CardItem> _cards(Iterable<String> keys) {
    final list = <CardItem>[];
    for (final k in keys) {
      final p = k.split('|');
      final u = int.parse(p[1]);
      final i = int.parse(p[2]);
      final w = words(p[0], u);
      if (i < w.length) list.add(CardItem(k, p[0], u, w[i]));
    }
    list.shuffle();
    return list;
  }

  /// Takror bajarilganini o'sha takror belgilangan kunga yozish (kechikib bajarilsa ham).
  void _creditReview(CardItem c, Prog p) {
    final u = ukey(c.book, c.unit);
    final dueDay = p.due.compareTo(td) < 0 ? p.due : td;
    final d = day(dueDay);
    d.reviewUnits.add(u);
    if (dueDay != td) d.lateUnits[u] = td;
    final t = day(td);
    t.reviewedUnits.add(u);
    t.reviewWords++;
  }

  // ---------- mashq natijalari ----------
  void markEasy(CardItem c, {required bool review}) {
    day(td).right++;
    if (review) {
      final p = prog[c.key];
      if (p != null) {
        _creditReview(c, p);
        // Kechikkan takror: keyingi sana asl sanadan hisoblanadi, lekin ertadan oldin emas.
        final due = DateTime.tryParse(p.due) ?? today;
        final base = due.isBefore(today) ? due : today;
        p.stage++;
        if (p.stage < intervals.length) {
          var next = addDays(base, intervals[p.stage] - intervals[p.stage - 1]);
          final tomorrow = addDays(today, 1);
          if (next.isBefore(tomorrow)) next = tomorrow;
          p.due = ds(next);
        } else {
          p.due = '9999-12-31';
        }
        bonusXp += 5;
        logToday(1);
      }
    } else if (!learned(c.key)) {
      final p = prog[c.key] ?? Prog(due: td);
      p
        ..learned = true
        ..stage = 0
        ..due = ds(addDays(today, 1));
      prog[c.key] = p;
      final d = day(td);
      d.newWords++;
      d.newUnits.add(ukey(c.book, c.unit));
      logToday(1);
    } else {
      logToday(1);
    }
    changed();
  }

  void markHard(CardItem c, {required bool review}) {
    day(td).wrong++;
    final p = prog[c.key] ?? Prog(due: td);
    p.fails++;
    if (review && p.learned) {
      _creditReview(c, p);
      p.stage = 0;
      p.due = ds(addDays(today, 1));
    }
    prog[c.key] = p;
    changed();
  }

  int fails(String k) => prog[k]?.fails ?? 0;

  void logSession() {
    day(td).sessions++;
    changed();
  }

  // ---------- limit va Premium ----------
  bool get isPremium => premiumUntil != null && premiumUntil!.compareTo(td) >= 0;

  int get sessionsLeft {
    if (isPremium) return 1 << 30;
    if (dailyDay != td) return freeSessions;
    return max(0, freeSessions - dailyCount);
  }

  void useSession() {
    if (isPremium) return;
    if (dailyDay != td) {
      dailyDay = td;
      dailyCount = 0;
    }
    dailyCount++;
    changed();
  }

  /// Internetsiz qolgan mashqlar (bugun).
  int get offlineLeft => offlineDay == td ? max(0, offlineSessions - offlineCount) : offlineSessions;

  void useOffline() {
    if (offlineDay != td) {
      offlineDay = td;
      offlineCount = 0;
    }
    offlineCount++;
    changed();
  }

  void activatePremium(int days) {
    final base = isPremium ? DateTime.parse(premiumUntil!) : today;
    premiumUntil = ds(addDays(base, days));
    changed();
  }

  // ---------- reyting ----------
  int myScore(int per) {
    const days = [1, 7, 30, 99999];
    var n = 0;
    for (final e in log.entries) {
      final d = DateTime.parse(e.key);
      final diff = today.difference(d).inDays;
      if (diff >= 0 && diff < days[per]) n += e.value;
    }
    return n;
  }
}

/// Javobni solishtirish uchun: kichik harf, turli apostroflar bitta, ortiqcha bo'shliqsiz.
String normalize(String s) =>
    s.toLowerCase().replaceAll(RegExp(r"[ʻʼ‘’`´]"), "'").replaceAll(RegExp(r'\s+'), ' ').trim();
