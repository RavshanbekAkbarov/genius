import 'dart:async';

import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../services/cloud.dart';
import '../state/app_state.dart';
import '../state/scope.dart';
import '../theme.dart';
import '../widgets/calendar.dart';
import '../widgets/common.dart';
import '../widgets/tools.dart';
import 'home.dart';
import 'login.dart';
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
    Widget row(String title, {String? sub, Widget? trailing, VoidCallback? onTap, Widget? leading}) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: leading,
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: sub == null ? null : Text(sub, style: const TextStyle(color: C.mut, fontSize: 12)),
          trailing: trailing ?? (onTap == null ? null : const Icon(Icons.chevron_right_rounded, color: C.mut)),
          onTap: onTap,
        );
    final best = s.bestStreaks();
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
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(18)),
                alignment: Alignment.center,
                child: Text(s.avatar, style: const TextStyle(fontSize: 30)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(
                        child: Text(s.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white))),
                    if (prem) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.workspace_premium_rounded, color: C.gold, size: 20),
                    ],
                  ]),
                  Text("🔥 ${s.streak} kun · ${s.totalLearned} so'z yodlangan",
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(
                      Cloud.signedIn
                          ? (s.accountLabel ?? 'Hisobga kirilgan')
                          : 'Hisobga kirilmagan: yutuqlar faqat shu telefonda',
                      style: const TextStyle(color: Colors.white60, fontSize: 11)),
                ]),
              ),
              IconButton.filledTonal(
                tooltip: 'Profilni tahrirlash',
                onPressed: () => push(context, const ProfileEditScreen()),
                icon: const Icon(Icons.edit_rounded),
              ),
            ]),
          ),
          if (!Cloud.signedIn) ...[
            const SizedBox(height: 10),
            Btn('Hisobga kirish (Google yoki Telegram)', kind: BtnKind.ghost, onTap: () => push(context, const LoginScreen())),
          ],
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _stat('${s.totalLearned}', "yodlangan so'z")),
            const SizedBox(width: 10),
            Expanded(child: _stat('${s.myScore(1)}', "so'z shu hafta")),
            const SizedBox(width: 10),
            Expanded(child: _stat('${s.xp}', s.titleInfo.cur)),
          ]),
          const SizedBox(height: 12),
          const ActivityCalendar(),
          const SizedBox(height: 12),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SectionTitle('Eng uzun seriyalar'),
              const SizedBox(height: 10),
              if (best.isEmpty)
                const Text("Hali seriya yo'q. Ketma-ket kunlar mashq qiling.", style: TextStyle(color: C.mut))
              else
                for (final r in best)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      SizedBox(
                          width: 64,
                          child: Text(shortDate(r.start), style: const TextStyle(color: C.mut, fontSize: 12))),
                      Expanded(
                        child: LayoutBuilder(builder: (_, c) {
                          final w = c.maxWidth * (r.length / best.first.length).clamp(.15, 1.0);
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: w,
                              height: 26,
                              decoration: BoxDecoration(color: C.good, borderRadius: BorderRadius.circular(8)),
                              alignment: Alignment.center,
                              child: Text('${r.length}',
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF052611))),
                            ),
                          );
                        }),
                      ),
                      SizedBox(
                          width: 64,
                          child: Text(shortDate(r.end),
                              textAlign: TextAlign.right, style: const TextStyle(color: C.mut, fontSize: 12))),
                    ]),
                  ),
            ]),
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: Column(children: [
              row('Genius Premium',
                  leading: const Icon(Icons.workspace_premium_rounded, color: C.gold),
                  trailing: Pill(
                    prem ? 'faol · ${dmy(s.premiumUntil!)} gacha' : '${money(premiumPrice)}/oy',
                    bg: prem ? C.good : C.ac,
                    fg: prem ? const Color(0xFF052611) : C.onAc,
                  ),
                  onTap: () => push(context, const PremiumScreen())),
              row('Ovoz',
                  leading: const Icon(Icons.record_voice_over_rounded, color: C.mut),
                  sub: 'Talaffuz uchun ovozni tanlash',
                  onTap: () => showVoiceSheet(context)),
              row('Eslatmalar',
                  leading: const Icon(Icons.notifications_active_rounded, color: C.mut),
                  sub: "08:00, 14:00, 20:00, 21:30 · bajarilgan bo'lsa kelmaydi"),
              row('Kunlik maqsad',
                  leading: const Icon(Icons.flag_rounded, color: C.mut), trailing: Pill("${s.dailyGoal} so'z")),
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
              Btn("Namuna ma'lumot qo'shish (kalendar, takrorlar)", kind: BtnKind.ghost, onTap: () {
                s.seedDemo();
                toast(context, "Namuna qo'shildi");
              }),
              const SizedBox(height: 10),
              Btn(resetSure ? 'Ishonchingiz komilmi? Yana bosing' : 'Hammasini tozalash', kind: BtnKind.ghost, onTap: () {
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
    toast(context, due > 0 ? "Eslatma: $due ta so'zni takrorlash vaqti keldi" : "$n kun o'tdi");
    ShellScope.of(context).goTab(0);
    if (s.takeSaveOffer()) push(context, const StreakScreen(todayMode: false));
  }

  Widget _stat(String v, String l) => AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(v, style: display(19)),
          Text(l, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.mut, fontSize: 12)),
        ]),
      );
}

/// Profilni tahrirlash: rasm (emoji), taxallus, kunlik maqsad, guruh, hisob, Premium.
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});
  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  static const avatars = ['🦁', '🦊', '🐼', '🐯', '🦉', '🐬', '🐨', '🦄', '🚀', '⭐', '⚡', '🎯'];
  static const goals = [10, 20, 30, 40];
  late final nick = TextEditingController(text: AppScope.read(context).nickname);
  late String avatar = AppScope.read(context).avatar;
  late int goal = AppScope.read(context).dailyGoal;
  bool saving = false;

  @override
  void dispose() {
    nick.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final n = nick.text.trim();
    if (n.isNotEmpty && (n.length < 2 || n.length > 20)) {
      toast(context, "Taxallus 2 tadan 20 tagacha harf bo'lsin");
      return;
    }
    setState(() => saving = true);
    final s = AppScope.read(context);
    s.setProfile(nick: n, avatar: avatar, goal: goal);
    final err = n.isEmpty ? null : await Cloud.saveProfile(nickname: n, avatar: avatar);
    if (!mounted) return;
    setState(() => saving = false);
    toast(context, err ?? 'Saqlandi');
    if (err == null) Navigator.of(context).pop();
  }

  Future<void> signOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hisobdan chiqasizmi?'),
        content: const Text("Yutuqlaringiz serverda saqlanib qoladi. Qayta kirsangiz hammasi qaytadi."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Yo'q")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Chiqish')),
        ],
      ),
    );
    if (ok != true) return;
    await Cloud.signOut();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      appBar: const TopBar(title: 'Profilni tahrirlash'),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(gradient: C.grad, borderRadius: BorderRadius.circular(26)),
            alignment: Alignment.center,
            child: Text(avatar, style: const TextStyle(fontSize: 46)),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
          for (final a in avatars)
            GestureDetector(
              onTap: () => setState(() => avatar = a),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: C.sf2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: a == avatar ? C.ac : Colors.transparent, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(a, style: const TextStyle(fontSize: 24)),
              ),
            ),
        ]),
        const SizedBox(height: 18),
        const Eyebrow('Taxallus'),
        const SizedBox(height: 6),
        TextField(
          controller: nick,
          maxLength: 20,
          decoration: const InputDecoration(hintText: 'Masalan: Sardor_07', counterText: ''),
        ),
        const SizedBox(height: 4),
        const Text("Ilovada shu ko'rinadi. Haqiqiy ism va telefon raqami so'ralmaydi.",
            style: TextStyle(color: C.mut, fontSize: 12)),
        const SizedBox(height: 16),
        const Eyebrow('Kunlik maqsad'),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final g in goals)
            ChoiceChip(
              label: Text("$g so'z"),
              selected: goal == g,
              selectedColor: C.ac.withValues(alpha: .25),
              onSelected: (_) => setState(() => goal = g),
            ),
        ]),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: Column(children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Hisob', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                  Cloud.signedIn
                      ? '${s.account == 'telegram' ? 'Telegram' : 'Google'} · ${s.accountLabel ?? ''}'
                      : 'Kirilmagan',
                  style: const TextStyle(color: C.mut, fontSize: 12)),
              trailing: Cloud.signedIn
                  ? null
                  : TextButton(onPressed: () => push(context, const LoginScreen()), child: const Text('Kirish')),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Premium', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(s.isPremium ? 'Faol · ${dmy(s.premiumUntil!)} gacha' : 'Faol emas',
                  style: const TextStyle(color: C.mut, fontSize: 12)),
              trailing: s.isPremium
                  ? null
                  : TextButton(onPressed: () => push(context, const PremiumScreen()), child: const Text('Olish')),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Btn(saving ? 'Saqlanmoqda…' : 'Saqlash', onTap: saving ? null : save),
        if (Cloud.signedIn) ...[
          const SizedBox(height: 10),
          Btn('Hisobdan chiqish', kind: BtnKind.ghost, onTap: signOut),
        ],
      ]),
    );
  }
}

/// Telefon bildirishnomasining ko'rinishi (sinov uchun).
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
                  Text('Olovingiz kuyyapti! 🔥', style: TextStyle(color: Color(0xFF101826), fontWeight: FontWeight.w800)),
                  Text('hozir · 20:00', style: TextStyle(color: Color(0xFF5A6577), fontSize: 11)),
                  SizedBox(height: 2),
                  Text("Iye, shashtingiz pastku? 😏 Bitta takror qiling, olov o'chmasin 🔥",
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
          Text(sub,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF3A2208), fontWeight: FontWeight.w700)),
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
      ('Cheksiz mashq', "Bepulda kuniga $freeSessions ta mashq, Premiumda cheklov yo'q"),
      ('Internetsiz ishlaydi', 'Internet bo\'lmasa ham cheklovsiz mashq qilasiz'),
      ('Olovni reklamasiz saqlash', "O'tkazib yuborilgan kun uchun reklama ko'rish shart emas"),
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
          const PayStepsText(),
          const SizedBox(height: 12),
          Btn('Telegram orqali sotib olish', kind: BtnKind.telegram, onTap: () => startPay(context, 'premium')),
        ],
      ]),
    );
  }
}

/// To'lov qadamlari (Premium va kitoblar uchun bir xil).
class PayStepsText extends StatelessWidget {
  const PayStepsText({super.key});
  @override
  Widget build(BuildContext context) {
    const steps = [
      'Telegram botimiz ochiladi',
      "Bot ko'rsatgan QR kod orqali Click bilan to'laysiz",
      'Chek rasmini (skrinshot) botga yuborasiz',
      "Administrator tasdiqlagach, Premium o'zi yoqiladi",
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final (i, t) in steps.indexed)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            CircleAvatar(
                radius: 11,
                backgroundColor: C.sf2,
                child: Text('${i + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
            const SizedBox(width: 10),
            Expanded(child: Text(t, style: const TextStyle(fontSize: 13))),
          ]),
        ),
    ]);
  }
}

/// To'lovni boshlash. Hisobga kirilmagan bo'lsa avval kirish oynasi.
Future<void> startPay(BuildContext context, String kind) async {
  final r = await Cloud.startPayment(kind);
  if (!context.mounted) return;
  if (r == 'login') {
    toast(context, "To'lov hisobingizga bog'lanishi uchun avval kiring");
    push(context, const LoginScreen());
    return;
  }
  if (r != null) {
    toast(context, r);
    return;
  }
  push(context, PayWaitScreen(kind: kind));
}

/// Botda to'lov qilingach: tasdiqlanishini kutish. Ilovaga qaytilganda server tekshiriladi.
class PayWaitScreen extends StatefulWidget {
  final String kind;
  const PayWaitScreen({super.key, required this.kind});
  @override
  State<PayWaitScreen> createState() => _PayWaitScreenState();
}

class _PayWaitScreenState extends State<PayWaitScreen> with WidgetsBindingObserver {
  bool checking = false;
  Timer? timer;

  bool done(AppState s) =>
      widget.kind == 'premium' ? s.isPremium : s.owned.contains(widget.kind.substring('book:'.length));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(seconds: 20), (_) => check(silent: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) check(silent: true);
  }

  Future<void> check({bool silent = false}) async {
    if (checking) return;
    setState(() => checking = true);
    await Cloud.sync();
    if (!mounted) return;
    setState(() => checking = false);
    if (!silent && !done(AppScope.read(context))) toast(context, 'Hali tasdiqlanmadi, birozdan keyin qayta tekshiring');
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final ok = done(s);
    if (ok) timer?.cancel();
    return Scaffold(
      appBar: const TopBar(title: "To'lov"),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        if (ok) ...[
          _Hero(widget.kind == 'premium' ? 'Premium faollashdi!' : 'Kitob ochildi!',
              widget.kind == 'premium' ? '${dmy(s.premiumUntil ?? s.td)} gacha' : 'Kitoblar bo\'limida turibdi'),
          const SizedBox(height: 16),
          Btn("O'rganishni davom ettirish", onTap: () => Navigator.of(context).popUntil((r) => r.isFirst)),
        ] else ...[
          const AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Telegram botda davom eting', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              SizedBox(height: 10),
              PayStepsText(),
            ]),
          ),
          const SizedBox(height: 12),
          Btn(checking ? 'Tekshirilmoqda…' : 'Tasdiqlandimi? Tekshirish', onTap: checking ? null : () => check()),
          const SizedBox(height: 8),
          const Text("Tasdiqlangach bot sizga xabar yuboradi. Odatda bir necha daqiqa ichida.",
              textAlign: TextAlign.center, style: TextStyle(color: C.mut, fontSize: 12)),
        ],
      ]),
    );
  }
}
