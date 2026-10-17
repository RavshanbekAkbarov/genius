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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        sliver: SliverList.list(children: [
          if (q.isNotEmpty) ...[_searchResults(s), const SizedBox(height: 14)],
          if (s.eveningWarning) ...[_eveningWarn(s), const SizedBox(height: 14)],
          _dailyCard(s),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _tile(Icons.menu_book_rounded, "O'rganish", b.title, () => openBook(context, b))),
            const SizedBox(width: 10),
            Expanded(child: _tile(Icons.view_carousel_rounded, 'Mashq', 'kartalar · yozish', () => openSetup(context, b.id))),
            const SizedBox(width: 10),
            Expanded(
                child: _tile(Icons.headphones_rounded, 'Tinglash', "eshitib yuring",
                    () => push(context, ListenScreen(bookId: b.isMine && s.myWords.isEmpty ? 'e1' : b.id)))),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: Text('Bugungi takrorlar', style: display(17))),
            Material(
              color: C.gold,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => push(context, const ScheduleScreen()),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.calendar_month_rounded, size: 19, color: Color(0xFF241800)),
                    SizedBox(width: 6),
                    Text('Jadval', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF241800))),
                  ]),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          ..._dueList(s),
          const SizedBox(height: 14),
          const WeekCard(),
          const SizedBox(height: 14),
          _wordOfDay(s),
          const SizedBox(height: 12),
          QuoteCard(quote: quoteOfDay(s.today)),
          const SizedBox(height: 18),
          SectionTitle('4000 Essential Words', action: 'Hammasi', onAction: () => ShellScope.of(context).goTab(1)),
          const SizedBox(height: 10),
          _shelf(booksOf(BookGroup.essential), s),
          const SizedBox(height: 18),
          const SectionTitle('Markaz kitoblari'),
          const SizedBox(height: 10),
          _shelf([...booksOf(BookGroup.center), bookById(myBookId)], s),
          const SizedBox(height: 18),
          const ActivityCalendar(),
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
          const VoiceButton(light: true),
          const SizedBox(width: 10),
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

  /// Bitta bosishda kunlik ish: avval takrorlar, keyin yangi so'zlar.
  Widget _dailyCard(AppState s) {
    final due = s.dueGroups;
    final fresh = s.nextNewCards();
    final sub = due.isNotEmpty
        ? "${due.length} ta takror${fresh.isNotEmpty ? ", keyin ${fresh.length} ta yangi so'z" : ''}"
        : fresh.isNotEmpty
            ? "Takror yo'q · Unit ${fresh.first.unit} dan ${fresh.length} ta yangi so'z"
            : "Bu kitob tugadi, boshqasini tanlang";
    return Material(
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: const BoxDecoration(gradient: C.grad),
        child: InkWell(
          onTap: () => startDaily(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Row(children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(color: C.gold, shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow_rounded, color: Color(0xFF241800), size: 36),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Bugungi mashq', style: display(19, color: Colors.white)),
                  const SizedBox(height: 3),
                  Text(sub, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
                  if (!s.isPremium)
                    Text('bugun ${s.sessionsLeft}/$freeSessions bepul mashq · takrorlar bepul',
                        style: const TextStyle(fontSize: 11, color: Colors.white70)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String title, String sub, VoidCallback onTap) => Material(
        color: C.sf,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: C.ln)),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, color: C.ac, size: 26),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              Text(sub,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.mut, fontSize: 11)),
            ]),
          ),
        ),
      );

  Widget _wordOfDay(AppState s) {
    final w = wordOfDay(s);
    return AppCard(
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Eyebrow("Kunning so'zi"),
            const SizedBox(height: 6),
            Text(w.en, style: display(20, color: C.ac)),
            if (w.ipa.isNotEmpty) Text(w.ipa, style: const TextStyle(color: C.mut, fontSize: 12)),
            const SizedBox(height: 4),
            Text(w.uz, style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
        ),
        IconButton.filledTonal(
          tooltip: 'Talaffuz',
          onPressed: () => Speech.speak(w.en),
          icon: const Icon(Icons.volume_up_rounded),
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
              corner: b.isMine ? "${s.myWords.length} so'z" : (s.locked(b) ? '🔒' : null),
              progress: s.bookPct(b.id) / 100,
              onTap: () => openBook(context, b),
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
        SectionTitle('Shu hafta', note: "kuniga ${s.dailyGoal} so'z · kunni bosing"),
        const SizedBox(height: 12),
        Row(children: [
          for (var i = 0; i < 7; i++)
            Expanded(child: Builder(builder: (_) {
              final d = addDays(mon, i);
              final c = s.log[ds(d)] ?? 0;
              final p = d.isAfter(t) ? 0 : (c / s.dailyGoal * 100).clamp(0, 100).round();
              final isToday = d == t;
              final planned = d.isAfter(t) ? s.dueOn(d) : 0;
              return GestureDetector(
                onTap: () => showDaySheet(context, d),
                child: Container(
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
                  Text(planned > 0 ? '🔁' : '$p%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                ]),
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
