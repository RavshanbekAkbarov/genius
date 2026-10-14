import 'dart:math';

import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../state/app_state.dart';
import '../state/scope.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Takror jadvali: har unit uchun 1·3·7·15·30 bosqichlari.
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final g = <String, List<Prog>>{};
    s.prog.forEach((k, p) {
      if (!p.learned) return;
      final parts = k.split('|');
      g.putIfAbsent('${parts[0]}|${parts[1]}', () => []).add(p);
    });
    final next = [for (var n = 1; n <= 3; n++) (addDays(s.today, n), s.dueOn(addDays(s.today, n)))]
        .where((e) => e.$2 > 0)
        .toList();
    final dueNow = s.dueKeys.length;
    return Scaffold(
      appBar: const TopBar(title: 'Takror jadvali', subtitle: '1 · 3 · 7 · 15 · 30 kun'),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
          const Text('Bugun:', style: TextStyle(color: C.mut, fontSize: 13)),
          Pill("$dueNow so'z", bg: dueNow > 0 ? C.bad : C.sf2, fg: dueNow > 0 ? const Color(0xFF2A0606) : C.fg),
          const SizedBox(width: 6),
          const Text('Keyingi:', style: TextStyle(color: C.mut, fontSize: 13)),
          if (next.isEmpty) const Text("3 kun ichida yo'q", style: TextStyle(color: C.mut, fontSize: 13)),
          for (final e in next) Pill("${e.$1.day} ${months[e.$1.month - 1]} · ${e.$2} so'z"),
        ]),
        const SizedBox(height: 14),
        if (g.isEmpty) const EmptyBox("Hali yodlangan so'z yo'q. Bitta unitni kartalarda yodlang."),
        for (final e in g.entries) ...[
          Builder(builder: (_) {
            final parts = e.key.split('|');
            final ps = e.value;
            final st = ps.map((p) => p.stage).reduce(min);
            final dd = (ps.map((p) => p.due).toList()..sort()).first;
            return AppCard(
              child: Column(children: [
                Row(children: [
                  BookBadge(bookById(parts[0]), size: 20),
                  const SizedBox(width: 9),
                  Expanded(child: Text('Unit ${parts[1]}', style: const TextStyle(fontWeight: FontWeight.w800))),
                  Text("${ps.length} so'z", style: const TextStyle(color: C.mut, fontSize: 12)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  for (var i = 0; i < intervals.length; i++)
                    Expanded(child: _chip(i < st ? 'done' : (i == st && dd.compareTo(s.td) < 0 ? 'miss' : (i == st && dd == s.td ? 'today' : '')), i < st ? '✓' : '${intervals[i]}')),
                ]),
              ]),
            );
          }),
          const SizedBox(height: 10),
        ],
        if (g.isNotEmpty)
          Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            SizedBox(width: 36, child: _chip('done', '✓')),
            const Text('bajarildi', style: TextStyle(color: C.mut, fontSize: 12)),
            SizedBox(width: 36, child: _chip('today', '3')),
            const Text('bugun', style: TextStyle(color: C.mut, fontSize: 12)),
            SizedBox(width: 36, child: _chip('miss', '3')),
            const Text("o'tkazib yuborildi", style: TextStyle(color: C.mut, fontSize: 12)),
          ]),
      ]),
    );
  }

  Widget _chip(String kind, String text) {
    final (bg, fg) = switch (kind) {
      'done' => (C.good, const Color(0xFF052611)),
      'today' => (C.ac, C.onAc),
      'miss' => (C.bad, const Color(0xFF2A0606)),
      _ => (C.sf2, C.mut),
    };
    return Container(
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
      alignment: Alignment.center,
      child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 13)),
    );
  }
}
