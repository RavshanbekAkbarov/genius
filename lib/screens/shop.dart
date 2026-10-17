import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../state/scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home.dart';
import 'profile.dart';
import 'shell.dart';

/// Do'kon: Genius Premium va pullik markaz kitoblari. Essential kitoblari doim bepul.
class ShopTab extends StatelessWidget {
  const ShopTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final center = booksOf(BookGroup.center).where((b) => b.paid).toList();
    return ListView(padding: EdgeInsets.zero, children: [
      const TabHeader(title: "Do'kon", subtitle: 'Premium va markaz kitoblari'),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (s.isPremium)
            AppCard(
              border: C.gold,
              child: Row(children: [
                const Icon(Icons.workspace_premium_rounded, color: C.gold, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Premium faol · ${dmy(s.premiumUntil!)} gacha',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ]),
            )
          else
            PremiumPromo(onTap: () => push(context, const PremiumScreen())),
          const SizedBox(height: 18),
          Text('Markaz kitoblari', style: display(17)),
          const SizedBox(height: 4),
          const Text("Aura Academy kitoblari. 4000 Essential Words kitoblari bepul.",
              style: TextStyle(color: C.mut, fontSize: 13)),
          const SizedBox(height: 12),
          if (center.isEmpty) const EmptyBox('Markaz kitoblari tez orada shu yerda chiqadi.'),
          for (final b in center) ...[
            AppCard(
              child: Row(children: [
                BookCover(badge: b.badge, title: b.title, gradient: b.gradient),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(b.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text("${b.fixedUnits} unit · ${b.fixedUnits * 20} so'z",
                        style: const TextStyle(color: C.mut, fontSize: 12)),
                    const SizedBox(height: 10),
                    if (s.owned.contains(b.id))
                      const Pill('Sizda bor', bg: C.good, fg: Color(0xFF052611))
                    else
                      Btn("${money(b.price)} so'm · Sotib olish",
                          kind: BtnKind.telegram, onTap: () => showBookBuySheet(context, b)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 12),
          ],
        ]),
      ),
    ]);
  }
}

/// Pullik markaz kitobini sotib olish: to'lov Telegram bot orqali.
void showBookBuySheet(BuildContext context, Book b) {
  showModalBottomSheet(
    context: context,
    backgroundColor: C.sf,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          BookBadge(b, size: 28),
          const SizedBox(width: 10),
          Expanded(child: Text(b.title, style: display(17))),
          Text("${money(b.price)} so'm", style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 12),
        const PayStepsText(),
        const SizedBox(height: 14),
        Btn("Telegram orqali sotib olish", kind: BtnKind.telegram, onTap: () {
          Navigator.pop(ctx);
          startPay(context, 'book:${b.id}');
        }),
        const SizedBox(height: 6),
        Btn('Bekor qilish', kind: BtnKind.text, onTap: () => Navigator.pop(ctx)),
      ]),
    ),
  );
}
