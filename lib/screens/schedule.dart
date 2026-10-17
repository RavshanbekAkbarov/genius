import 'dart:math';

import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../state/app_state.dart';
import '../state/scope.dart';
import '../theme.dart';
import '../widgets/calendar.dart';
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
    final dueNow = s.dueKeys.length;
    return Scaffold(
      appBar: const TopBar(title: 'Takror jadvali', subtitle: '1 · 3 · 7 · 15 · 30 kun'),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        Row(children: [
          const Text('Bugun:', style: TextStyle(color: C.mut, fontSize: 13)),
          const SizedBox(width: 6),
          Pill("$dueNow so'z", bg: dueNow > 0 ? C.bad : C.sf2, fg: dueNow > 0 ? const Color(0xFF2A0606) : C.fg),
        ]),
        const SizedBox(height: 12),
        const Eyebrow('Kunlar (bosing: tafsilot)'),
        const SizedBox(height: 8),
        Row(children: [
          for (var n = -3; n <= 3; n++)
            Expanded(child: Builder(builder: (_) {
              final d = addDays(s.today, n);
              final done = s.dayOf(d)?.reviewUnits.length ?? 0;
              final plan = s.plannedOn(d).length;
              return GestureDetector(
                onTap: () => showDaySheet(context, d),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: C.sf2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: n == 0 ? C.ac : Colors.transparent, width: 1.5),
                  ),
                  child: Column(children: [
                    Text(weekdays[d.weekday - 1], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    Text('${d.day}', style: const TextStyle(fontSize: 12, color: C.mut)),
                    const SizedBox(height: 4),
                    Text(done > 0 ? '✓$done' : (plan > 0 ? '$plan' : '·'),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: done > 0 ? C.good : (plan > 0 ? (n < 0 ? C.bad : C.ac) : C.mut))),
                  ]),
                ),
              );
            })),
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
                  Flexible(
                    child: Text(
                        st >= intervals.length
                            ? "${ps.length} so'z · mustahkam"
                            : "${ps.length} so'z · keyingi: ${shortDate(DateTime.parse(dd))}",
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: C.mut, fontSize: 12)),
                  ),
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
