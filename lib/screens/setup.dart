import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../state/app_state.dart';
import '../state/scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'study.dart';

enum WordOrder { standart, hardFirst, easyFirst, mixed }

const orderLabels = {
  WordOrder.standart: 'Standart',
  WordOrder.hardFirst: 'Qiyindan osonga',
  WordOrder.easyFirst: 'Osondan qiyinga',
  WordOrder.mixed: 'Aralash',
};

/// Mashq sozlamalari: unitlar, rejim, tartib, teskari, faqat yodlanmaganlar.
class SetupScreen extends StatefulWidget {
  final String bookId;
  const SetupScreen({super.key, required this.bookId});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final selected = <int>{};
  bool typing = false;
  WordOrder order = WordOrder.mixed;
  bool reverse = false;
  bool onlyNew = false;

  @override
  void initState() {
    super.initState();
    final s = AppScope.read(context);
    final b = bookById(widget.bookId);
    var first = 1;
    for (var u = 1; u <= s.unitsOf(b); u++) {
      final w = s.words(b.id, u).length;
      if (w > 0 && s.unitLearned(b.id, u) < w) {
        first = u;
        break;
      }
    }
    selected.add(first);
  }

  List<CardItem> pool(AppState s) {
    final out = <CardItem>[];
    for (final u in selected.toList()..sort()) {
      final w = s.words(widget.bookId, u);
      for (var i = 0; i < w.length; i++) {
        final k = wkey(widget.bookId, u, i);
        if (!onlyNew || !s.learned(k)) out.add(CardItem(k, widget.bookId, u, w[i]));
      }
    }
    return out;
  }

  List<CardItem> ordered(AppState s, List<CardItem> list) {
    switch (order) {
      case WordOrder.mixed:
        list.shuffle();
      case WordOrder.hardFirst:
        list.sort((a, b) => s.fails(b.key).compareTo(s.fails(a.key)));
      case WordOrder.easyFirst:
        list.sort((a, b) => s.fails(a.key).compareTo(s.fails(b.key)));
      case WordOrder.standart:
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final b = bookById(widget.bookId);
    final units = s.unitsOf(b);
    final cnt = pool(s).length;
    return Scaffold(
      appBar: TopBar(title: 'Mashq qilish', subtitle: b.title, book: b),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(child: Text('Unitlarni tanlang', style: TextStyle(fontWeight: FontWeight.w800))),
              Text("${selected.length} ta · $cnt so'z", style: const TextStyle(color: C.mut, fontSize: 12)),
            ]),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 10,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var u = 1; u <= units; u++) _unitCircle(s, b, u),
              ],
            ),
            const SizedBox(height: 10),
            const Wrap(spacing: 14, children: [
              _Legend(color: C.ac, filled: true, text: 'tanlangan'),
              _Legend(color: C.good, filled: false, text: 'yodlangan'),
              _Legend(color: C.sf2, filled: true, text: "so'zlar hali yo'q"),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Eyebrow('Mashq turi'),
            const SizedBox(height: 10),
            SegmentedButton<bool>(
              style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: C.ac.withValues(alpha: .18), selectedForegroundColor: C.ac),
              segments: const [
                ButtonSegment(value: false, label: Text('Kartalar'), icon: Icon(Icons.style_outlined)),
                ButtonSegment(value: true, label: Text('Yozish'), icon: Icon(Icons.edit_outlined)),
              ],
              selected: {typing},
              onSelectionChanged: (v) => setState(() => typing = v.first),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Eyebrow("So'zlar tartibi"),
            const SizedBox(height: 8),
            DropdownButtonFormField<WordOrder>(
              initialValue: order,
              dropdownColor: C.sf2,
              items: [
                for (final o in WordOrder.values)
                  DropdownMenuItem(
                      value: o, child: Text(orderLabels[o]!, style: const TextStyle(fontWeight: FontWeight.w800))),
              ],
              onChanged: (v) => setState(() => order = v ?? order),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: Column(children: [
            SwitchRow(
                title: 'Teskari (uz → en)',
                subtitle: "Avval o'zbekchasi ko'rinadi",
                value: reverse,
                onTap: () => setState(() => reverse = !reverse)),
            SwitchRow(
                title: "Faqat yodlanmagan so'zlar", value: onlyNew, onTap: () => setState(() => onlyNew = !onlyNew)),
          ]),
        ),
        const SizedBox(height: 14),
        Btn("Boshlash · $cnt so'z",
            onTap: cnt == 0
                ? null
                : () => startSession(context, ordered(s, pool(s)), review: false, typing: typing, reverse: reverse)),
        const SizedBox(height: 8),
        Text(
          s.isPremium
              ? 'Premium: mashqlar cheklanmagan'
              : 'Bugun ${s.sessionsLeft}/$freeSessions bepul mashq qoldi · takrorlar doim bepul',
          textAlign: TextAlign.center,
          style: const TextStyle(color: C.mut, fontSize: 12),
        ),
      ]),
    );
  }

  Widget _unitCircle(AppState s, Book b, int u) {
    final w = s.words(b.id, u).length;
    final l = s.unitLearned(b.id, u);
    final on = selected.contains(u);
    final done = w > 0 && l == w;
    return Semantics(
      button: true,
      selected: on,
      label: 'Unit $u',
      child: GestureDetector(
        onTap: () {
          if (w == 0) {
            toast(context, "Bu unit so'zlari hali qo'shilmagan");
            return;
          }
          setState(() => on ? selected.remove(u) : selected.add(u));
        },
        child: Opacity(
          opacity: w == 0 ? .45 : 1,
          child: Container(
            constraints: const BoxConstraints(minHeight: 28),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? C.ac : C.sf2,
              border: Border.all(color: done ? C.good : Colors.transparent, width: 2),
            ),
            alignment: Alignment.center,
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Text('$u',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 12, color: on ? C.onAc : (done ? C.fg : C.mut))),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final bool filled;
  final String text;
  const _Legend({required this.color, required this.filled, required this.text});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? color : Colors.transparent,
            border: Border.all(color: color, width: 2),
          ),
        ),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 11, color: C.mut, fontWeight: FontWeight.w700)),
      ]);
}
