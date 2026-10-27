import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../theme.dart';

/// AdMob reklamalari: pastdagi banner va mashqdan keyingi katta (interstitial) reklama.
/// Android: Aura Academy AdMob hisobining haqiqiy ID lari. iOS: hozircha Google sinov ID lari
/// (iOS ilova AdMob'da ochilgach shu yerda va Info.plist da almashtiriladi).
/// AdMob'da qimor va boshqa nomaqbul toifalar o'chirib qo'yiladi; ilova ham faqat
/// "G" (hamma uchun) darajadagi reklamani so'raydi.
class Ads {
  static bool _ready = false;
  static InterstitialAd? _interstitial;
  static bool _loading = false;
  static int _fails = 0;
  static Timer? _retry;

  static const _ids = {
    TargetPlatform.android: (
      banner: 'ca-app-pub-2138975626249191/3693120348',
      interstitial: 'ca-app-pub-2138975626249191/3270623524',
    ),
    TargetPlatform.iOS: (
      banner: 'ca-app-pub-3940256099942544/2934735716',
      interstitial: 'ca-app-pub-3940256099942544/4411468910',
    ),
  };

  static ({String banner, String interstitial})? get _unit => kIsWeb ? null : _ids[defaultTargetPlatform];

  static Future<void> init() async {
    if (_unit == null) return;
    try {
      await MobileAds.instance.initialize();
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(maxAdContentRating: MaxAdContentRating.g),
      );
      _ready = true;
      _loadInterstitial();
    } catch (e) {
      debugPrint('AdMob ishga tushmadi: $e');
    }
  }

  /// Katta reklamani oldindan yuklash. Yuklanmasa 5, 10, 20, 40, 60 soniyadan keyin qayta uriniladi.
  static void _loadInterstitial() {
    if (!_ready || _loading || _interstitial != null) return;
    _loading = true;
    _retry?.cancel();
    InterstitialAd.load(
      adUnitId: _unit!.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _loading = false;
          _fails = 0;
        },
        onAdFailedToLoad: (e) {
          debugPrint('Interstitial yuklanmadi: $e');
          _loading = false;
          _fails++;
          _retry = Timer(Duration(seconds: min(60, 5 * (1 << min(_fails - 1, 4)))), _loadInterstitial);
        },
      ),
    );
  }

  /// Mashq boshlanganda chaqiriladi: tugaguncha reklama tayyor bo'lib turadi.
  static void preload() => _loadInterstitial();

  /// Mashq tugagach yoki olovni saqlashda ko'rsatiladigan katta reklama.
  /// Tayyor bo'lmasa 3 soniyagacha kutiladi. Baribir bo'lmasa: [fallback] bo'lsa 5 soniyalik
  /// ichki oyna, aks holda hech narsa.
  static Future<void> showInterstitial(BuildContext context, {String label = 'Reklama', bool fallback = false}) async {
    if (_interstitial == null && _ready) {
      _loadInterstitial();
      final end = DateTime.now().add(const Duration(seconds: 3));
      while (_interstitial == null && DateTime.now().isBefore(end)) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    }
    if (!context.mounted) return;
    final ad = _interstitial;
    if (ad != null) {
      _interstitial = null;
      final done = Completer<void>();
      void finish(InterstitialAd a) {
        a.dispose();
        _loadInterstitial();
        if (!done.isCompleted) done.complete();
      }

      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: finish,
        onAdFailedToShowFullScreenContent: (a, _) => finish(a),
      );
      ad.show();
      return done.future;
    }
    _loadInterstitial();
    if (!fallback) return;
    await Navigator.of(context, rootNavigator: true).push(PageRouteBuilder(
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

/// Pastdagi kichik banner (AdMob).
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});
  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _failed = false;
  int _tries = 0;
  Timer? _retry;

  @override
  void initState() {
    super.initState();
    if (!Ads._ready) {
      _failed = true;
      return;
    }
    _load();
  }

  /// Banner yuklanmasa 20 soniyadan keyin yana uriniladi (3 martagacha).
  void _load() {
    _tries++;
    _ad = BannerAd(
      size: AdSize.banner,
      adUnitId: Ads._unit!.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, e) {
          ad.dispose();
          _ad = null;
          if (!mounted) return;
          if (_tries < 3) {
            _retry = Timer(const Duration(seconds: 20), () {
              if (mounted) _load();
            });
          } else {
            setState(() => _failed = true);
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _retry?.cancel();
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const SizedBox.shrink();
    return Container(
      height: 50,
      color: C.sf2,
      alignment: Alignment.center,
      child: _loaded && _ad != null ? SizedBox(width: 320, height: 50, child: AdWidget(ad: _ad!)) : null,
    );
  }
}
