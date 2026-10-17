import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../services/ads.dart';
import '../state/app_state.dart';
import '../state/scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/tools.dart';
import 'study.dart';

enum WordOrder { standart, mixed, hardFirst, easyFirst }

const orderLabels = {
  WordOrder.standart: 'Standart',
  WordOrder.mixed: 'Aralash',
  WordOrder.hardFirst: 'Qiyin → oson',
  WordOrder.easyFirst: 'Oson → qiyin',
};

/// Mashq sozlamalari: unitlar, rejim, tartib, teskari, faqat yodlanmaganlar.
class SetupScreen extends StatefulWidget {
  final String bookId;
  final int? unit;
  const SetupScreen({super.key, required this.bookId, this.unit});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final selected = <int>{};
  bool typing = false;
  WordOrder order = WordOrder.mixed;
  bool onlyNew = false;

  @override
  void initState() {
    super.initState();
    final s = AppScope.read(context);
    final b = bookById(widget.bookId);
    var first = widget.unit ?? 1;
    if (widget.unit == null) {
      for (var u = 1; u <= s.unitsOf(b); u++) {
        final w = s.words(b.id, u).length;
        if (w > 0 && s.unitLearned(b.id, u) < w) {
          first = u;
          break;
        }
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
      appBar: TopBar(title: 'Mashq qilish', subtitle: b.title, book: b, actions: const [VoiceButton()]),
      bottomNavigationBar: s.isPremium ? null : const SafeArea(top: false, child: AdBanner()),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(child: Text('Unitlarni tanlang', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
              Text("${selected.length} ta · $cnt so'z", style: const TextStyle(color: C.mut, fontSize: 12)),
            ]),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 6,
              mainAxisSpacing: 9,
              crossAxisSpacing: 9,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var u = 1; u <= units; u++) _unitCircle(s, b, u),
              ],
            ),
            const SizedBox(height: 12),
            const Wrap(spacing: 14, runSpacing: 6, children: [
              _Legend(color: C.ac, text: 'tanlangan'),
              _Legend(color: C.good, text: 'yodlangan'),
              _Legend(color: C.sf2, text: 'yodlanmagan'),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _modeTile('Kartalar', Icons.view_carousel_rounded, !typing, () => setState(() => typing = false))),
          const SizedBox(width: 10),
          Expanded(child: _modeTile('Yozish', Icons.keyboard_alt_rounded, typing, () => setState(() => typing = true))),
        ]),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Eyebrow('Tartib'),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final o in WordOrder.values)
                ChoiceChip(
                  label: Text(orderLabels[o]!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  selected: order == o,
                  visualDensity: VisualDensity.compact,
                  selectedColor: C.ac.withValues(alpha: .25),
                  onSelected: (_) => setState(() => order = o),
                ),
            ]),
            const SizedBox(height: 4),
            _toggle('Teskari (uz → en)', 'hamma unitda saqlanadi', s.reverse, () => s.setReverse(!s.reverse)),
            _toggle('Faqat yodlanmaganlar', null, onlyNew, () => setState(() => onlyNew = !onlyNew)),
          ]),
        ),
        const SizedBox(height: 14),
        Btn("Boshlash · $cnt so'z",
            onTap: cnt == 0 ? null : () => startSession(context, ordered(s, pool(s)), review: false, typing: typing)),
        const SizedBox(height: 12),
        Text(
          s.isPremium ? 'Premium: mashqlar cheklanmagan' : 'Bugun ${s.sessionsLeft}/$freeSessions mashq qoldi',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w800, color: s.sessionsLeft == 0 && !s.isPremium ? C.bad : C.fg),
        ),
        const SizedBox(height: 2),
        const Text('Takrorlar doim bepul', textAlign: TextAlign.center, style: TextStyle(color: C.mut, fontSize: 12)),
      ]),
    );
  }

  Widget _modeTile(String label, IconData icon, bool on, VoidCallback onTap) => Material(
        color: on ? C.ac.withValues(alpha: .16) : C.sf,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), side: BorderSide(color: on ? C.ac : C.ln, width: on ? 2 : 1)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            height: 54,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: on ? C.ac : C.mut, size: 22),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: on ? C.fg : C.mut)),
            ]),
          ),
        ),
      );

  Widget _toggle(String title, String? sub, bool value, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            Expanded(
              child: Text.rich(TextSpan(children: [
                TextSpan(text: title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                if (sub != null) TextSpan(text: '  $sub', style: const TextStyle(color: C.mut, fontSize: 11)),
              ])),
            ),
            Transform.scale(scale: .8, child: Switch(value: value, onChanged: (_) => onTap())),
          ]),
        ),
      );

  Widget _unitCircle(AppState s, Book b, int u) {
    final w = s.words(b.id, u).length;
    final l = s.unitLearned(b.id, u);
    final on = selected.contains(u);
    final done = w > 0 && l == w;
    final part = l > 0 && !done;
    final bg = on ? C.ac : (done ? C.good : C.sf2);
    return Semantics(
      button: true,
      selected: on,
      label: 'Unit $u${done ? ', yodlangan' : ''}',
      child: GestureDetector(
        onTap: () {
          if (w == 0) {
            toast(context, "Bu unit so'zlari hali qo'shilmagan");
            return;
          }
          setState(() => on ? selected.remove(u) : selected.add(u));
        },
        child: Opacity(
          opacity: w == 0 ? .4 : 1,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bg,
              border: Border.all(
                  color: on && done ? C.good : (part ? C.good.withValues(alpha: .7) : Colors.transparent), width: 2.5),
            ),
            alignment: Alignment.center,
            child: Text('$u',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: on ? C.onAc : (done ? const Color(0xFF052611) : C.fg))),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;
  const _Legend({required this.color, required this.text});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 11, height: 11, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 11, color: C.mut, fontWeight: FontWeight.w700)),
      ]);
}
