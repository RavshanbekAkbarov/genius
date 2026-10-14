import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../state/app_state.dart';
import '../state/scope.dart';
import '../theme.dart';
import '../widgets/add_word_sheet.dart';
import '../widgets/common.dart';
import 'home.dart';
import 'shell.dart';
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
                : "${b.fixedUnits} unit · ${b.fixedUnits * 20} so'z",
            trailing: '${s.bookPct(b.id)}%',
            fill: s.bookPct(b.id) / 100,
            onTap: () => push(context, UnitsScreen(bookId: b.id)),
          ),
        );
    Widget h(String t) => Padding(padding: const EdgeInsets.fromLTRB(0, 14, 0, 10), child: Text(t, style: display(17)));
    return ListView(padding: EdgeInsets.zero, children: [
      const TabHeader(title: 'Kitoblar', subtitle: 'Genius'),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          h('Shaxsiy'),
          row(bookById(myBookId)),
          h('4000 Essential Words'),
          ...books.where((b) => b.group == BookGroup.essential).map(row),
          h('Markaz kitoblari'),
          ...books.where((b) => b.group == BookGroup.center).map(row),
        ]),
      ),
    ]);
  }
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
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        Row(children: [
          Expanded(child: Btn('Mashq qilish', onTap: empty ? null : () => openSetup(context, b.id))),
          const SizedBox(width: 10),
          Expanded(child: Btn("+ So'z qo'shish", kind: BtnKind.ghost, onTap: () => showAddWordSheet(context))),
        ]),
        const SizedBox(height: 12),
        if (empty)
          const EmptyBox(
              "Tashqaridan topgan so'zlaringizni shu yerga qo'shing. Har 20 ta so'z bitta unit bo'ladi va ular ham kartalar, yozish va 1·3·7·15·30 takrorga tushadi.")
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

/// Bitta unitning so'zlari.
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
      appBar: TopBar(title: 'Unit $unit', book: b, subtitle: "${w.length} so'z · $l yodlangan"),
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
          const SizedBox(height: 12),
          for (var i = 0; i < w.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Builder(builder: (_) {
                final p = s.prog[wkey(bookId, unit, i)];
                final isL = p?.learned ?? false;
                return WordRow(
                  word: w[i],
                  learned: isL,
                  extra: isL
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: Pill(
                            p!.stage >= intervals.length
                                ? 'Mustahkam'
                                : 'Keyingi takror: ${p.due.substring(8)}.${p.due.substring(5, 7)}',
                            bg: p.due.compareTo(s.td) <= 0 ? C.ac : C.sf2,
                            fg: p.due.compareTo(s.td) <= 0 ? C.onAc : C.fg,
                          ),
                        )
                      : null,
                  trailing: b.isMine
                      ? IconButton(
                          tooltip: 'Tahrirlash',
                          style: IconButton.styleFrom(backgroundColor: C.sf2),
                          icon: const Icon(Icons.edit_outlined, size: 18, color: C.mut),
                          onPressed: () => showAddWordSheet(context, editIndex: (unit - 1) * 20 + i),
                        )
                      : null,
                );
              }),
            ),
        ],
        const SizedBox(height: 4),
        Btn(
          b.isMine
              ? (w.length < 20 ? "+ So'z qo'shish (${20 - w.length} ta joy bor)" : "+ So'z qo'shish")
              : "+ Yangi so'z qo'shish (Mening so'zlarimga)",
          kind: BtnKind.ghost,
          onTap: () => showAddWordSheet(context),
        ),
      ]),
    );
  }
}
