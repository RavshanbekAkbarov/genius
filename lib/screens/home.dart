import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/quotes.dart';
import '../data/words.dart';
import '../services/speech.dart';
import '../services/word_widget.dart';
import '../state/app_state.dart';
import '../state/scope.dart';
import '../theme.dart';
import '../widgets/add_word_sheet.dart';
import '../widgets/calendar.dart';
import '../widgets/common.dart';
import '../widgets/tools.dart';
import 'books.dart';
import 'listen.dart';
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        sliver: SliverList.list(children: [
          if (q.isNotEmpty) ...[_searchResults(s), const SizedBox(height: 16)],
          if (s.eveningWarning) ...[_eveningWarn(s), const SizedBox(height: 16)],
          _dailyCard(s),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _tile(Icons.auto_stories_rounded, C.ac, "O'rganish", b.title, () => openBook(context, b))),
            const SizedBox(width: 10),
            Expanded(
                child: _tile(Icons.style_rounded, C.violet, 'Mashq', 'kartalar · yozish', () => openSetup(context, b.id))),
            const SizedBox(width: 10),
            Expanded(
                child: _tile(Icons.headphones_rounded, C.teal, 'Tinglash', "eshitib yuring",
                    () => push(context, ListenScreen(bookId: b.isMine && s.myWords.isEmpty ? 'e1' : b.id)))),
          ]),
          const SizedBox(height: 28),
          SectionTitle('Bugungi takrorlar', action: 'Jadval', onAction: () => push(context, const ScheduleScreen())),
          const SizedBox(height: 12),
          ..._dueList(s),
          const SizedBox(height: 20),
          const WeekCard(),
          const SizedBox(height: 12),
          _wordOfDay(s),
          const SizedBox(height: 12),
          QuoteCard(quote: quoteOfDay(s.today)),
          const SizedBox(height: 28),
          SectionTitle('4000 Essential Words', action: 'Hammasi', onAction: () => ShellScope.of(context).goTab(1)),
          const SizedBox(height: 12),
          _shelf(booksOf(BookGroup.essential), s),
          const SizedBox(height: 24),
          const SectionTitle('Markaz kitoblari'),
          const SizedBox(height: 12),
          _shelf([...booksOf(BookGroup.center), bookById(myBookId)], s),
          const SizedBox(height: 24),
          const ActivityCalendar(),
        ]),
      ),
    ]);
  }

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

  /// Yuqori ko'k qism: Genius brendi, kitob va uning foizi, olov, qidiruv.
  Widget _header(AppState s, Book b) {
    final pct = s.bookPct(b.id);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: C.grad,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(R.xl)),
      ),
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const BurgerButton(light: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Genius', style: display(26, color: Colors.white)),
              Text('AURA ACADEMY',
                  style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: .7))),
            ]),
          ),
          _streakChip(s),
          const SizedBox(width: 8),
          const VoiceButton(light: true),
        ]),
        const SizedBox(height: 16),
        // Hozirgi kitob: bosilsa kitob tanlash menyusi ochiladi.
        Semantics(
          button: true,
          label: '${b.title}: $pct% yodlangan. Kitobni almashtirish',
          child: _glass(
            onTap: () => ShellScope.of(context).openDrawer(),
            child: Row(children: [
              BookBadge(b, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text(b.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
                    ),
                    Text('$pct%', style: display(15, color: Colors.white)),
                  ]),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                        value: pct / 100,
                        minHeight: 6,
                        color: C.good,
                        backgroundColor: Colors.white.withValues(alpha: .18)),
                  ),
                ]),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 22, semanticLabel: 'Almashtirish'),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: TextField(
              controller: search,
              onChanged: (v) => setState(() => q = v.trim().toLowerCase()),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: "So'z qidirish",
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: .7)),
                fillColor: Colors.black.withValues(alpha: .18),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(R.md),
                    borderSide: const BorderSide(color: Colors.white54, width: 1.5)),
                suffixIcon: q.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => setState(() {
                              search.clear();
                              q = '';
                            })),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Tooltip(
            message: "So'z qo'shish · Mening so'zlarim (${s.myWords.length})",
            child: Material(
              color: C.gold,
              borderRadius: BorderRadius.circular(R.md),
              child: InkWell(
                borderRadius: BorderRadius.circular(R.md),
                onTap: () => showAddWordSheet(context),
                child: const SizedBox(
                    width: 52,
                    height: 52,
                    child: Icon(Icons.add_rounded, color: C.onGold, size: 28, semanticLabel: "So'z qo'shish")),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _glass({required Widget child, VoidCallback? onTap}) => Material(
        color: Colors.black.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(R.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(R.md),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.fromLTRB(12, 11, 14, 11), child: child),
        ),
      );

  Widget _streakChip(AppState s) {
    final on = s.active(s.today);
    return Semantics(
      label: '${s.streak} kunlik olov',
      child: Material(
        color: Colors.black.withValues(alpha: .18),
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => push(context, const StreakScreen(todayMode: true)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 14, 9),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.local_fire_department_rounded, color: on ? C.gold : Colors.white70, size: 22),
              const SizedBox(width: 4),
              Text('${s.streak}', style: display(17, color: Colors.white)),
            ]),
          ),
        ),
      ),
    );
  }

  /// Bitta bosishda kunlik ish: avval takrorlar, keyin yangi so'zlar.
  Widget _dailyCard(AppState s) {
    final due = s.dueGroups;
    final dueWords = due.fold<int>(0, (a, g) => a + g.keys.length);
    final fresh = s.nextNewCards();
    final sub = dueWords > 0
        ? "$dueWords ta takror${fresh.isNotEmpty ? ", keyin Unit ${fresh.first.unit}" : ''}"
        : fresh.isNotEmpty
            ? "Unit ${fresh.first.unit} dan ${fresh.length} ta yangi so'z"
            : 'Kitob tugadi, boshqasini tanlang';
    final today = s.log[ds(s.today)] ?? 0;
    return AppCard(
      onTap: () => startDaily(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(color: C.gold, shape: BoxShape.circle),
            child: const Icon(Icons.bolt_rounded, color: C.onGold, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Bugungi mashq', style: display(19)),
              const SizedBox(height: 3),
              Text(sub, style: const TextStyle(fontSize: 13, color: C.mut, fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(width: 10),
          Semantics(
            label: "Bugun $today / ${s.dailyGoal} so'z",
            child: Ring(today / s.dailyGoal,
                size: 52,
                stroke: 5,
                color: C.good,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$today', style: display(14)),
                  Text('/${s.dailyGoal}', style: const TextStyle(fontSize: 9, color: C.mut, fontWeight: FontWeight.w700)),
                ])),
          ),
        ]),
        const SizedBox(height: 14),
        Btn('Boshlash', icon: const Icon(Icons.play_arrow_rounded), onTap: () => startDaily(context)),
        if (!s.isPremium) ...[
          const SizedBox(height: 8),
          Text('Bugun ${s.sessionsLeft}/$freeSessions bepul mashq · takrorlar doim bepul',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11.5, color: C.mut, fontWeight: FontWeight.w600)),
        ],
      ]),
    );
  }

  Widget _tile(IconData icon, Color color, String title, String sub, VoidCallback onTap) => AppCard(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(12, 14, 10, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          IconBox(icon, color: color, size: 40),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 1),
          Text(sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: C.mut, fontSize: 11.5, fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _wordOfDay(AppState s) {
    final w = wordOfDay(s);
    return AppCard(
      onTap: () => Speech.speak(w.en),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Eyebrow("Kunning so'zi"),
            const SizedBox(height: 8),
            Text(w.en, style: display(24, color: C.fg)),
            if (w.ipa.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(w.ipa, style: const TextStyle(color: C.ac, fontSize: 13, fontWeight: FontWeight.w700)),
            ],
            const SizedBox(height: 6),
            Text(w.uz, style: const TextStyle(fontWeight: FontWeight.w600, color: C.mut)),
          ]),
        ),
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: C.ac),
          child: const Icon(Icons.volume_up_rounded, color: Colors.white, semanticLabel: 'Talaffuz'),
        ),
      ]),
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
            leading: BookBadge(bookById(g.book), size: 26),
            title: 'Unit ${g.unit}',
            subtitle: "${intervals[g.stage]}-kun takrori · ${g.keys.length} so'z",
            trailing: '',
            onTap: () {
              final list = s.reviewCards(g.book, g.unit);
              if (list.isNotEmpty) startSession(context, list, review: true);
            },
          ).withChip(g.late
              ? Pill('kechikdi', bg: C.bad.withValues(alpha: .18), fg: C.bad)
              : Pill('bugun', bg: C.ac.withValues(alpha: .18), fg: C.ac)),
        ),
    ];
  }

  Widget _shelf(List<Book> list, AppState s) => SizedBox(
        height: 160,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final b in list) ...[
            BookCover(
              badge: b.badge,
              title: b.title,
              gradient: b.gradient,
              corner: b.isMine ? "${s.myWords.length} so'z" : (s.locked(b) ? '🔒' : null),
              progress: s.bookPct(b.id) / 100,
              onTap: () => openBook(context, b),
            ),
            const SizedBox(width: 14),
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
      borderRadius: BorderRadius.circular(R.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(R.md),
        onTap: () => Speech.speak(word.en),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(R.md), border: Border.all(color: C.ln)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 10),
              child: Icon(Icons.circle, size: 9, color: learned ? C.good : C.ln),
            ),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text.rich(TextSpan(children: [
                  TextSpan(text: word.en, style: const TextStyle(color: C.fg, fontWeight: FontWeight.w800, fontSize: 16)),
                  if (word.ipa.isNotEmpty)
                    TextSpan(text: '  ${word.ipa}', style: const TextStyle(color: C.mut, fontSize: 12)),
                ])),
                const SizedBox(height: 2),
                Text(word.uz, style: const TextStyle(color: C.fg, fontWeight: FontWeight.w500)),
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
        SectionTitle('Shu hafta', note: "kuniga ${s.dailyGoal} so'z"),
        const SizedBox(height: 14),
        Row(children: [
          for (var i = 0; i < 7; i++)
            Expanded(child: Builder(builder: (_) {
              final d = addDays(mon, i);
              final c = s.log[ds(d)] ?? 0;
              final future = d.isAfter(t);
              final p = future ? 0.0 : (c / s.dailyGoal).clamp(0, 1).toDouble();
              final isToday = d == t;
              final planned = future ? s.dueOn(d) : 0;
              return Semantics(
                button: true,
                label: '${weekdays[i]}: ${(p * 100).round()}%',
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => showDaySheet(context, d),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(children: [
                      Text(weekdays[i],
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isToday ? C.ac : (future ? C.dim : C.mut))),
                      const SizedBox(height: 8),
                      Ring(p,
                          size: 36,
                          stroke: 4,
                          color: p >= 1 ? C.good : C.ac,
                          track: isToday ? C.ac.withValues(alpha: .25) : C.sf2,
                          child: p >= 1
                              ? const Icon(Icons.check_rounded, size: 18, color: C.good)
                              : Text('${d.day}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: isToday ? C.fg : (future ? C.dim : C.mut)))),
                      const SizedBox(height: 6),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: planned > 0 ? C.violet : Colors.transparent),
                      ),
                    ]),
                  ),
                ),
              );
            })),
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
