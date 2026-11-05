import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/words.dart';
import '../services/ads.dart';
import '../services/speech.dart';
import '../state/app_state.dart';
import '../state/scope.dart';
import '../theme.dart';
import '../widgets/add_word_sheet.dart';
import '../widgets/common.dart';
import '../widgets/tools.dart';
import 'home.dart';
import 'profile.dart';
import 'shell.dart';
import 'shop.dart';
import 'study.dart';

class BooksTab extends StatelessWidget {
  const BooksTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final center = booksOf(BookGroup.center);
    final ess = booksOf(BookGroup.essential);
    final learned = ess.fold<int>(0, (a, b) => a + s.bookPct(b.id));
    Widget h(String t, [String? note]) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 22, 0, 12), child: SectionTitle(t, note: note));
    return ListView(padding: EdgeInsets.zero, children: [
      TabHeader(
        title: 'Kitoblar',
        subtitle: "O'qiyotgan kitobingizni tanlang",
        bottom: _CurrentBook(book: bookById(s.currentBook)),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          h('Shaxsiy'),
          BookRow(book: bookById(myBookId)),
          h('4000 Essential Words', 'umumiy ${(learned / ess.length).round()}%'),
          for (final b in ess) Padding(padding: const EdgeInsets.only(bottom: 10), child: BookRow(book: b)),
          h('Markaz kitoblari'),
          if (center.isEmpty)
            const EmptyBox("Aura Academy kitoblari tez orada shu yerda chiqadi.")
          else
            for (final b in center) Padding(padding: const EdgeInsets.only(bottom: 10), child: BookRow(book: b)),
        ]),
      ),
    ]);
  }
}

/// Sarlavhadagi "Hozir o'qiyapsiz" qatori.
class _CurrentBook extends StatelessWidget {
  final Book book;
  const _CurrentBook({required this.book});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final pct = s.bookPct(book.id);
    return Material(
      color: Colors.black.withValues(alpha: .18),
      borderRadius: BorderRadius.circular(R.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(R.md),
        onTap: () => openBook(context, book),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
          child: Row(children: [
            BookBadge(book, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("HOZIR O'QIYAPSIZ",
                    style: TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: .7))),
                Text('${book.title} · $pct%',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ]),
        ),
      ),
    );
  }
}

/// Kitob kartasi: muqova, nomi, hajmi va progress chizig'i.
class BookRow extends StatelessWidget {
  final Book book;
  const BookRow({super.key, required this.book});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final b = book;
    final pct = s.bookPct(b.id);
    final locked = s.locked(b);
    final current = s.currentBook == b.id;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      border: current ? C.ac : null,
      onTap: () => openBook(context, b),
      child: Row(children: [
        BookBadge(b, size: 40),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(b.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              if (current) ...[
                const SizedBox(width: 8),
                Pill('hozir', bg: C.ac.withValues(alpha: .18), fg: C.ac),
              ],
            ]),
            const SizedBox(height: 2),
            Text(
                b.isMine
                    ? "${s.myWords.length} so'z · o'zingiz qo'shasiz"
                    : locked
                        ? "${b.fixedUnits} unit · ${money(b.price)} so'm"
                        : "${b.fixedUnits} unit · ${b.fixedUnits * 20} so'z",
                style: TextStyle(color: C.mut, fontSize: 12.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 9),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: pct / 100, minHeight: 6, color: C.good, backgroundColor: C.sf2),
            ),
          ]),
        ),
        const SizedBox(width: 14),
        locked
            ? Icon(Icons.lock_rounded, color: C.gold, size: 22)
            : SizedBox(
                width: 40,
                child: Text('$pct%', textAlign: TextAlign.right, style: display(15, color: pct > 0 ? C.good : C.mut))),
      ]),
    );
  }
}

/// Kitobni ochish: pullik va sotib olinmagan bo'lsa do'kondagi sotib olish oynasi.
void openBook(BuildContext context, Book b) {
  final s = AppScope.read(context);
  if (s.locked(b)) {
    showBookBuySheet(context, b);
    return;
  }
  push(context, UnitsScreen(bookId: b.id));
}

/// Kitobning unitlari ro'yxati.
class UnitsScreen extends StatelessWidget {
  final String bookId;
  const UnitsScreen({super.key, required this.bookId});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final b = bookById(bookId);
    final units = s.unitsOf(b);
    final empty = b.isMine && s.myWords.isEmpty;
    return Scaffold(
      appBar: TopBar(
        title: b.title,
        book: b,
        subtitle: "${b.isMine ? "${s.myWords.length} so'z · " : ''}${s.bookPct(b.id)}% yodlangan",
        actions: const [VoiceButton()],
      ),
      bottomNavigationBar: s.isPremium ? null : const SafeArea(top: false, child: AdBanner()),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Ring(s.bookPct(b.id) / 100,
                  size: 64,
                  stroke: 6,
                  color: C.good,
                  child: Text('${s.bookPct(b.id)}%', style: display(15))),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(b.title, style: display(19)),
                  const SizedBox(height: 2),
                  Text(
                      "$units unit · ${[for (var u = 1; u <= units; u++) s.unitLearned(b.id, u)].fold<int>(0, (a, x) => a + x)} so'z yodlangan",
                      style: TextStyle(color: C.mut, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
            const SizedBox(height: 14),
            Btn('Mashq qilish', icon: const Icon(Icons.play_arrow_rounded), onTap: empty ? null : () => openSetup(context, b.id)),
          ]),
        ),
        const SizedBox(height: 20),
        if (empty)
          const EmptyBox(
              "Tashqaridan topgan so'zlaringizni bosh sahifadagi «So'z qo'shish» tugmasi bilan qo'shing. Har 20 ta so'z bitta unit bo'ladi va ular ham kartalar, yozish va 1·3·7·15·30 takrorga tushadi.")
        else ...[
          const SectionTitle('Unitlar'),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: .92,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var u = 1; u <= units; u++) _UnitTile(book: b, unit: u),
            ],
          ),
        ],
      ]),
    );
  }
}

class _UnitTile extends StatelessWidget {
  final Book book;
  final int unit;
  const _UnitTile({required this.book, required this.unit});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final w = s.words(book.id, unit).length;
    final l = s.unitLearned(book.id, unit);
    final done = w > 0 && l == w;
    final total = book.isMine ? w : (w == 0 ? 20 : w);
    return Opacity(
      opacity: w == 0 ? .45 : 1,
      child: AppCard(
        padding: const EdgeInsets.all(10),
        color: done ? C.tint(C.good, .10) : null,
        border: done ? C.good.withValues(alpha: .45) : null,
        onTap: () => push(context, UnitScreen(bookId: book.id, unit: unit)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Ring(total == 0 ? 0 : l / total,
              size: 46,
              stroke: 4,
              color: C.good,
              child: done
                  ? Icon(Icons.check_rounded, color: C.good, size: 22)
                  : Text('$unit', style: display(15))),
          const SizedBox(height: 8),
          Text('Unit $unit', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          Text(w == 0 ? 'tez orada' : '$l/$total',
              style: TextStyle(color: C.mut, fontSize: 11.5, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

/// Bitta unitning so'zlari: har so'z alohida blokda, inglizcha va o'zbekcha yonma-yon.
class UnitScreen extends StatelessWidget {
  final String bookId;
  final int unit;
  const UnitScreen({super.key, required this.bookId, required this.unit});

  void quick(BuildContext context, AppState s, bool onlyNew) {
    final w = s.words(bookId, unit);
    final list = <CardItem>[
      for (var i = 0; i < w.length; i++)
        if (!onlyNew || !s.learned(wkey(bookId, unit, i))) CardItem(wkey(bookId, unit, i), bookId, unit, w[i])
    ];
    if (list.isNotEmpty) startSession(context, list, review: false);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final b = bookById(bookId);
    final w = s.words(bookId, unit);
    final l = s.unitLearned(bookId, unit);
    return Scaffold(
      appBar: TopBar(
        title: 'Unit $unit',
        book: b,
        subtitle: '${b.title} · $l/${w.length} yodlangan',
        actions: const [FontButtons(), VoiceButton()],
      ),
      bottomNavigationBar: s.isPremium ? null : const SafeArea(top: false, child: AdBanner()),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        if (w.isEmpty)
          const EmptyBox("Bu unit so'zlari kitoblaringiz kelgach qo'shiladi.")
        else ...[
          if (l == w.length)
            Btn("Hammasi yodlangan · qayta mashq (${w.length})",
                kind: BtnKind.ghost,
                icon: const Icon(Icons.replay_rounded),
                onTap: () => quick(context, s, false))
          else
            Row(children: [
              Expanded(child: Btn('Yodlanmaganlar (${w.length - l})', onTap: () => quick(context, s, true))),
              const SizedBox(width: 10),
              Expanded(child: Btn('Hammasi (${w.length})', kind: BtnKind.ghost, onTap: () => quick(context, s, false))),
            ]),
          const SizedBox(height: 14),
          for (var i = 0; i < w.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: WordBlock(
                n: i + 1,
                word: w[i],
                learned: s.learned(wkey(bookId, unit, i)),
                scale: s.fontScale,
                onEdit: b.isMine ? () => showAddWordSheet(context, editIndex: (unit - 1) * 20 + i) : null,
              ),
            ),
        ],
        if (!s.isPremium) ...[
          const SizedBox(height: 8),
          PremiumPromo(onTap: () => push(context, const PremiumScreen())),
        ],
      ]),
    );
  }
}

/// So'z bloki: raqam, inglizcha (talaffuz bilan) va o'zbekcha yonma-yon. Yodlangan so'z yashil.
class WordBlock extends StatelessWidget {
  final int n;
  final Word word;
  final bool learned;
  final double scale;
  final VoidCallback? onEdit;
  const WordBlock({super.key, required this.n, required this.word, required this.learned, this.scale = 1, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final f = scale;
    return Material(
      color: C.sf,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(R.md),
          side: BorderSide(color: learned ? C.good.withValues(alpha: .35) : C.ln)),
      child: InkWell(
        borderRadius: BorderRadius.circular(R.md),
        onTap: () => Speech.speak(word.en),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 8, 12),
          child: Row(children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(shape: BoxShape.circle, color: learned ? C.good.withValues(alpha: .18) : C.sf2),
              alignment: Alignment.center,
              child: Text('$n',
                  style: TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 12, color: learned ? C.good : C.mut)),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 5,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(word.en, style: TextStyle(color: C.fg, fontWeight: FontWeight.w800, fontSize: 17 * f)),
                if (word.ipa.isNotEmpty) Text(word.ipa, style: TextStyle(color: C.ac, fontSize: 12 * f, fontWeight: FontWeight.w600)),
              ]),
            ),
            Container(width: 1, height: 30 * f, color: C.ln, margin: const EdgeInsets.symmetric(horizontal: 10)),
            Expanded(
              flex: 6,
              child: Text(word.uz, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15 * f, color: C.fg)),
            ),
            if (onEdit != null)
              IconButton(
                tooltip: 'Tahrirlash',
                icon: Icon(Icons.edit_outlined, size: 18, color: C.mut),
                onPressed: onEdit,
              )
            else
              Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.volume_up_rounded, color: C.mut, size: 18),
              ),
          ]),
        ),
      ),
    );
  }
}

/// Bosh sahifa va menyudan "Kitoblar" bo'limiga o'tish.
void goBooks(BuildContext context) => ShellScope.of(context).goTab(1);
