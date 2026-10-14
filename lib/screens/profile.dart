import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/catalog.dart';
import '../state/app_state.dart';
import '../state/scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home.dart';
import 'shell.dart';
import 'streak.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});
  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool resetSure = false;

  void eveningDemo(AppState s) {
    s.showEveningDemo();
    ShellScope.of(context).goTab(0);
    showFakePush(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final prem = s.isPremium;
    final initials = s.name.split(' ').where((x) => x.isNotEmpty).map((x) => x[0]).join();
    Widget row(String title, {String? sub, Widget? trailing, VoidCallback? onTap, Widget? leading}) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: leading,
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: sub == null ? null : Text(sub, style: const TextStyle(color: C.mut, fontSize: 12)),
          trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: C.mut),
          onTap: onTap,
        );
    return ListView(padding: EdgeInsets.zero, children: [
      const TabHeader(title: 'Profil', subtitle: "Aura Academy o'quvchisi"),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: C.grad, borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(14)),
                alignment: Alignment.center,
                child: Text(initials, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(
                        child: Text(s.name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white))),
                    if (prem) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.workspace_premium_rounded, color: C.gold, size: 20),
                    ],
                  ]),
                  Text('${s.titleInfo.cur} · ${s.xp} XP · ${s.streak} kun',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _stat('${s.totalLearned}', "yodlangan so'z")),
            const SizedBox(width: 10),
            Expanded(child: _stat('${s.myScore(1)}', "so'z shu hafta")),
          ]),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: Column(children: [
              row('Genius Premium',
                  leading: const Icon(Icons.workspace_premium_rounded, color: C.gold),
                  trailing: Pill(
                    prem
                        ? 'faol · ${s.premiumUntil!.substring(8)}.${s.premiumUntil!.substring(5, 7)} gacha'
                        : '${money(premiumPrice)}/oy',
                    bg: prem ? C.good : C.ac,
                    fg: prem ? const Color(0xFF052611) : C.onAc,
                  ),
                  onTap: () => push(context, const PremiumScreen())),
              row("Do'stni taklif qilish",
                  sub: 'har bir do\'st uchun 1 hafta Premium', onTap: () => push(context, const InviteScreen())),
              row('Ota-onani ulash',
                  sub: s.parentLinked ? 'Ulangan · har yakshanba hisobot' : "Haftalik hisobot Telegram'ga",
                  onTap: () => push(context, const ParentScreen())),
              SwitchRow(
                  title: 'Eslatmalar',
                  subtitle: '09:00, 14:00, 20:00 · 20:00 da mashq qilinmasa olov ogohlantirishi',
                  value: s.reminders,
                  onTap: s.toggleReminders),
              row('Kunlik maqsad', trailing: const Pill("$dailyGoal so'z")),
            ]),
          ),
          const SizedBox(height: 12),
          AppCard(
            border: C.ln,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text("Sinab ko'rish uchun", style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                  "Takror, olov va limitni ko'rish uchun kunni suring. Hozirgi sana: ${s.today.day.toString().padLeft(2, '0')}.${s.today.month.toString().padLeft(2, '0')}.${s.today.year}",
                  style: const TextStyle(color: C.mut, fontSize: 13)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: Btn('+1 kun', kind: BtnKind.ghost, onTap: () {
                  s.shiftDays(1);
                  _afterShift(s, 1);
                })),
                const SizedBox(width: 10),
                Expanded(
                    child: Btn("+2 kun (o'tkazib yuborish)", kind: BtnKind.ghost, onTap: () {
                  s.shiftDays(2);
                  _afterShift(s, 2);
                })),
              ]),
              const SizedBox(height: 10),
              Btn("Soat 20:00 eslatmasini ko'rish", kind: BtnKind.ghost, onTap: () => eveningDemo(s)),
              const SizedBox(height: 10),
              Btn(resetSure ? 'Ishonchingiz komilmi? Yana bosing' : 'Hammasini tozalash',
                  kind: BtnKind.ghost, onTap: () {
                if (resetSure) {
                  s.resetAll();
                  setState(() => resetSure = false);
                  ShellScope.of(context).goTab(0);
                } else {
                  setState(() => resetSure = true);
                }
              }),
            ]),
          ),
        ]),
      ),
    ]);
  }

  void _afterShift(AppState s, int n) {
    final due = s.dueKeys.length;
    toast(context, due > 0 ? "Eslatma: $due ta so'zni takrorlash vaqti keldi" : '$n kun o\'tdi');
    ShellScope.of(context).goTab(0);
    if (s.takeSaveOffer()) push(context, const StreakScreen(todayMode: false));
  }

  Widget _stat(String v, String l) => AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(v, style: display(20)),
          Text(l, style: const TextStyle(color: C.mut, fontSize: 12)),
        ]),
      );
}

/// Telefon bildirishnomasining ko'rinishi (sinov uchun). Haqiqiy ilovada flutter_local_notifications yuboradi.
void showFakePush(BuildContext context) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  var removed = false;
  void remove() {
    if (!removed) {
      removed = true;
      entry.remove();
    }
  }

  entry = OverlayEntry(
    builder: (ctx) => Positioned(
      top: MediaQuery.of(ctx).padding.top + 10,
      left: 10,
      right: 10,
      child: Material(
        color: const Color(0xFFEEF2F8),
        elevation: 12,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            remove();
            push(context, const StreakScreen(todayMode: true));
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(gradient: C.grad, borderRadius: BorderRadius.circular(9)),
                alignment: Alignment.center,
                child: const Text('G', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Genius', style: TextStyle(color: Color(0xFF101826), fontWeight: FontWeight.w800)),
                  Text('hozir · 20:00', style: TextStyle(color: Color(0xFF5A6577), fontSize: 11)),
                  SizedBox(height: 2),
                  Text("🔥 Marrangiz kuyadi! Bugun hali so'z yodlamadingiz. Reklama ko'rib uni saqlab qoling.",
                      style: TextStyle(color: Color(0xFF101826), fontSize: 13)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Timer(const Duration(seconds: 7), remove);
}

class _Hero extends StatelessWidget {
  final String title, sub;
  const _Hero(this.title, this.sub);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
        decoration: BoxDecoration(gradient: C.premiumGrad, borderRadius: BorderRadius.circular(24)),
        child: Column(children: [
          const Icon(Icons.workspace_premium_rounded, size: 44, color: Color(0xFF3A2208)),
          const SizedBox(height: 6),
          Text(title, textAlign: TextAlign.center, style: display(22, color: const Color(0xFF241200))),
          const SizedBox(height: 4),
          Text(sub, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF3A2208), fontWeight: FontWeight.w700)),
        ]),
      );
}

String dmy(String iso) => iso.split('-').reversed.join('.');

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    const perks = [
      ("Reklama yo'q", 'Banner ham, katta reklama ham chiqmaydi'),
      ('Cheksiz mashq', 'Bepulda kuniga $freeSessions ta mashq, Premiumda cheklov yo\'q'),
      ('Olovni reklamasiz saqlash', "O'tkazib yuborilgan kun uchun reklama ko'rish shart emas"),
      ('Premium nishoni', 'Reytingda ismingiz yonida toj'),
    ];
    return Scaffold(
      appBar: const TopBar(title: 'Genius Premium'),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        const _Hero('Genius Premium', "Reklamasiz va cheklovsiz o'rganing"),
        const SizedBox(height: 12),
        AppCard(
          child: Column(children: [
            for (final p in perks)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                    radius: 13, backgroundColor: C.good, child: Icon(Icons.check, size: 16, color: Color(0xFF052611))),
                title: Text(p.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(p.$2, style: const TextStyle(color: C.mut, fontSize: 12)),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        if (s.isPremium)
          AppCard(
            child: Column(children: [
              const Text('Premium faol', style: TextStyle(color: C.gold, fontWeight: FontWeight.w800)),
              Text('${dmy(s.premiumUntil!)} gacha', style: const TextStyle(color: C.mut, fontSize: 13)),
            ]),
          )
        else ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Color.alphaBlend(C.gold.withValues(alpha: .1), C.sf),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: C.gold, width: 2),
            ),
            child: Row(children: [
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('1 oy', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Text("avtomatik yechilmaydi, o'zingiz uzaytirasiz", style: TextStyle(color: C.mut, fontSize: 12)),
                ]),
              ),
              Text.rich(TextSpan(children: [
                TextSpan(text: money(premiumPrice), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                const TextSpan(text: " so'm"),
              ])),
            ]),
          ),
          const SizedBox(height: 12),
          Btn('Telegram bot orqali sotib olish', kind: BtnKind.telegram, onTap: () => push(context, const PayScreen())),
        ],
        const SizedBox(height: 10),
        Btn("Do'st taklif qiling: 1 hafta bepul", kind: BtnKind.ghost, onTap: () => push(context, const InviteScreen())),
      ]),
    );
  }
}

/// To'lov: Telegram bot (Click/Payme) orqali. Server to'lovni tasdiqlagach Premium yoqiladi.
class PayScreen extends StatefulWidget {
  const PayScreen({super.key});
  @override
  State<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends State<PayScreen> {
  int step = 0;

  void setStep(int n) {
    setState(() => step = n);
    if (n == 2) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        AppScope.read(context).activatePremium(30);
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const PremiumOkScreen()));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const steps = [
      ("Telegram botga o'tasiz", '@GeniusAuraBot ochiladi'),
      ("Click yoki Payme bilan to'laysiz", "${'10 000'} so'm"),
      ('Ilova tekshiradi', "Server to'lovni tasdiqlaydi, Premium o'zi yoqiladi"),
    ];
    return Scaffold(
      appBar: TopBar(title: "To'lov", subtitle: "Genius Premium · ${money(premiumPrice)} so'm"),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        for (final (i, st) in steps.indexed)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: C.sf,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: i == step ? C.ac : (i < step ? C.good : C.ln), width: i == step ? 1.5 : 1),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: i < step ? C.good : (i == step ? C.ac : C.sf2),
                child: Text(i < step ? '✓' : '${i + 1}',
                    style: TextStyle(fontWeight: FontWeight.w800, color: i <= step ? C.onAc : C.mut)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(st.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(st.$2, style: const TextStyle(color: C.mut, fontSize: 12)),
                ]),
              ),
            ]),
          ),
        const Text(
            "To'lov ilova ichida emas, Telegram botda qilinadi: Google Play qoidasiga mos va komissiya yo'q.",
            style: TextStyle(color: C.mut, fontSize: 13)),
        const SizedBox(height: 12),
        if (step == 0)
          Btn('Botni ochish', kind: BtnKind.telegram, onTap: () => setStep(1))
        else if (step == 1)
          Btn("To'ladim (demo)", onTap: () => setStep(2))
        else
          const Btn('Tekshirilmoqda…'),
        const SizedBox(height: 8),
        const Text("Hozircha to'lov o'xshatiladi, pul olinmaydi.",
            textAlign: TextAlign.center, style: TextStyle(color: C.mut, fontSize: 11)),
      ]),
    );
  }
}

class PremiumOkScreen extends StatelessWidget {
  const PremiumOkScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(20), children: [
            _Hero('Premium faollashdi!', '${dmy(s.premiumUntil ?? s.td)} gacha'),
            const SizedBox(height: 16),
            const Text("Endi reklama chiqmaydi va mashqlar soni cheklanmaydi.",
                textAlign: TextAlign.center, style: TextStyle(color: C.mut)),
            const SizedBox(height: 16),
            Btn("O'rganishni davom ettirish",
                onTap: () => Navigator.of(context).popUntil((r) => r.isFirst)),
          ]),
        ),
      ),
    );
  }
}

class InviteScreen extends StatelessWidget {
  const InviteScreen({super.key});
  static const link = 't.me/GeniusAuraBot?start=1289';
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      appBar: const TopBar(title: "Do'stni taklif qilish"),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(gradient: C.grad, borderRadius: BorderRadius.circular(20)),
          child: Column(children: [
            Text('+7 kun', style: display(32, color: Colors.white)),
            const SizedBox(height: 4),
            const Text("har bir do'st uchun", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 6),
            const Text(
                "Do'stingiz ilovaga kirib Telegram orqali tasdiqlasa, ikkalangiz ham 1 hafta Premium olasiz",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Eyebrow('Sizning havolangiz'),
            const SizedBox(height: 8),
            Row(children: [
              const Expanded(child: SelectableText(link, style: TextStyle(fontFamily: 'monospace', fontSize: 13))),
              ActionChip(
                label: const Text('Nusxa'),
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: 'https://$link'));
                  toast(context, 'Nusxa olindi');
                },
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        Btn("Telegram'da ulashish", kind: BtnKind.telegram, onTap: () {
          s.addInvite();
          toast(context, "Do'stingiz qo'shildi: +7 kun Premium");
        }),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _box('${s.invited}', "taklif qilingan do'st")),
          const SizedBox(width: 10),
          Expanded(child: _box('${s.invited * 7} kun', 'olingan Premium')),
        ]),
        const SizedBox(height: 10),
        const Text(
            "Faqat yangi foydalanuvchi hisoblanadi. Hozircha \"ulashish\" bosilganda bitta do'st qo'shilgandek bo'ladi.",
            style: TextStyle(color: C.mut, fontSize: 12)),
      ]),
    );
  }

  Widget _box(String v, String l) => AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(v, style: display(20)),
          Text(l, style: const TextStyle(color: C.mut, fontSize: 12)),
        ]),
      );
}

class ParentScreen extends StatelessWidget {
  const ParentScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      appBar: const TopBar(title: 'Ota-onani ulash', subtitle: 'Haftalik hisobot uchun'),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        AppCard(
          child: Column(children: [
            const Text('Ota-onangiz shu QR kodni telefonida skanerlasin',
                textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            const _FakeQr(),
            const SizedBox(height: 12),
            const Text(
                "Telegram bot ochiladi, bitta tugma bilan ulanadi. Markazga yozilishda administrator yordam beradi.",
                textAlign: TextAlign.center,
                style: TextStyle(color: C.mut, fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Holat', style: TextStyle(fontWeight: FontWeight.w700)),
              trailing: s.parentLinked
                  ? const Pill('Ulangan · Telegram', bg: C.good, fg: Color(0xFF052611))
                  : ActionChip(label: const Text('Ulandi (demo)'), onPressed: () {
                      s.linkParent();
                      toast(context, 'Ota-ona ulandi');
                    }),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Hisobot', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('har yakshanba', style: TextStyle(color: C.mut, fontSize: 12)),
              trailing: Pill('20:00'),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Btn("Hisobotni ko'rish", kind: BtnKind.ghost, onTap: () => push(context, const ReportScreen())),
      ]),
    );
  }
}

/// QR kodning ko'rinishi (haqiqiy QR bot havolasi tayyor bo'lganda qr_flutter bilan chiziladi).
class _FakeQr extends StatelessWidget {
  const _FakeQr();
  @override
  Widget build(BuildContext context) {
    var seed = 11;
    final cells = <bool>[];
    for (var i = 0; i < 441; i++) {
      seed = (seed * 9301 + 49297) % 233280;
      final x = i % 21, y = i ~/ 21;
      final corner = (x < 7 && y < 7) || (x > 13 && y < 7) || (x < 7 && y > 13);
      final xx = x % 14, yy = y % 14;
      cells.add(corner
          ? (xx == 0 || xx == 6 || yy == 0 || yy == 6 || (xx > 1 && xx < 5 && yy > 1 && yy < 5))
          : seed / 233280 > .52);
    }
    return Container(
      width: 190,
      height: 190,
      padding: const EdgeInsets.all(10),
      color: Colors.white,
      child: GridView.count(
        crossAxisCount: 21,
        physics: const NeverScrollableScrollPhysics(),
        children: [for (final c in cells) Container(color: c ? Colors.black : Colors.white)],
      ),
    );
  }
}

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = s.today;
    final mon = addDays(t, -(t.weekday - 1));
    final sun = addDays(mon, 6);
    final b = bookById(s.currentBook);
    return Scaffold(
      appBar: const TopBar(title: 'Haftalik hisobot', subtitle: "Ota-onaga Telegram'da shunday keladi"),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF0E1621), borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: C.grad),
                alignment: Alignment.center,
                child: const Text('G', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
              ),
              const SizedBox(width: 10),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Genius · Aura Academy', style: TextStyle(fontWeight: FontWeight.w800)),
                Text('bot', style: TextStyle(color: Color(0xFF7F91A4), fontSize: 12)),
              ]),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFF182533),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                ),
              ),
              child: Text.rich(
                TextSpan(style: const TextStyle(height: 1.6, fontSize: 14), children: [
                  const TextSpan(text: 'Haftalik hisobot\n', style: TextStyle(fontWeight: FontWeight.w800)),
                  const TextSpan(text: 'Farzandingiz '),
                  TextSpan(text: s.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  TextSpan(text: ' ${mon.day}–${sun.day} ${months[sun.month - 1]}:\n\n'),
                  TextSpan(text: "Yangi va takrorlangan so'zlar: ${s.myScore(1)}\n"),
                  TextSpan(text: 'Ketma-ket kunlar: ${s.streak}\n'),
                  TextSpan(text: 'Jami yodlangan: ${s.totalLearned}\n'),
                  TextSpan(text: 'Kitob: ${b.title} · ${s.bookPct(b.id)}%'),
                ]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Btn('Hisobotni rasm qilib yuborish',
            kind: BtnKind.ghost, onTap: () => toast(context, 'Rasm sifatida saqlandi (demo)')),
        SizedBox(height: max(0, 0)),
      ]),
    );
  }
}
