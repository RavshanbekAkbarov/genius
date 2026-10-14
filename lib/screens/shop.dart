import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../state/scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home.dart';
import 'profile.dart';
import 'shell.dart';

/// Do'kon: IELTS kitoblarini o'qish va ularning so'zlari alohida, ikkalasi birga arzonroq.
class ShopTab extends StatelessWidget {
  const ShopTab({super.key});

  void buySheet(BuildContext context, IeltsBook b, String kind, int price) {
    final s = AppScope.read(context);
    if (s.owned.contains('${b.id}:$kind')) {
      toast(context, 'Bu allaqachon sizda bor');
      return;
    }
    final what = {'read': "Kitobni o'qish", 'words': "So'zlarni kartaga qo'shish", 'both': "Kitob + so'zlar"}[kind]!;
    showModalBottomSheet(
      context: context,
      backgroundColor: C.sf,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('${b.title} · $what', style: display(17)),
          const SizedBox(height: 12),
          _priceRow('Narxi', "${money(price)} so'm"),
          const SizedBox(height: 10),
          const Text(
              "To'lov Telegram botimiz orqali Click yoki Payme bilan qilinadi. To'lagandan keyin shu yerda o'zi ochiladi.",
              style: TextStyle(color: C.mut, fontSize: 13)),
          const SizedBox(height: 14),
          Btn("Telegram bot orqali to'lash", kind: BtnKind.telegram, onTap: () {
            s.buy(b.id, kind);
            Navigator.pop(ctx);
            toast(context, "To'landi (demo)");
          }),
          const SizedBox(height: 10),
          Btn('Bekor qilish', kind: BtnKind.ghost, onTap: () => Navigator.pop(ctx)),
          const SizedBox(height: 8),
          const Text("Hozircha to'lov o'xshatiladi, pul olinmaydi.",
              textAlign: TextAlign.center, style: TextStyle(color: C.mut, fontSize: 11)),
        ]),
      ),
    );
  }

  static Widget _priceRow(String l, String v, {bool best = false, bool owned = false, String? tag}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: C.sf2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: owned ? C.good : (best ? C.ac : Colors.transparent), width: 1.5),
        ),
        child: Row(children: [
          Expanded(
            child: Row(children: [
              Flexible(child: Text(l, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
              if (tag != null) ...[const SizedBox(width: 6), Pill(tag, bg: C.ac.withValues(alpha: .25), fg: C.ac)],
            ]),
          ),
          Text(v, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: owned ? C.good : C.fg)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return ListView(padding: EdgeInsets.zero, children: [
      const TabHeader(title: "Do'kon", subtitle: 'IELTS kitoblari'),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text("Kitobni o'qish va undagi so'zlarni kartalarga qo'shish alohida sotiladi. Ikkalasi birga arzonroq.",
              style: TextStyle(color: C.mut, fontSize: 13)),
          const SizedBox(height: 12),
          for (final b in ieltsBooks) ...[
            AppCard(
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                BookCover(badge: b.badge, title: b.title, gradient: b.gradient),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(b.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 7),
                    for (final (k, l, p) in [
                      ('read', "Kitobni o'qish", b.readPrice),
                      ('words', "So'zlarni kartaga", b.wordsPrice),
                      ('both', 'Ikkalasi', b.bothPrice),
                    ]) ...[
                      GestureDetector(
                        onTap: () => buySheet(context, b, k, p),
                        child: _priceRow(l, s.owned.contains('${b.id}:$k') ? 'Sotib olingan' : "${money(p)} so'm",
                            best: k == 'both',
                            owned: s.owned.contains('${b.id}:$k'),
                            tag: k == 'both' ? '−${money(b.readPrice + b.wordsPrice - b.bothPrice)}' : null),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 12),
          ],
          Material(
            color: C.sf,
            borderRadius: BorderRadius.circular(20),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              leading: const Icon(Icons.workspace_premium_rounded, color: C.gold),
              title: const Text('Genius Premium', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text("Reklamasiz, cheksiz mashq · ${money(premiumPrice)} so'm/oy",
                  style: const TextStyle(color: C.mut, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right_rounded, color: C.mut),
              onTap: () => push(context, const PremiumScreen()),
            ),
          ),
        ]),
      ),
    ]);
  }
}
