import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../state/app_state.dart';
import '../state/scope.dart';
import '../theme.dart';
import 'common.dart';

/// Faollik kalendari: har ustun bitta hafta, har kun bitta katak (ichida sana).
/// Qancha ko'p o'qilsa, shuncha to'q yashil. Kunni bosganda o'sha kun tafsiloti ochiladi.
class ActivityCalendar extends StatefulWidget {
  final String title;
  const ActivityCalendar({super.key, this.title = 'Faollik kalendari'});
  @override
  State<ActivityCalendar> createState() => _ActivityCalendarState();
}

class _ActivityCalendarState extends State<ActivityCalendar> {
  final scroll = ScrollController();
  static const cell = 30.0, gap = 4.0, weeksBack = 30, weeksAhead = 3;
  bool scrolled = false;

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  Color color(AppState s, int n) {
    if (n <= 0) return C.heat[0];
    final r = n / s.dailyGoal;
    return C.heat[r < .25 ? 1 : r < .6 ? 2 : r < 1 ? 3 : 4];
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = s.today;
    final mon = addDays(t, -(t.weekday - 1));
    final start = addDays(mon, -7 * weeksBack);
    const weeks = weeksBack + 1 + weeksAhead;
    if (!scrolled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!scroll.hasClients) return;
        scrolled = true;
        final target = (weeksBack * (cell + gap) - scroll.position.viewportDimension + 3 * (cell + gap))
            .clamp(0.0, scroll.position.maxScrollExtent);
        scroll.jumpTo(target);
      });
    }
    final cols = <Widget>[];
    for (var w = 0; w < weeks; w++) {
      final first = addDays(start, w * 7);
      final showM = w == 0 || first.month != addDays(first, -7).month;
      final cells = <Widget>[
        SizedBox(
          height: 16,
          width: cell,
          child: Text(showM ? months[first.month - 1] : '',
              softWrap: false, overflow: TextOverflow.visible, style: const TextStyle(fontSize: 11, color: C.mut)),
        ),
      ];
      for (var d = 0; d < 7; d++) {
        final day = addDays(first, d);
        final fut = day.isAfter(t);
        final n = s.log[ds(day)] ?? 0;
        final savedDay = s.saved.contains(ds(day));
        final planned = fut && s.dueOn(day) > 0;
        final bg = fut ? C.sf2.withValues(alpha: .5) : (savedDay && n == 0 ? C.gold.withValues(alpha: .5) : color(s, n));
        cells.add(Padding(
          padding: const EdgeInsets.only(top: gap),
          child: Semantics(
            button: true,
            label: dayLabel(day),
            child: GestureDetector(
              onTap: () => showDaySheet(context, day),
              child: Container(
                width: cell,
                height: cell,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(7),
                  border: day == t
                      ? Border.all(color: C.ac, width: 2)
                      : (planned ? Border.all(color: C.ac.withValues(alpha: .5)) : null),
                ),
                alignment: Alignment.center,
                child: Text('${day.day}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: n > 0 && !fut ? Colors.white : C.mut.withValues(alpha: fut ? .6 : 1))),
              ),
            ),
          ),
        ));
      }
      cols.add(Padding(padding: const EdgeInsets.only(right: gap), child: Column(children: cells)));
    }
    final activeDays = s.log.entries.where((e) => e.value > 0 && e.key.startsWith('${t.year}')).length;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionTitle(widget.title, note: '${t.year} · $activeDays faol kun'),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            const SizedBox(height: 16),
            for (final w in weekdays)
              Container(
                height: cell,
                margin: const EdgeInsets.only(top: gap),
                padding: const EdgeInsets.only(right: 6),
                alignment: Alignment.centerLeft,
                child: Text(w, style: const TextStyle(fontSize: 11, color: C.mut, fontWeight: FontWeight.w700)),
              ),
          ]),
          Expanded(
            child: SingleChildScrollView(
              controller: scroll,
              scrollDirection: Axis.horizontal,
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: cols),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        const Text("Kunni bosing: o'sha kuni nima qilinganini ko'rasiz",
            style: TextStyle(fontSize: 12, color: C.mut)),
      ]),
    );
  }
}

/// Bitta kunning tafsiloti. O'tgan kun: yodlangan unitlar, takrorlar, mashqlar.
/// Kelgusi kun: rejadagi takrorlar.
Future<void> showDaySheet(BuildContext context, DateTime day) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: C.sf,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .6,
        maxChildSize: .92,
        builder: (ctx, sc) => _DaySheet(day: day, scroll: sc),
      ),
    );

class _DaySheet extends StatelessWidget {
  final DateTime day;
  final ScrollController scroll;
  const _DaySheet({required this.day, required this.scroll});

  String unitName(String uk) {
    final p = uk.split('|');
    return '${bookById(p[0]).title} · Unit ${p[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = s.today;
    final fut = day.isAfter(t);
    final isToday = day == t;
    final d = s.dayOf(day);
    final pending = s.plannedOn(day);
    final children = <Widget>[
      Center(
        child: Container(
            width: 40, height: 4, decoration: BoxDecoration(color: C.ln, borderRadius: BorderRadius.circular(2))),
      ),
      const SizedBox(height: 14),
      Text(dayLabel(day), style: display(18)),
      const SizedBox(height: 4),
      Text(fut ? 'Rejadagi takrorlar' : (isToday ? 'Bugun' : "O'sha kuni nima qilingan"),
          style: const TextStyle(color: C.mut, fontSize: 13)),
      const SizedBox(height: 14),
    ];
    Widget line(IconData icon, Color c, String title, String? sub) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: C.sf2, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Icon(icon, color: c, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  if (sub != null) Text(sub, style: const TextStyle(color: C.mut, fontSize: 12)),
                ]),
              ),
            ]),
          ),
        );
    if (fut) {
      if (pending.isEmpty) {
        children.add(const EmptyBox('Bu kunga takror rejalashtirilmagan.'));
      } else {
        for (final g in pending) {
          children.add(line(Icons.event_repeat_rounded, C.ac, unitName(ukey(g.book, g.unit)),
              "${intervals[g.stage]}-kun takrori · ${g.keys.length} so'z"));
        }
        children.add(const Text("Oldingi kunlardan qolgan takrorlar ham shu kuni chiqadi.",
            style: TextStyle(color: C.mut, fontSize: 12)));
      }
    } else {
      final acc = d?.accuracy;
      children.add(Row(children: [
        Expanded(child: _stat('${d?.newWords ?? 0}', "yangi so'z")),
        const SizedBox(width: 8),
        Expanded(child: _stat('${d?.reviewWords ?? 0}', 'takrorlandi')),
        const SizedBox(width: 8),
        Expanded(child: _stat('${d?.sessions ?? 0}', 'mashq')),
        const SizedBox(width: 8),
        Expanded(child: _stat(acc == null ? '–' : '$acc%', 'aniqlik')),
      ]));
      children.add(const SizedBox(height: 14));
      if (d != null && d.newUnits.isNotEmpty) {
        children.add(const Eyebrow('Yodlangan unitlar'));
        children.add(const SizedBox(height: 8));
        for (final uk in d.newUnits) {
          final p = uk.split('|');
          final u = int.parse(p[1]);
          final w = s.words(p[0], u).length;
          children.add(line(Icons.menu_book_rounded, C.good, unitName(uk),
              "${s.unitLearned(p[0], u)}/$w so'z yodlangan${s.unitDone(p[0], u) ? ' · tugagan' : ''}"));
        }
        children.add(const SizedBox(height: 6));
      }
      final done = d?.reviewUnits ?? <String>{};
      final missed = pending.where((g) => !done.contains(ukey(g.book, g.unit))).toList();
      if (done.isNotEmpty || missed.isNotEmpty) {
        children.add(const Eyebrow('Takrorlar'));
        children.add(const SizedBox(height: 8));
        for (final uk in done) {
          final lateOn = d!.lateUnits[uk];
          children.add(line(Icons.check_circle_rounded, C.good, unitName(uk),
              lateOn == null ? 'bajarildi' : 'kechikib bajarildi: ${shortDate(DateTime.parse(lateOn))}'));
        }
        for (final g in missed) {
          children.add(line(isToday ? Icons.schedule_rounded : Icons.cancel_rounded, isToday ? C.ac : C.bad,
              unitName(ukey(g.book, g.unit)), isToday ? 'kutilmoqda' : "bajarilmagan · bugungi takrorlarda turibdi"));
        }
      }
      if (s.saved.contains(ds(day))) {
        children.add(line(Icons.local_fire_department_rounded, C.gold, 'Olov saqlangan', 'reklama yoki Premium bilan'));
      }
      if ((d == null || d.empty) && missed.isEmpty && !s.saved.contains(ds(day))) {
        children.add(EmptyBox(isToday ? "Bugun hali mashq qilinmadi." : 'Bu kuni mashq qilinmagan.'));
      }
    }
    return ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(16, 10, 16, 24), children: children);
  }

  Widget _stat(String v, String l) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(color: C.sf2, borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Text(v, style: display(17)),
          const SizedBox(height: 2),
          Text(l, textAlign: TextAlign.center, style: const TextStyle(color: C.mut, fontSize: 11)),
        ]),
      );
}
