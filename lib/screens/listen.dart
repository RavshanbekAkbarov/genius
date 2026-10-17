import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../services/ads.dart';
import '../services/speech.dart';
import '../state/app_state.dart';
import '../state/scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/tools.dart';

/// Tinglash: tanlangan unitlarning so'zlari ovoz bilan o'qiladi (inglizcha, keyin o'zbekcha).
/// Yo'lda yurib yoki dam olib yodlash uchun. Takror soni, tezlik va aralash tartib sozlanadi.
class ListenScreen extends StatefulWidget {
  final String bookId;
  const ListenScreen({super.key, required this.bookId});
  @override
  State<ListenScreen> createState() => _ListenScreenState();
}

class _ListenScreenState extends State<ListenScreen> {
  final selected = <int>{};
  List<CardItem> queue = [];
  int i = 0;
  bool playing = false;
  int _gen = 0;
  bool? hasUz;

  @override
  void initState() {
    super.initState();
    final s = AppScope.read(context);
    selected.add(s.nextUnit(widget.bookId) ?? 1);
    _rebuild(s);
    Speech.hasUzbek().then((v) {
      if (mounted) setState(() => hasUz = v);
    });
  }

  @override
  void dispose() {
    _gen++;
    Speech.stop();
    super.dispose();
  }

  void _rebuild(AppState s) {
    final b = widget.bookId;
    queue = [
      for (final u in selected.toList()..sort())
        for (final (k, w) in s.words(b, u).indexed) CardItem(wkey(b, u, k), b, u, w),
    ];
    if (s.listenShuffle) queue.shuffle();
    i = 0;
  }

  void _stop() {
    _gen++;
    Speech.stop();
    playing = false;
  }

  void toggleUnit(AppState s, int u) {
    if (s.words(widget.bookId, u).isEmpty) {
      toast(context, "Bu unit so'zlari hali qo'shilmagan");
      return;
    }
    setState(() {
      _stop();
      selected.contains(u) ? selected.remove(u) : selected.add(u);
      _rebuild(s);
    });
  }

  Future<void> play() async {
    if (queue.isEmpty) return;
    if (playing) {
      setState(_stop);
      return;
    }
    if (i >= queue.length) i = 0;
    final gen = ++_gen;
    setState(() => playing = true);
    final s = AppScope.read(context);
    final uz = hasUz ?? await Speech.hasUzbek();
    while (mounted && gen == _gen && i < queue.length) {
      final w = queue[i].word;
      for (var r = 0; r < s.listenRepeat && gen == _gen; r++) {
        if (s.listenUzFirst && uz) {
          await Speech.speakUz(w.uz, speed: s.listenSpeed);
          await _pause(gen, 350);
        }
        if (gen != _gen) break;
        await Speech.speak(w.en, speed: s.listenSpeed);
        if (!s.listenUzFirst && uz && gen == _gen) {
          await _pause(gen, 350);
          await Speech.speakUz(w.uz, speed: s.listenSpeed);
        }
        await _pause(gen, uz ? 700 : 1600);
      }
      if (!mounted || gen != _gen) return;
      setState(() => i++);
    }
    if (mounted && gen == _gen) setState(() => playing = false);
  }

  Future<void> _pause(int gen, int ms) => Future.delayed(Duration(milliseconds: ms));

  void jump(int d) {
    final was = playing;
    setState(() {
      _stop();
      i = (i + d).clamp(0, queue.isEmpty ? 0 : queue.length - 1);
    });
    if (was) play();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final b = bookById(widget.bookId);
    final cur = queue.isEmpty ? null : queue[i.clamp(0, queue.length - 1)];
    return Scaffold(
      appBar: TopBar(title: 'Tinglash', subtitle: b.title, book: b, actions: const [VoiceButton()]),
      bottomNavigationBar: s.isPremium ? null : const SafeArea(top: false, child: AdBanner()),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(child: Text('Unitlarni tanlang', style: TextStyle(fontWeight: FontWeight.w800))),
              Text("${selected.length} ta · ${queue.length} so'z", style: const TextStyle(color: C.mut, fontSize: 12)),
            ]),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var u = 1; u <= s.unitsOf(b); u++)
                  GestureDetector(
                    onTap: () => toggleUnit(s, u),
                    child: Opacity(
                      opacity: s.words(b.id, u).isEmpty ? .4 : 1,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected.contains(u) ? C.ac : (s.unitDone(b.id, u) ? C.good : C.sf2),
                        ),
                        alignment: Alignment.center,
                        child: Text('$u',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: selected.contains(u)
                                    ? C.onAc
                                    : (s.unitDone(b.id, u) ? const Color(0xFF052611) : C.fg))),
                      ),
                    ),
                  ),
              ],
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(gradient: C.grad, borderRadius: BorderRadius.circular(24)),
          child: Column(children: [
            Text(cur == null ? "So'z yo'q" : '${i + 1} / ${queue.length} · UNIT ${cur.unit}',
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: .8)),
            const SizedBox(height: 14),
            Text(cur?.word.en ?? '–', textAlign: TextAlign.center, style: display(30 * s.fontScale, color: Colors.white)),
            const SizedBox(height: 6),
            Text(cur?.word.uz ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(color: C.gold, fontWeight: FontWeight.w800, fontSize: 17 * s.fontScale)),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(
                  iconSize: 34,
                  color: Colors.white,
                  tooltip: 'Oldingi',
                  onPressed: () => jump(-1),
                  icon: const Icon(Icons.skip_previous_rounded)),
              const SizedBox(width: 12),
              Material(
                color: C.gold,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: play,
                  child: SizedBox(
                    width: 68,
                    height: 68,
                    child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 40, color: const Color(0xFF241800)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                  iconSize: 34,
                  color: Colors.white,
                  tooltip: 'Keyingi',
                  onPressed: () => jump(1),
                  icon: const Icon(Icons.skip_next_rounded)),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ActionChip(
            label: Text(s.listenUzFirst ? 'uz → en' : 'en → uz'),
            onPressed: () => s.setListen(uzFirst: !s.listenUzFirst),
          ),
          ActionChip(
            label: Text('${s.listenRepeat} marta'),
            onPressed: () => s.setListen(repeat: s.listenRepeat % 3 + 1),
          ),
          ActionChip(
            label: Text('Tezlik ${s.listenSpeed}x'),
            onPressed: () {
              const speeds = [0.75, 1.0, 1.25];
              final k = speeds.indexOf(s.listenSpeed);
              s.setListen(speed: speeds[(k + 1) % speeds.length]);
            },
          ),
          FilterChip(
            label: const Text('Aralash'),
            selected: s.listenShuffle,
            onSelected: (v) {
              s.setListen(shuffle: v);
              setState(() {
                _stop();
                _rebuild(s);
              });
            },
          ),
        ]),
        if (hasUz == false) ...[
          const SizedBox(height: 12),
          const EmptyBox(
              "Telefoningizda o'zbekcha ovoz yo'q, shuning uchun faqat inglizchasi o'qiladi. O'zbekcha tarjima ekranda ko'rinib turadi."),
        ],
        const SizedBox(height: 12),
        for (final (k, c) in queue.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Material(
              color: k == i ? C.ac.withValues(alpha: .18) : C.sf,
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                dense: true,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Text(c.word.en, style: const TextStyle(fontWeight: FontWeight.w800, color: C.ac)),
                trailing: SizedBox(
                  width: 160,
                  child: Text(c.word.uz,
                      textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
                onTap: () {
                  final was = playing;
                  setState(() {
                    _stop();
                    i = k;
                  });
                  if (was) play();
                },
              ),
            ),
          ),
      ]),
    );
  }
}
