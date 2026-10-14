import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Reklama joylari. Hozircha joy egallovchi (placeholder): AdMob ID lari olingach
/// shu fayldagi ikkita widget google_mobile_ads bilan almashtiriladi, qolgan kod o'zgarmaydi.
/// AdMob'da qimor va boshqa nomaqbul toifalar o'chirib qo'yiladi.
class Ads {
  /// Mashq tugagach yoki olovni saqlashda ko'rsatiladigan katta reklama.
  static Future<void> showInterstitial(BuildContext context, {String label = 'Reklama'}) {
    return Navigator.of(context, rootNavigator: true).push(PageRouteBuilder(
      opaque: true,
      pageBuilder: (_, _, _) => _Interstitial(label: label),
      transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
    ));
  }
}

class _Interstitial extends StatefulWidget {
  final String label;
  const _Interstitial({required this.label});
  @override
  State<_Interstitial> createState() => _InterstitialState();
}

class _InterstitialState extends State<_Interstitial> {
  int left = 5;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => left--);
      if (left <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: left <= 0,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        body: SafeArea(
          child: Stack(children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('REKLAMA',
                      style: TextStyle(letterSpacing: 2, color: Color(0xFF999999), fontWeight: FontWeight.w800, fontSize: 11)),
                  const SizedBox(height: 14),
                  Container(
                    height: 260,
                    width: double.infinity,
                    decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(18)),
                    alignment: Alignment.center,
                    child: const Text('Katta reklama joyi (AdMob)', style: TextStyle(color: Color(0xFF777777))),
                  ),
                  const SizedBox(height: 14),
                  Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ]),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: FilledButton.tonal(
                onPressed: left > 0 ? null : () => Navigator.of(context).pop(),
                child: Text(left > 0 ? '$left' : 'Yopish ✕'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Pastdagi kichik banner.
class AdBanner extends StatelessWidget {
  const AdBanner({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      color: C.sf2,
      alignment: Alignment.center,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(color: C.gold, borderRadius: BorderRadius.circular(4)),
          child: const Text('Ad', style: TextStyle(color: Color(0xFF241800), fontSize: 9, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 10),
        const Text('REKLAMA · BANNER',
            style: TextStyle(fontSize: 11, color: C.mut, fontWeight: FontWeight.w800, letterSpacing: .6)),
      ]),
    );
  }
}
