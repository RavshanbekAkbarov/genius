import 'package:flutter/material.dart';

import '../services/cloud.dart';
import '../state/scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'shell.dart';

/// Kirish: Google yoki Telegram bilan bitta bosishda. Ism, familiya va raqam so'ralmaydi.
/// [first] bo'lsa ilova birinchi ochilganda ko'rsatiladi va keyin asosiy oynaga o'tadi.
class LoginScreen extends StatefulWidget {
  final bool first;
  const LoginScreen({super.key, this.first = false});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool busy = false;

  @override
  void initState() {
    super.initState();
    Cloud.signedInNotifier.addListener(_onAuth);
  }

  @override
  void dispose() {
    Cloud.signedInNotifier.removeListener(_onAuth);
    super.dispose();
  }

  void _onAuth() {
    if (Cloud.signedInNotifier.value && mounted) _done();
  }

  void _done() {
    final s = AppScope.read(context);
    s.loginSeen = true;
    s.refresh();
    if (widget.first) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const Shell()));
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> google() async {
    final err = await Cloud.signInGoogle();
    if (err != null && mounted) toast(context, err);
  }

  Future<void> telegram() async {
    final cancel = ValueNotifier(false);
    setState(() => busy = true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.sf,
        title: const Text('Telegram orqali kirish'),
        content: const Column(mainAxisSize: MainAxisSize.min, children: [
          LinearProgressIndicator(),
          SizedBox(height: 14),
          Text("Telegram'da botni oching, «START» va «✅ Ha, kiraman» tugmalarini bosing, keyin shu yerga qayting."),
        ]),
        actions: [
          TextButton(
              onPressed: () {
                cancel.value = true;
                Navigator.pop(ctx);
              },
              child: const Text('Bekor qilish')),
        ],
      ),
    );
    final err = await Cloud.signInTelegram(cancel);
    if (!mounted) return;
    if (!cancel.value) Navigator.of(context, rootNavigator: true).pop();
    setState(() => busy = false);
    if (err == null) {
      _done();
    } else if (err.isNotEmpty) {
      toast(context, err);
    }
  }

  void skip() {
    final s = AppScope.read(context);
    s.loginSeen = true;
    s.refresh();
    if (widget.first) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const Shell()));
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(24), children: [
            Center(
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(gradient: C.grad, borderRadius: BorderRadius.circular(28)),
                alignment: Alignment.center,
                child: Text('G', style: display(46, color: Colors.white, weight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Genius', textAlign: TextAlign.center, style: display(28)),
            const Text('AURA ACADEMY',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w800, color: C.mut)),
            const SizedBox(height: 18),
            const Text(
              "Yutuqlaringiz va Premium boshqa telefonga o'tganda ham yo'qolmasligi uchun hisob yarating. Ism, familiya va raqam so'ralmaydi.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 22),
            Btn('Google bilan kirish',
                icon: const Text('G', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: C.onAc)),
                onTap: busy ? null : google),
            const SizedBox(height: 10),
            Btn('Telegram bilan kirish',
                kind: BtnKind.telegram,
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onTap: busy ? null : telegram),
            const SizedBox(height: 6),
            Btn('Hozircha kirmasdan boshlash', kind: BtnKind.text, onTap: skip),
            const SizedBox(height: 8),
            const Text(
              "Telegram bilan kirsangiz to'lov ham shu hisobga bog'lanadi. Kirmasangiz ham ilova ishlaydi, faqat reyting va to'lov uchun hisob kerak.",
              textAlign: TextAlign.center,
              style: TextStyle(color: C.mut, fontSize: 12),
            ),
          ]),
        ),
      ),
    );
  }
}
