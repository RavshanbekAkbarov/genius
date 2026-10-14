import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../state/scope.dart';
import '../theme.dart';
import 'shell.dart';

/// Reyting: eng ko'p so'z yodlaganlar (bugun / hafta / oy / umumiy).
class RatingTab extends StatefulWidget {
  const RatingTab({super.key});
  @override
  State<RatingTab> createState() => _RatingTabState();
}

class _RatingTabState extends State<RatingTab> {
  int per = 1;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final rows = [
      for (final p in samplePeople) (name: p.$1, v: p.$2[per], me: false),
      (name: s.name.split(' ').first, v: s.myScore(per), me: true),
    ]..sort((a, b) => b.v.compareTo(a.v));
    final medal = [const Color(0xFFFFD34D), const Color(0xFFCFD6E0), const Color(0xFFE2A36B)];
    return ListView(padding: EdgeInsets.zero, children: [
      TabHeader(
        title: 'Reyting',
        subtitle: "Eng ko'p so'z yodlaganlar",
        bottom: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            for (final (i, l) in ['Bugun', 'Hafta', 'Oy', 'Umumiy'].indexed)
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => per = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                        color: per == i ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(11)),
                    alignment: Alignment.center,
                    child: Text(l,
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13, color: per == i ? C.onAc : Colors.white)),
                  ),
                ),
              ),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(children: [
          for (final (i, r) in rows.indexed)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: C.sf,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: r.me ? C.ac : C.ln, width: r.me ? 1.5 : 1),
              ),
              child: Row(children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: i < 3 ? medal[i] : C.sf2),
                  alignment: Alignment.center,
                  child: Text('${i + 1}',
                      style: TextStyle(fontWeight: FontWeight.w800, color: i < 3 ? const Color(0xFF1A1200) : C.mut)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(r.me ? '${r.name} (siz)' : r.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                      if (r.me && s.isPremium) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.workspace_premium_rounded, color: C.gold, size: 18),
                      ],
                    ]),
                    if (r.me && i > 0)
                      Text("Keyingi o'ringa ${rows[i - 1].v - r.v + 1} so'z qoldi",
                          style: const TextStyle(color: C.mut, fontSize: 12)),
                  ]),
                ),
                Text("${r.v} so'z", style: const TextStyle(fontWeight: FontWeight.w800)),
              ]),
            ),
          const SizedBox(height: 4),
          const Text('Boshqa ismlar namuna. Haqiqiy reyting serverdan keladi.',
              textAlign: TextAlign.center, style: TextStyle(color: C.mut, fontSize: 12)),
        ]),
      ),
    ]);
  }
}
