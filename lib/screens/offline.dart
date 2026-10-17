import 'dart:async';

import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../services/net.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home.dart';
import 'profile.dart';

/// Internetsiz kunlik mashqlar tugaganda chiqadi. Internet yoqilishi bilan o'zi yopiladi
/// va mashq qolgan joyidan boshlanadi.
class OfflineScreen extends StatefulWidget {
  const OfflineScreen({super.key});
  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  Timer? timer;
  bool checking = false;

  @override
  void initState() {
    super.initState();
    Net.online.addListener(_onNet);
    timer = Timer.periodic(const Duration(seconds: 4), (_) => Net.check());
  }

  @override
  void dispose() {
    timer?.cancel();
    Net.online.removeListener(_onNet);
    super.dispose();
  }

  void _onNet() {
    if (Net.online.value && mounted) Navigator.of(context).pop(true);
  }

  Future<void> retry() async {
    setState(() => checking = true);
    final ok = await Net.check();
    if (!mounted) return;
    setState(() => checking = false);
    if (!ok) toast(context, "Hali ham internet yo'q");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(24), children: [
            Center(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(shape: BoxShape.circle, color: C.sf2, border: Border.all(color: C.ln, width: 2)),
                child: const Icon(Icons.wifi_off_rounded, size: 52, color: C.gold),
              ),
            ),
            const SizedBox(height: 20),
            Text('Internetni yoqing', textAlign: TextAlign.center, style: display(22)),
            const SizedBox(height: 12),
            const Text(
              "Genius siz uchun bepul. Buni reklamalar ta'minlaydi, ular esa internet bilan ishlaydi.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 8),
            const Text(
              "Internet yoqilishi bilan qolgan joyingizdan davom etasiz.",
              textAlign: TextAlign.center,
              style: TextStyle(color: C.mut, fontSize: 14),
            ),
            const SizedBox(height: 22),
            Btn(checking ? 'Tekshirilmoqda…' : 'Qayta urinish', onTap: checking ? null : retry),
            const SizedBox(height: 10),
            Btn("Kitobda so'z o'rganish", kind: BtnKind.ghost, onTap: () => Navigator.of(context).pop(false)),
            const SizedBox(height: 14),
            Text(
              "Internetsiz kuniga $offlineSessions ta mashq va kitobdan so'z o'rganish mumkin. Premium foydalanuvchilar internetsiz cheklovsiz ishlaydi.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: C.mut, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Btn('Premium haqida', kind: BtnKind.text, onTap: () => push(context, const PremiumScreen())),
          ]),
        ),
      ),
    );
  }
}
