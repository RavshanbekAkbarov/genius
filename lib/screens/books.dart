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
    Widget row(Book b) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: FillRow(
            leading: BookBadge(b, size: 28),
            title: b.title,
            subtitle: b.isMine
                ? "${s.myWords.length} so'z · o'zingiz qo'shasiz"
                : s.locked(b)
                    ? "${b.fixedUnits} unit · ${money(b.price)} so'm"
                    : "${b.fixedUnits} unit · ${b.fixedUnits * 20} so'z",
            trailing: s.locked(b) ? '🔒' : '${s.bookPct(b.id)}%',
            fill: s.bookPct(b.id) / 100,
            onTap: () => openBook(context, b),
          ),
        );
    Widget h(String t) => Padding(padding: const EdgeInsets.fromLTRB(0, 14, 0, 10), child: Text(t, style: display(17)));
    final center = booksOf(BookGroup.center);
    return ListView(padding: EdgeInsets.zero, children: [
      const TabHeader(title: 'Kitoblar', subtitle: 'Genius'),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          h('Shaxsiy'),
          row(bookById(myBookId)),
          h('4000 Essential Words'),
          ...booksOf(BookGroup.essential).map(row),
          h('Markaz kitoblari'),
          if (center.isEmpty)
            const EmptyBox("Aura Academy kitoblari tez orada shu yerda chiqadi.")
          else
            ...center.map(row),
        ]),
      ),
    ]);
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
        Btn('Mashq qilish', onTap: empty ? null : () => openSetup(context, b.id)),
        const SizedBox(height: 12),
        if (empty)
          const EmptyBox(
              "Tashqaridan topgan so'zlaringizni bosh sahifadagi «So'z qo'shish» tugmasi bilan qo'shing. Har 20 ta so'z bitta unit bo'ladi va ular ham kartalar, yozish va 1·3·7·15·30 takrorga tushadi.")
        else
          for (var u = 1; u <= units; u++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Builder(builder: (_) {
                final w = s.words(b.id, u).length;
                final l = s.unitLearned(b.id, u);
                return FillRow(
                  title: 'Unit $u',
                  subtitle: w == 0 ? "so'zlar hali qo'shilmagan" : null,
                  trailing: '$l/${b.isMine ? w : (w == 0 ? 20 : w)}',
                  fill: w == 0 ? 0 : l / w,
                  done: w > 0 && l == w,
                  onTap: () => push(context, UnitScreen(bookId: b.id, unit: u)),
                );
              }),
            ),
      ]),
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
          Row(children: [
            Expanded(
                child: Btn('Yodlanmaganlar (${w.length - l})',
                    onTap: l == w.length ? null : () => quick(context, s, true))),
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
    final edge = learned ? C.good : C.ln;
    return Material(
      color: learned ? Color.alphaBlend(C.good.withValues(alpha: .12), C.sf) : C.sf,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: edge, width: 1.5)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Speech.speak(word.en),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 8, 12),
          child: Row(children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(shape: BoxShape.circle, color: learned ? C.good : C.sf2),
              alignment: Alignment.center,
              child: Text('$n',
                  style: TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 12, color: learned ? const Color(0xFF052611) : C.mut)),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 5,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(word.en, style: TextStyle(color: C.ac, fontWeight: FontWeight.w800, fontSize: 17 * f)),
                if (word.ipa.isNotEmpty) Text(word.ipa, style: TextStyle(color: C.mut, fontSize: 12 * f)),
              ]),
            ),
            Container(width: 1, height: 30 * f, color: C.ln, margin: const EdgeInsets.symmetric(horizontal: 10)),
            Expanded(
              flex: 6,
              child: Text(word.uz, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16 * f)),
            ),
            if (onEdit != null)
              IconButton(
                tooltip: 'Tahrirlash',
                icon: const Icon(Icons.edit_outlined, size: 18, color: C.mut),
                onPressed: onEdit,
              )
            else
              const Padding(
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
