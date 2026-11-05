import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Tinglash fonda ham davom etishi uchun Android'dagi xizmat (bildirishnoma + uyg'oq qoldirish).
/// Ekran o'chsa yoki ilovadan chiqilsa ham so'zlar o'qilaveradi. Boshqa platformalarda hech narsa qilmaydi.
class Background {
  static const _ch = MethodChannel('genius/listen');
  static VoidCallback? _onStop;

  static bool get _android => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> start(String text, {VoidCallback? onStop}) async {
    if (!_android) return;
    _onStop = onStop;
    _ch.setMethodCallHandler((c) async {
      if (c.method == 'stop') _onStop?.call();
    });
    try {
      await _ch.invokeMethod('start', {'text': text});
    } catch (e) {
      debugPrint('Fon xizmati ishga tushmadi: $e');
    }
  }

  static Future<void> update(String text) async {
    if (!_android) return;
    try {
      await _ch.invokeMethod('update', {'text': text});
    } catch (_) {}
  }

  static Future<void> stop() async {
    if (!_android) return;
    _onStop = null;
    try {
      await _ch.invokeMethod('stop');
    } catch (_) {}
  }
}
