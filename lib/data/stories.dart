import 'dart:convert';

import 'package:flutter/services.dart';

/// Hikoya oxiridagi bitta test savoli.
class StoryQ {
  final String q;
  final List<String> options;
  final int answer;
  const StoryQ(this.q, this.options, this.answer);
  factory StoryQ.fromJson(Map<String, dynamic> j) =>
      StoryQ(j['q'] as String, (j['o'] as List).cast<String>(), (j['a'] ?? 0) as int);
}

/// Unit hikoyasi (kitobdagi o'qish matni).
class Story {
  final String id; // "e1|1"
  final String title;
  final List<String> paras;
  final List<StoryQ> qs;
  const Story(this.id, this.title, this.paras, this.qs);
  factory Story.fromJson(String id, Map<String, dynamic> j) => Story(
      id,
      j['title'] as String,
      (j['paras'] as List).cast<String>(),
      ((j['qs'] ?? []) as List).map((e) => StoryQ.fromJson(e as Map<String, dynamic>)).toList());

  int get words => paras.fold(0, (a, p) => a + p.split(RegExp(r'\s+')).length);

  /// O'qish vaqti, daqiqa (o'quvchi uchun ~110 so'z/daqiqa).
  int get minutes => (words / 110).ceil().clamp(1, 9);
}

/// Hikoyadagi so'z lug'ati: tarjima, sinonimlar, talaffuz.
class DictEntry {
  final String lemma;
  final String uz;
  final List<String> syn;
  final String ipa;
  const DictEntry(this.lemma, this.uz, this.syn, this.ipa);
}

/// Hikoyalar va lug'at ilova ichida keladi: internetsiz ishlaydi.
class StoryBank {
  static Map<String, Story> _stories = {};
  static Map<String, List> _dict = {};
  static Map<String, String> _forms = {};

  static Future<void> load() async {
    try {
      final raw = await rootBundle.loadString('assets/data/stories.json');
      final j = jsonDecode(raw) as Map<String, dynamic>;
      _stories = (j['stories'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, Story.fromJson(k, v as Map<String, dynamic>)));
      _dict = (j['dict'] as Map<String, dynamic>).map((k, v) => MapEntry(k, v as List));
      _forms = (j['forms'] as Map<String, dynamic>).cast<String, String>();
    } catch (_) {}
  }

  /// Admin paneldan kelgan hikoyalar (bir xil id bo'lsa ilovadagisi o'rniga ishlatiladi).
  static Map<String, Story> remote = {};

  static Story? of(String book, int unit) => remote['$book|$unit'] ?? _stories['$book|$unit'];

  static String norm(String token) => token.toLowerCase().replaceAll('’', "'").replaceAll('‘', "'");

  /// So'z shaklidan lug'at so'zini topish: "jumped" -> "jump", "rabbit's" -> "rabbit".
  static String lemmaOf(String token) {
    var k = norm(token);
    if (_forms.containsKey(k)) return _forms[k]!;
    if (_dict.containsKey(k)) return k;
    if (k.endsWith("'s")) k = k.substring(0, k.length - 2);
    if (_forms.containsKey(k)) return _forms[k]!;
    if (_dict.containsKey(k)) return k;
    for (final suf in const ['ing', 'ed', 'es', 's', 'd', 'er', 'est', 'ly']) {
      if (k.length > suf.length + 2 && k.endsWith(suf)) {
        final b = k.substring(0, k.length - suf.length);
        if (_dict.containsKey(b)) return b;
        if (_dict.containsKey('${b}e')) return '${b}e';
      }
    }
    return k;
  }

  static DictEntry? lookup(String token) {
    final l = lemmaOf(token);
    final v = _dict[l] ?? _dict[norm(token)];
    if (v == null) return null;
    return DictEntry(l, v[0] as String, (v[1] as List).cast<String>(), (v.length > 2 ? v[2] : '') as String);
  }

  static bool get loaded => _stories.isNotEmpty;
}
