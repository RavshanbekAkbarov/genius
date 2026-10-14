import 'package:flutter/material.dart';

import '../services/ads.dart';
import '../state/scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home.dart';
import 'profile.dart';

/// Olovni saqlash: 3 ta reklama yoki Premium.
/// todayMode=false: kecha o'tkazib yuborilgan kunni saqlash.
/// todayMode=true: 20:00 dan keyin bugungi kunni saqlash ("Marrangiz kuyadi").
class StreakScreen extends StatefulWidget {
  final bool todayMode;
  const StreakScreen({super.key, required this.todayMode});
  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  int watched = 0;

  Future<void> watch() async {
    await Ads.showInterstitial(context, label: 'Olovni saqlash: ${watched + 1}/3');
    if (!mounted) return;
    setState(() => watched++);
    if (watched >= 3) AppScope.read(context).saveStreakDay(todayMode: widget.todayMode);
  }

  void premiumSave() {
    final s = AppScope.read(context);
    if (s.isPremium) {
      s.saveStreakDay(todayMode: widget.todayMode);
      setState(() => watched = 3);
    } else {
      push(context, const PremiumScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final saved = watched >= 3 || (widget.todayMode && s.saved.contains(s.td));
    final count = widget.todayMode ? s.streak : (saved ? s.prevStreak + 1 : s.prevStreak);
    final title = saved ? 'Olov saqlandi!' : (widget.todayMode ? 'Marrangiz kuyadi!' : "Olovingiz o'chmoqda!");
    final text = saved
        ? (widget.todayMode
            ? 'Bugungi kun hisoblandi. Ertaga ham mashq qilishni unutmang.'
            : 'Ketma-ketlik davom etmoqda. Bugun ham mashq qilishni unutmang.')
        : (widget.todayMode
            ? "Bugun hali so'z yodlamadingiz va takrorlamadingiz. $count kunlik olovni saqlash uchun mashq qiling yoki 3 ta reklama ko'ring."
            : "Kecha mashq qilmadingiz. $count kunlik ketma-ketlikni saqlash uchun 3 ta reklama ko'ring.");
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(20), children: [
            Center(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    (saved ? C.gold : const Color(0xFFB0703A)).withValues(alpha: .35),
                    Colors.transparent,
                  ]),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.local_fire_department_rounded,
                      size: 64, color: saved ? C.gold : const Color(0xFF9A7A62)),
                  Text('$count', style: display(30, weight: FontWeight.w700)),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center, style: display(20)),
            const SizedBox(height: 10),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: C.mut)),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < 3; i++)
                Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < watched || saved ? C.good : C.sf2,
                    border: Border.all(color: C.ln),
                  ),
                  alignment: Alignment.center,
                  child: Text(i < watched || saved ? '✓' : '${i + 1}',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, color: i < watched || saved ? const Color(0xFF052611) : C.mut)),
                ),
            ]),
            const SizedBox(height: 18),
            if (saved)
              Btn('Davom etish', onTap: () => Navigator.of(context).pop())
            else ...[
              if (widget.todayMode) ...[
                Btn('Hozir mashq qilish', onTap: () {
                  Navigator.of(context).pop();
                  openSetup(context, s.currentBook);
                }),
                const SizedBox(height: 10),
              ],
              Btn("Reklama ko'rish (${3 - watched} ta qoldi)",
                  kind: widget.todayMode ? BtnKind.ghost : BtnKind.primary, onTap: watch),
              const SizedBox(height: 10),
              Btn('Premium: reklamasiz saqlash',
                  kind: BtnKind.ghost,
                  icon: const Icon(Icons.workspace_premium_rounded, color: C.gold, size: 20),
                  onTap: premiumSave),
              if (!widget.todayMode) ...[
                const SizedBox(height: 4),
                Btn("Kerak emas, 0 dan boshlayman", kind: BtnKind.text, onTap: () => Navigator.of(context).pop()),
              ],
            ],
          ]),
        ),
      ),
    );
  }
}
