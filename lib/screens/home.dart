import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/words.dart';
import '../services/speech.dart';
import '../state/app_state.dart';
import '../state/scope.dart';
import '../theme.dart';
import '../widgets/add_word_sheet.dart';
import '../widgets/common.dart';
import 'books.dart';
import 'schedule.dart';
import 'setup.dart';
import 'shell.dart';
import 'streak.dart';
import 'study.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final search = TextEditingController();
  String q = '';

  @override
  void initState() {
    super.initState();
    // Kecha o'tkazib yuborilgan bo'lsa: olovni saqlash taklifi (kuniga bir marta).
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkStreak());
  }

  void _checkStreak() {
    if (!mounted) return;
    final s = AppScope.read(context);
    if (s.takeSaveOffer()) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StreakScreen(todayMode: false)));
    }
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final b = bookById(s.currentBook);
    return CustomScrollView(slivers: [
      SliverToBoxAdapter(child: _header(s, b)),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        sliver: SliverList.list(children: [
          if (q.isNotEmpty) ...[_searchResults(s), const SizedBox(height: 14)],
          if (s.eveningWarning) ...[_eveningWarn(s), const SizedBox(height: 14)],
          _learnCard(s, b),
          const SizedBox(height: 12),
          _practiceCard(s, b),
          const SizedBox(height: 18),
          SectionTitle('Bugungi takrorlar', action: 'Jadval', onAction: () => push(context, const ScheduleScreen())),
          const SizedBox(height: 10),
          ..._dueList(s),
          const SizedBox(height: 14),
          const WeekCard(),
          const SizedBox(height: 18),
          SectionTitle('4000 Essential Words', action: 'Hammasi', onAction: () => ShellScope.of(context).goTab(1)),
          const SizedBox(height: 10),
          _shelf(books.where((b) => b.group == BookGroup.essential).toList(), s),
          const SizedBox(height: 18),
          const SectionTitle('Markaz kitoblari'),
          const SizedBox(height: 10),
          _shelf([...books.where((b) => b.group == BookGroup.center), bookById(myBookId)], s),
          const SizedBox(height: 18),
          const ActivityHeatmap(),
          const SizedBox(height: 18),
          SectionTitle('IELTS kitoblari', action: "Do'kon", onAction: () => ShellScope.of(context).goTab(3)),
          const SizedBox(height: 10),
          SizedBox(
            height: 124,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final ib in ieltsBooks) ...[
                BookCover(
                  badge: ib.badge,
                  title: ib.title,
                  gradient: ib.gradient,
                  corner: s.owned.contains('${ib.id}:read') ? null : 'Pullik',
                  onTap: () => ShellScope.of(context).goTab(3),
                ),
                const SizedBox(width: 12),
              ]
            ]),
          ),
        ]),
      ),
    ]);
  }

  Widget _header(AppState s, Book b) {
    return Container(
      decoration: const BoxDecoration(
        gradient: C.grad,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 14, 16, 16),
      child: Column(children: [
        Row(children: [
          BurgerButton(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Genius', style: display(22, color: Colors.white)),
              const Text('AURA ACADEMY',
                  style: TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: Colors.white70)),
            ]),
          ),
          Semantics(label: '${b.title}: ${s.bookPct(b.id)}% yodlangan', child: BookBadge(b, size: 30)),
          const SizedBox(width: 10),
          PctRing(s.bookPct(b.id)),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: search,
          onChanged: (v) => setState(() => q = v.trim().toLowerCase()),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "So'z qidirish",
            hintStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.search, color: Colors.white),
            suffixIcon: q.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => setState(() {
                          search.clear();
                          q = '';
                        })),
            fillColor: Colors.black26,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.white54)),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: _glass(
              onTap: () => showAddWordSheet(context),
              child: Row(children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: C.gold, borderRadius: BorderRadius.circular(10)),
                  alignment: Alignment.center,
                  child: const Text('+',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF241800), height: 1)),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text("So'z qo'shish",
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
                    Text("Mening so'zlarim · ${s.myWords.length} so'z",
                        style: const TextStyle(fontSize: 11, color: Colors.white70)),
                  ]),
                ),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          _glass(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.local_fire_department_rounded, color: C.gold, size: 22),
              const SizedBox(width: 6),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${s.streak}', style: display(22, color: Colors.white, weight: FontWeight.w700)),
                const Text('kun', style: TextStyle(fontSize: 10, color: Colors.white70)),
              ]),
            ]),
          ),
        ]),
      ]),
    );
  }

  Widget _glass({required Widget child, VoidCallback? onTap}) => Material(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8), child: child),
        ),
      );

  Widget _eveningWarn(AppState s) => AppCard(
        color: Color.alphaBlend(C.bad.withValues(alpha: .12), C.sf),
        border: C.bad,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Row(children: [
            Icon(Icons.local_fire_department_rounded, color: C.bad),
            SizedBox(width: 8),
            Text('Olovingiz kuyadi!', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ]),
          const SizedBox(height: 6),
          Text(
              "Bugun hali so'z yodlamadingiz va takrorlamadingiz. ${s.streak} kunlik olovni yo'qotmaslik uchun hozir mashq qiling yoki 3 ta reklama ko'rib saqlab qoling.",
              style: const TextStyle(color: C.mut, fontSize: 13)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: Btn('Mashq qilish', onTap: () => openSetup(context, s.currentBook))),
            const SizedBox(width: 10),
            Expanded(
                child: Btn('Reklama bilan saqlash',
                    kind: BtnKind.ghost, onTap: () => push(context, const StreakScreen(todayMode: true)))),
          ]),
        ]),
      );

  Widget _learnCard(AppState s, Book b) {
    final u = s.nextUnit(b.id);
    return Material(
      color: C.sf,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => push(context, UnitsScreen(bookId: b.id)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: C.ln)),
          child: Row(children: [
            BookBadge(b, size: 34),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("O'rganish", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                Text('${b.title} · ${u != null ? 'Unit $u dan davom eting' : 'barcha unitlar'}',
                    style: const TextStyle(color: C.mut, fontSize: 12)),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                      value: s.bookPct(b.id) / 100, minHeight: 6, color: C.good, backgroundColor: C.sf2),
                ),
              ]),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: C.mut),
          ]),
        ),
      ),
    );
  }

  Widget _practiceCard(AppState s, Book b) {
    return Material(
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: const BoxDecoration(gradient: C.grad),
        child: InkWell(
          onTap: () => openSetup(context, b.id),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.style_rounded, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Kartalarda yodlash',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
                  Text(
                      '${b.title} · kartalar yoki yozish${s.isPremium ? '' : ' · bugun ${s.sessionsLeft}/$freeSessions mashq'}',
                      style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 30),
            ]),
          ),
        ),
      ),
    );
  }

  List<Widget> _dueList(AppState s) {
    final due = s.dueGroups;
    if (due.isEmpty) {
      return const [
        EmptyBox("Bugun takrorlash yo'q. Yodlagan so'zlaringiz 1, 3, 7, 15 va 30 kundan keyin shu yerda chiqadi.")
      ];
    }
    return [
      for (final g in due)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: FillRow(
            leading: BookBadge(bookById(g.book), size: 24),
            title: 'Unit ${g.unit}',
            subtitle: "${intervals[g.stage]}-kun takrori · ${g.keys.length} so'z",
            trailing: '',
            onTap: () {
              final list = s.reviewCards(g.book, g.unit);
              if (list.isNotEmpty) startSession(context, list, review: true);
            },
          ).withChip(g.late ? const Pill('kechikdi', bg: C.bad, fg: Color(0xFF2A0606)) : const Pill('bugun', bg: C.ac, fg: C.onAc)),
        ),
    ];
  }

  Widget _shelf(List<Book> list, AppState s) => SizedBox(
        height: 136,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final b in list) ...[
            BookCover(
              badge: b.badge,
              title: b.title,
              gradient: b.gradient,
              corner: b.isMine ? "${s.myWords.length} so'z" : null,
              progress: s.bookPct(b.id) / 100,
              onTap: () => b.isMine ? push(context, UnitsScreen(bookId: b.id)) : openSetup(context, b.id),
            ),
            const SizedBox(width: 12),
          ]
        ]),
      );

  Widget _searchResults(AppState s) {
    final hits = <(String, int, int, Word)>[];
    WordBank.all.forEach((key, list) {
      final p = key.split('|');
      for (var i = 0; i < list.length; i++) {
        final w = list[i];
        if (w.en.toLowerCase().contains(q) || w.uz.toLowerCase().contains(q)) hits.add((p[0], int.parse(p[1]), i, w));
      }
    });
    for (var j = 0; j < s.myWords.length; j++) {
      final w = s.myWords[j];
      if (w.en.toLowerCase().contains(q) || w.uz.toLowerCase().contains(q)) hits.add((myBookId, j ~/ 20 + 1, j % 20, w));
    }
    final exact = hits.any((h) => h.$4.en.toLowerCase() == q || h.$4.uz.toLowerCase().contains(q));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (hits.isEmpty) EmptyBox('"$q" topilmadi.'),
      for (final h in hits.take(12))
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: WordRow(
            word: h.$4,
            learned: s.learned(wkey(h.$1, h.$2, h.$3)),
            note: '${bookById(h.$1).title} · Unit ${h.$2}',
          ),
        ),
      if (!exact) ...[
        const SizedBox(height: 4),
        Btn("★ \"$q\" ni Mening so'zlarimga qo'shish",
            kind: BtnKind.ghost, onTap: () => showAddWordSheet(context, prefillEn: q)),
      ],
    ]);
  }
}

extension _WithChip on FillRow {
  Widget withChip(Widget chip) => Stack(alignment: Alignment.centerRight, children: [
        this,
        Positioned(right: 14, child: IgnorePointer(child: chip)),
      ]);
}

/// So'z qatori: bosilsa talaffuz qilinadi.
class WordRow extends StatelessWidget {
  final Word word;
  final bool learned;
  final String? note;
  final Widget? extra;
  final Widget? trailing;
  const WordRow({super.key, required this.word, this.learned = false, this.note, this.extra, this.trailing});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: C.sf,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Speech.speak(word.en),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: C.ln)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 10),
              child: Icon(Icons.circle, size: 9, color: learned ? C.good : C.ln),
            ),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text.rich(TextSpan(children: [
                  TextSpan(text: word.en, style: const TextStyle(color: C.ac, fontWeight: FontWeight.w800, fontSize: 15)),
                  if (word.ipa.isNotEmpty)
                    TextSpan(text: '  ${word.ipa}', style: const TextStyle(color: C.mut, fontSize: 12)),
                ])),
                Text(word.uz),
                if (word.ex.isNotEmpty) Text(word.ex, style: const TextStyle(color: C.mut, fontSize: 12)),
                if (note != null) Text(note!, style: const TextStyle(color: C.mut, fontSize: 12)),
                if (extra != null) ...[const SizedBox(height: 6), extra!],
              ]),
            ),
            const Icon(Icons.volume_up_rounded, color: C.ac, size: 20),
            if (trailing != null) ...[const SizedBox(width: 6), trailing!],
          ]),
        ),
      ),
    );
  }
}

class WeekCard extends StatelessWidget {
  const WeekCard({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = s.today;
    final mon = addDays(t, -(t.weekday - 1));
    return AppCard(
      child: Column(children: [
        const SectionTitle('Shu hafta', note: "kuniga $dailyGoal so'z"),
        const SizedBox(height: 12),
        Row(children: [
          for (var i = 0; i < 7; i++)
            Expanded(child: Builder(builder: (_) {
              final d = addDays(mon, i);
              final c = s.log[ds(d)] ?? 0;
              final p = d.isAfter(t) ? 0 : (c / dailyGoal * 100).clamp(0, 100).round();
              final isToday = d == t;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: C.sf2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isToday ? C.ac : Colors.transparent, width: 1.5),
                ),
                child: Column(children: [
                  Text(weekdays[i], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Container(
                    width: 8,
                    height: 34,
                    decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(4)),
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: p / 100,
                      child: Container(decoration: BoxDecoration(color: C.good, borderRadius: BorderRadius.circular(4))),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('$p%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                ]),
              );
            })),
        ]),
      ]),
    );
  }
}

/// Faollik jadvali: joriy yilning yanvaridan dekabrigacha.
class ActivityHeatmap extends StatefulWidget {
  const ActivityHeatmap({super.key});
  @override
  State<ActivityHeatmap> createState() => _ActivityHeatmapState();
}

class _ActivityHeatmapState extends State<ActivityHeatmap> {
  final scroll = ScrollController();
  static const cell = 12.0, gap = 3.0;

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  int lv(int n) => n == 0 ? 0 : n < 5 ? 1 : n < 10 ? 2 : n < 20 ? 3 : 4;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = s.today;
    final j1 = DateTime(t.year, 1, 1);
    final start = addDays(j1, -(j1.weekday - 1));
    final end = DateTime(t.year, 12, 31);
    final weeks = ((end.difference(start).inDays + 1) / 7).ceil();
    final curW = t.difference(start).inDays ~/ 7;
    var activeDays = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients && scroll.offset == 0) {
        final target = (curW * (cell + gap) - scroll.position.viewportDimension / 2)
            .clamp(0.0, scroll.position.maxScrollExtent);
        scroll.jumpTo(target);
      }
    });
    final cols = <Widget>[];
    final labels = <Widget>[];
    var lastM = -1;
    for (var w = 0; w < weeks; w++) {
      final wEnd = addDays(start, w * 7 + 6);
      final showM = wEnd.month - 1 != lastM && wEnd.day <= 7 && wEnd.year == t.year;
      if (wEnd.day <= 7) lastM = wEnd.month - 1;
      labels.add(SizedBox(
        width: cell + gap,
        child: Text(showM ? months[wEnd.month - 1] : '',
            softWrap: false, overflow: TextOverflow.visible, style: const TextStyle(fontSize: 10, color: C.mut)),
      ));
      final cells = <Widget>[];
      for (var d = 0; d < 7; d++) {
        final day = addDays(start, w * 7 + d);
        final inYear = day.year == t.year;
        final fut = day.isAfter(t);
        final n = s.log[ds(day)] ?? 0;
        if (!fut && n > 0 && inYear) activeDays++;
        cells.add(Container(
          width: cell,
          height: cell,
          margin: const EdgeInsets.only(bottom: gap),
          decoration: BoxDecoration(
            color: !inYear ? Colors.transparent : C.heat[fut ? 0 : lv(n)].withValues(alpha: fut ? .35 : 1),
            borderRadius: BorderRadius.circular(3),
            border: day == t ? Border.all(color: C.ac, width: 1.5) : null,
          ),
        ));
      }
      cols.add(Padding(padding: const EdgeInsets.only(right: gap), child: Column(children: cells)));
    }
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionTitle('Faollik jadvali', note: '${t.year} · $activeDays faol kun'),
        const SizedBox(height: 12),
        SingleChildScrollView(
          controller: scroll,
          scrollDirection: Axis.horizontal,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: labels),
            const SizedBox(height: 4),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: cols),
          ]),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          const Text('Kam ', style: TextStyle(fontSize: 11, color: C.mut)),
          for (final c in C.heat)
            Container(
                width: 11,
                height: 11,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
          const Text(" Ko'p", style: TextStyle(fontSize: 11, color: C.mut)),
        ]),
      ]),
    );
  }
}

/// Mashq oynasini ochish. "Mening so'zlarim" bo'sh bo'lsa, avval so'z qo'shishga yuboradi.
void openSetup(BuildContext context, String bookId) {
  final s = AppScope.read(context);
  if (bookId == myBookId && s.myWords.isEmpty) {
    push(context, const UnitsScreen(bookId: myBookId));
    toast(context, "Avval so'z qo'shing");
    return;
  }
  s.pickBook(bookId);
  push(context, SetupScreen(bookId: bookId));
}

Future<T?> push<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));
