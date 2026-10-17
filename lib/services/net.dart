import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Internet bormi: Google'ning "204" manziliga qisqa so'rov yuboriladi.
class Net {
  static final online = ValueNotifier<bool>(true);
  static Timer? _timer;

  static Future<bool> check() async {
    if (kIsWeb) return true;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
    try {
      final req = await client.getUrl(Uri.parse('https://clients3.google.com/generate_204'));
      final res = await req.close().timeout(const Duration(seconds: 5));
      await res.drain<void>();
      online.value = res.statusCode < 500;
    } catch (_) {
      online.value = false;
    } finally {
      client.close(force: true);
    }
    return online.value;
  }

  static void start() {
    check();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => check());
  }
}
