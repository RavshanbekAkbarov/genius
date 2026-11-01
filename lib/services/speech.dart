import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Telefondagi bitta inglizcha ovoz.
class VoiceOption {
  final String name;
  final String locale;
  final String label;
  const VoiceOption(this.name, this.locale, this.label);
}

/// Talaffuz: telefonning o'z ovoz dvigateli (internet shart emas).
/// Tanlangan ovoz bir marta saqlanadi va hamma joyda ishlatiladi.
class Speech {
  static final FlutterTts _tts = FlutterTts();
  static bool _ready = false;
  static String? _voice;
  static String? _voiceLocale;
  static bool? _uz;
  static Set<String>? _uzFiles;
  static final AudioPlayer _player = AudioPlayer();

  /// Odatdagi tezlik (flutter_tts da 0.5 oddiy tezlik).
  static const baseRate = 0.45;

  static Future<void> _init() async {
    if (_ready) return;
    await _tts.awaitSpeakCompletion(true);
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(baseRate);
    _ready = true;
    await _applyVoice();
  }

  static Future<void> _applyVoice() async {
    if (_voice != null && _voiceLocale != null) {
      await _tts.setVoice({'name': _voice!, 'locale': _voiceLocale!});
    } else {
      await _tts.setLanguage('en-US');
    }
  }

  /// Saqlangan ovozni o'rnatish (ilova ochilganda va ovoz tanlanganda).
  static Future<void> useVoice(String? name, String? locale) async {
    _voice = name;
    _voiceLocale = locale;
    if (_ready) {
      try {
        await _applyVoice();
      } catch (_) {}
    }
  }

  /// Inglizcha so'zni o'qish. [speed] 1.0 = odatdagi tezlik.
  static Future<void> speak(String text, {double speed = 1.0}) async {
    try {
      await _init();
      await _tts.stop();
      await _tts.setSpeechRate((baseRate * speed).clamp(0.1, 1.0));
      await _tts.speak(text);
    } catch (_) {
      // Ovoz dvigateli bo'lmasa jim qolamiz.
    }
  }

  /// Ilova ichidagi o'zbekcha ovoz fayli nomi (tool/uz_audio.py dagi key() bilan bir xil).
  static String uzAudioKey(String text) =>
      sha1.convert(utf8.encode(text.trim().replaceAll(RegExp(r'\s+'), ' '))).toString().substring(0, 12);

  static Future<Set<String>> _uzAudio() async {
    if (_uzFiles != null) return _uzFiles!;
    try {
      final m = await AssetManifest.loadFromAssetBundle(rootBundle);
      _uzFiles = m.listAssets().where((a) => a.startsWith('assets/audio/uz/') && a.endsWith('.mp3')).toSet();
    } catch (_) {
      _uzFiles = {};
    }
    return _uzFiles!;
  }

  /// Bu o'zbekcha matn uchun ilovada tayyor ovoz bormi.
  static Future<bool> hasUzAudio(String text) async =>
      (await _uzAudio()).contains('assets/audio/uz/${uzAudioKey(text)}.mp3');

  /// O'zbekcha o'qish: avval ilova ichidagi yozib olingan ovoz, bo'lmasa telefonning o'zbek ovozi (bo'lsa).
  static Future<void> speakUz(String text, {double speed = 1.0}) async {
    if (await hasUzAudio(text)) {
      try {
        await _tts.stop();
        await _player.stop();
        await _player.setPlaybackRate(speed);
        final done = _player.onPlayerComplete.first;
        await _player.play(AssetSource('audio/uz/${uzAudioKey(text)}.mp3'));
        await done.timeout(const Duration(seconds: 10));
        return;
      } catch (_) {
        // Fayl o'ynamasa telefon ovoziga o'tamiz.
      }
    }
    if (!await hasUzbek()) return;
    try {
      await _init();
      await _tts.stop();
      await _tts.setLanguage('uz-UZ');
      await _tts.setSpeechRate((baseRate * speed).clamp(0.1, 1.0));
      await _tts.speak(text);
    } catch (_) {
    } finally {
      try {
        await _applyVoice();
      } catch (_) {}
    }
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
      await _player.stop();
    } catch (_) {}
  }

  /// O'zbekcha o'qish mumkinmi: ilovada yozib olingan ovozlar yoki telefonda o'zbek ovozi bor.
  static Future<bool> canSpeakUz() async => (await _uzAudio()).isNotEmpty || await hasUzbek();

  /// Telefonda o'zbek tilidagi ovoz bormi.
  static Future<bool> hasUzbek() async {
    if (_uz != null) return _uz!;
    try {
      await _init();
      final a = await _tts.isLanguageAvailable('uz-UZ');
      final voices = (await _tts.getVoices as List?) ?? const [];
      final v = voices.any((e) => '${(e as Map)['locale']}'.toLowerCase().startsWith('uz'));
      _uz = a == true && v;
    } catch (_) {
      _uz = false;
    }
    return _uz!;
  }

  static const _regions = {
    'us': 'Amerika',
    'gb': 'Britaniya',
    'au': 'Avstraliya',
    'in': 'Hindiston',
    'ca': 'Kanada',
    'ie': 'Irlandiya',
    'nz': 'Yangi Zelandiya',
    'za': 'Janubiy Afrika',
    'ng': 'Nigeriya',
  };

  /// Telefondagi inglizcha ovozlar: ko'pi bilan 5 ta, internetsiz ishlaydiganlari birinchi.
  static Future<List<VoiceOption>> voices() async {
    try {
      await _init();
      final raw = (await _tts.getVoices as List?) ?? const [];
      final all = <({String name, String locale})>[];
      for (final e in raw) {
        final m = e as Map;
        final name = '${m['name']}';
        final locale = '${m['locale']}';
        if (!locale.toLowerCase().startsWith('en')) continue;
        if (m['network_required'] == '1' || m['network_required'] == true) continue;
        all.add((name: name, locale: locale));
      }
      int rank(String locale) {
        final r = locale.toLowerCase().replaceAll('_', '-');
        const order = ['en-us', 'en-gb', 'en-au', 'en-in', 'en-ca'];
        final i = order.indexWhere(r.startsWith);
        return i < 0 ? order.length : i;
      }

      all.sort((a, b) {
        final la = a.name.toLowerCase().contains('local') ? 0 : 1;
        final lb = b.name.toLowerCase().contains('local') ? 0 : 1;
        if (la != lb) return la.compareTo(lb);
        return rank(a.locale).compareTo(rank(b.locale));
      });
      // Har xil hududdan va har xil ovozdan bittadan, 5 tagacha.
      final picked = <({String name, String locale})>[];
      final byRegion = <String, int>{};
      for (final v in all) {
        final reg = v.locale.toLowerCase();
        if ((byRegion[reg] ?? 0) >= 2) continue;
        picked.add(v);
        byRegion[reg] = (byRegion[reg] ?? 0) + 1;
        if (picked.length == 5) break;
      }
      for (final v in all) {
        if (picked.length == 5) break;
        if (!picked.contains(v)) picked.add(v);
      }
      return [
        for (final (i, v) in picked.indexed)
          VoiceOption(v.name, v.locale, '${i + 1}-ovoz · ${_region(v.locale)}${_gender(v.name)}'),
      ];
    } catch (_) {
      return const [];
    }
  }

  static String _region(String locale) {
    final p = locale.toLowerCase().replaceAll('_', '-').split('-');
    return p.length > 1 ? (_regions[p[1]] ?? p[1].toUpperCase()) : 'Inglizcha';
  }

  static String _gender(String name) {
    final n = name.toLowerCase();
    if (n.contains('female')) return ' · ayol';
    if (n.contains('male')) return ' · erkak';
    return '';
  }
}
