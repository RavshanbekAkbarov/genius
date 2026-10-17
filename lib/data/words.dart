import 'dart:convert';

import 'package:flutter/services.dart';

class Word {
  final String en;
  final String uz;
  final String ipa;
  final String ex;
  const Word(this.en, this.uz, [this.ipa = '', this.ex = '']);

  factory Word.fromJson(Map<String, dynamic> j) =>
      Word(j['en'] as String, j['uz'] as String, (j['ipa'] ?? '') as String, (j['ex'] ?? '') as String);

  Map<String, dynamic> toJson() => {'en': en, 'uz': uz, 'ipa': ipa, 'ex': ex};
}

/// Kitob so'zlari: "kitobId|unit" -> so'zlar ro'yxati.
/// Essential 1-6 to'liq (180 unit, 3600 so'z); tarjimalar kitob PDF'laridan olingan.
class WordBank {
  static Map<String, List<Word>> _data = {};

  static Future<void> load() async {
    final raw = await rootBundle.loadString('assets/data/words.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    _data = map.map((k, v) => MapEntry(
        k, (v as List).map((e) => Word.fromJson(e as Map<String, dynamic>)).toList()));
  }

  /// Admin paneldan qo'shilgan markaz kitoblari so'zlari (serverdan keladi, telefonda saqlanadi).
  static Map<String, List<Word>> remote = {};

  static List<Word> unit(String book, int unit) => _data['$book|$unit'] ?? remote['$book|$unit'] ?? const [];
  static Map<String, List<Word>> get all => {..._data, ...remote};
}
