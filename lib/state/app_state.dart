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

String ds(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);
String wkey(String b, int u, int i) => '$b|$u|$i';

/// Ilovaning butun holati. Hammasi telefonda (SharedPreferences) saqlanadi.
class AppState extends ChangeNotifier {
  static const _key = 'genius-v1';
  SharedPreferences? _prefs;

  Map<String, Prog> prog = {};
  Map<String, int> log = {};
  Set<String> saved = {};
  int bonusXp = 0;
  int dayOffset = 0; // faqat sinov uchun: kunni oldinga surish
  String? premiumUntil;
  String dailyDay = '';
  int dailyCount = 0;
  Set<String> owned = {};
  int invited = 0;
  bool parentLinked = false;
  String currentBook = 'e2';
  String askedSave = '';
  String evening = '';
  String name = 'Aziz Karimov';
  List<Word> myWords = [];

  // ---------- saqlash ----------
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw != null) {
      try {
        _fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    } else {
      _seedSamples();
      save();
    }
  }

  void save() {
    _prefs?.setString(_key, jsonEncode(_toJson()));
  }

  void changed() {
    save();
    notifyListeners();
  }

  Map<String, dynamic> _toJson() => {
        'prog': prog.map((k, v) => MapEntry(k, v.toJson())),
        'log': log,
        'saved': saved.toList(),
        'xp': bonusXp,
        'offset': dayOffset,
        'premiumUntil': premiumUntil,
        'daily': {'d': dailyDay, 'n': dailyCount},
        'owned': owned.toList(),
        'invited': invited,
        'parent': parentLinked,
        'book': currentBook,
        'askedSave': askedSave,
        'evening': evening,
        'name': name,
        'my': myWords.map((w) => w.toJson()).toList(),
      };

  void _fromJson(Map<String, dynamic> j) {
    prog = ((j['prog'] ?? {}) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, Prog.fromJson(v as Map<String, dynamic>)));
    log = ((j['log'] ?? {}) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int));
    saved = ((j['saved'] ?? []) as List).cast<String>().toSet();
    bonusXp = (j['xp'] ?? 0) as int;
    dayOffset = (j['offset'] ?? 0) as int;
    premiumUntil = j['premiumUntil'] as String?;
    final daily = (j['daily'] ?? {}) as Map<String, dynamic>;
    dailyDay = (daily['d'] ?? '') as String;
    dailyCount = (daily['n'] ?? 0) as int;
    owned = ((j['owned'] ?? []) as List).cast<String>().toSet();
    invited = (j['invited'] ?? 0) as int;
    parentLinked = j['parent'] == true;
    currentBook = (j['book'] ?? 'e2') as String;
    askedSave = (j['askedSave'] ?? '') as String;
    evening = (j['evening'] ?? '') as String;
    name = (j['name'] ?? name) as String;
    myWords = ((j['my'] ?? []) as List).map((e) => Word.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Birinchi ochilishda: o'tgan kunlar faolligi va takror jadvali uchun namuna.
  void _seedSamples() {
    final t = today;
    const counts = [8, 14, 20, 26, 12, 18, 22, 9];
    for (var i = 1; i <= 40; i++) {
      final r = (i * 37) % 11;
      if (i <= 12 || r > 5) log[ds(addDays(t, -i))] = counts[i % 8];
    }
    void put(String b, int u, int n, int stage, int dueOff) {
      for (var i = 0; i < n; i++) {
        prog[wkey(b, u, i)] = Prog(learned: true, stage: stage, due: ds(addDays(t, dueOff)));
      }
    }

    put('e1', 1, 20, 2, -1); // 7-kun takrori o'tkazib yuborilgan
    put('e1', 2, 20, 1, 0); // 3-kun takrori bugun
    put('e2', 1, 10, 0, 1); // 1-kun takrori ertaga
  }

  void resetAll() {
    prog = {};
    log = {};
    saved = {};
    bonusXp = 0;
    dayOffset = 0;
    premiumUntil = null;
    dailyDay = '';
    dailyCount = 0;
    owned = {};
    invited = 0;
    parentLinked = false;
    currentBook = 'e2';
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

  // ---------- kitoblar va so'zlar ----------
  int unitsOf(Book b) => b.isMine ? max(1, (myWords.length / 20).ceil()) : b.fixedUnits;

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

  int bookPct(String id) {
    final b = bookById(id);
    var n = 0;
    final units = unitsOf(b);
    for (var u = 1; u <= units; u++) {
      n += unitLearned(id, u);
    }
    final all = b.isMine ? myWords.length : units * 20;
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

  List<DueGroup> get dueGroups {
    final g = <String, List<String>>{};
    for (final k in dueKeys) {
      final p = k.split('|');
      g.putIfAbsent('${p[0]}|${p[1]}', () => []).add(k);
    }
    return g.entries.map((e) {
      final p = e.key.split('|');
      final st = e.value.map((k) => prog[k]!.stage).reduce(min);
      final late = e.value.any((k) => prog[k]!.due.compareTo(td) < 0);
      return DueGroup(p[0], int.parse(p[1]), e.value, st, late);
    }).toList();
  }

  int dueOn(DateTime d) {
    final k = ds(d);
    return prog.values.where((p) => p.learned && p.stage < intervals.length && p.due == k).length;
  }

  List<CardItem> reviewCards(String b, int u) {
    final list = <CardItem>[];
    for (final k in dueKeys.where((k) => k.startsWith('$b|$u|'))) {
      final i = int.parse(k.split('|')[2]);
      final w = words(b, u);
      if (i < w.length) list.add(CardItem(k, b, u, w[i]));
    }
    list.shuffle();
    return list;
  }

  // ---------- mashq natijalari ----------
  void markEasy(CardItem c, {required bool review}) {
    if (review) {
      final p = prog[c.key];
      if (p != null) {
        p.stage++;
        p.due = p.stage < intervals.length
            ? ds(addDays(today, intervals[p.stage] - intervals[p.stage - 1]))
            : '9999-12-31';
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
      logToday(1);
    } else {
      logToday(1);
    }
    changed();
  }

  void markHard(CardItem c, {required bool review}) {
    final p = prog[c.key] ?? Prog(due: td);
    p.fails++;
    if (review) {
      p.stage = 0;
      p.due = ds(addDays(today, 1));
    }
    prog[c.key] = p;
    changed();
  }

  int fails(String k) => prog[k]?.fails ?? 0;

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

  void activatePremium(int days) {
    final base = isPremium ? DateTime.parse(premiumUntil!) : today;
    premiumUntil = ds(addDays(base, days));
    changed();
  }

  void addInvite() {
    invited++;
    activatePremium(7);
  }

  void buy(String id, String kind) {
    owned.add('$id:$kind');
    if (kind == 'both') owned.addAll(['$id:read', '$id:words']);
    changed();
  }

  void linkParent() {
    parentLinked = true;
    changed();
  }

  // ---------- reyting va hisobot ----------
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
